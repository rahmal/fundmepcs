module ErrorManager

  DB_ERRORS = [
    PG::Error,
    ActiveRecord::StatementInvalid
  ]

  NOT_FOUND_ERRORS = [
    ActiveRecord::RecordNotFound,
    AbstractController::ActionNotFound
  ]

  ROUTE_ERRORS = [
    ActionController::RoutingError
  ]

  INVALID_DATA_ERRORS = [
    ActiveRecord::RecordInvalid,
    DuplicateRecord,
    InvalidAttribute,
    ArgumentError
  ]

  SMS_ERRORS = [
    Twilio::REST::RequestError
  ]

  PAYMENT_ERRORS = [
    Stripe::InvalidRequestError,    # Raised when the request is improper and/or malformed.
    Stripe::StripeError,
    Stripe::CardError,
    Stripe::APIError,
    Stripe::APIConnectionError,      # Raised when the request had a logical error.
    AccountNotFound,
    PaymentError,
    Money::Bank::UnknownRate,
    PaypalAdaptive::NoDataError # Raised when the PayPal request failed to get a proper response
  ]

  PAYMENT_AUTH = [
    Stripe::AuthenticationError,  # Raised when the http authentication fails.
    Balanced::Forbidden,     # Raised when the user is not authorized to access the resource.
    Balanced::FundingInstrumentVerificationError, # Raised when there's an issue verifying an account
    Balanced::PaymentRequired
  ]

  PAYMENT_GATEWAY = [
    Balanced::NotImplemented,
    Balanced::BadGateway,
    Balanced::GatewayTimeout,
    Balanced::ServiceUnavailable,
    Errno::ECONNRESET
  ]

  SHIPPING_ERRORS = [
    EasyPost::Error
  ]

  def self.included base
    base.class_eval do
      if ENV["RAISE_ERRORS"].blank?
        rescue_from *PAYMENT_AUTH,        with: :payment_auth_error
        rescue_from *PAYMENT_GATEWAY,     with: :payment_gateway_error
        rescue_from *PAYMENT_ERRORS,      with: :payment_error
        rescue_from *SHIPPING_ERRORS,     with: :shipment_error
        rescue_from *SMS_ERRORS,          with: :sms_error
        rescue_from *INVALID_DATA_ERRORS, with: :invalid_params
        rescue_from *ROUTE_ERRORS,        with: :not_found
        rescue_from *NOT_FOUND_ERRORS,    with: :not_found
        rescue_from SecurityError,        with: :auth_error
        rescue_from RuntimeError,         with: :api_error
      end
    end
  end

  protected

  def api_error(exception)
    respond_to do |format|
      format.html { (Rails.env.production? || Rails.env.test?) ? error_page(:internal_server_error) : raise(exception) }
      format.json { error_response(exception, API::Errors::ERROR) }
    end
  end

  def payment_error(exception)
    error_response(exception, API::Errors::PAYMENT_PROCESS_ERROR, :description => exception.message)
  end

  def shipment_error(exception)
    error_response(exception, API::Errors::CARRIER_NOT_FOUND)
  end

  def payment_auth_error(exception)
    error = API::Errors::PAYMENT_AUTH_ERROR
    message = exception.message rescue ''

    if exception.is_a?(Balanced::PaymentRequired) ||
      message['PaymentRequired'] || message['card-declined']
      message = message.split(':').last.to_s
      code, desc = error[:code], error[:description]
      error = {code: code, description: desc, message: message}
      render(json: {card: nil, error: error}) and return
    end

    error_response(exception, error)
  end

  def payment_gateway_error(exception)
    error_response(exception, API::Errors::PAYMENT_GATEWAY_ERROR, :description => exception.message)
  end

  def sms_error(exception)
    error_response(exception, API::Errors::SMS_TEXT_ERROR)
  end

  def db_error(exception)
    error_response(exception, API::Errors::DATABASE_ERROR)
  end

  def rec_not_found(exception)
    error_response(exception, API::Errors::RECORD_NOT_FOUND)
  end

  def rec_not_created(exception)
    error_response(exception, API::Errors::RECORD_NOT_CREATED)
  end

  def rec_not_updated(exception)
    error_response(exception, API::Errors::RECORD_NOT_UPDATED)
  end

  def rec_not_deleted(exception)
    error_response(exception, API::Errors::RECORD_NOT_DELETED)
  end

  def invalid_params(exception)
    debug :exception, exception
    raise exception unless exception.respond_to?(:record)
    params = exception.record.errors.messages
    error_response(exception, API::Errors::INVALID_PARAMS, params: params)
  end

  def missing_params(exception)
    error_response(exception, API::Errors::MISSING_PARAMS, params: params)
  end

  def blank_params(exception)
    error_response(exception, API::Errors::BLANK_PARAMS, params: params)
  end

  def not_found(exception)
    respond_to do |format|
      format.html { (Rails.env.production? || Rails.env.test?) ? error_page(:not_found) : raise(exception) }
      format.json { error_response(exception, API::Errors::ROUTING_ERROR, path: request.path) }
    end
  end

  def auth_error(exception)
    error_response(exception, API::Errors::AUTH_ERROR)
  end

  def login_error(exception)
    error_response(exception, API::Errors::LOGIN_ERROR)
  end

  def error_page error
    render template: "errors/#{error}", layout: false, status: error
  end

  def error_response exception, error=nil, extras={}
    logger.info "ERROR:\n#{exception.inspect}"
    logger.info "ERROR BT:\n#{exception.backtrace.join("\n")}"
    error ||= API::Errors::ERROR
    code, desc = (extras[:code] || error[:code]), (extras[:description] || error[:description])
    msg   = exception.message
    error_out = {code: code, description: desc, message: msg}.merge(extras)
    root = get_root(exception)
    json  = {root || "root" => nil, error: error_out}
    respond_to do |format|
      format.html { flash[:notice] = msg; redirect_to :back }
      format.json { render json: json, :status => error[:status] || 500 }
    end
  end

  def render_success
    respond_to do |format|
      format.html { redirect_to :back }
      format.json { render json: API::Errors::SUCCESS  }
    end
  end

  def get_root(exception)
    logger.info "exception: #{exception.class}, controller: #{current_controller}, action: #{current_action}"
    return :user if exception.is_a?(LoginFailed)
    con = current_controller.to_sym
    act = current_action.to_sym
    req = "#{con}_#{act}".to_sym
    mod = con.to_s.singularize.to_sym

    case act
    when :index, :search, :send_link
      return con
    when :show, :create, :update, :destroy, :find
      return mod
    end

    case con
    when :items
      return (act.in?(*item_collection_actions) ? con : mod)
    when :users
      return (act.in?(*user_collection_actions) ? con : mod)
    end
  end

  def item_collection_actions
    [:my, :my_stuff, :discover, :globalsearch]
  end

  def user_collection_actions
    [:followers, :followings, :suggested, :search, :search_followed]
  end

end
