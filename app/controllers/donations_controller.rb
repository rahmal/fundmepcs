class DonationsController  < InheritedResources::Base
  respond_to :html, :json

  actions :new, :create

  skip_authorization_check
  skip_before_action :authenticate_user!

  def create
    @user = User.create(donation_params.delete(:user))
    @donation = Donation.new(donation_params)
    create! do |success, failure|
      success.html { redirect_to donation_path(@donation)}
      failure.html { redirect_to new_donation_path(@donation) }
    end
  end

  protected

  def donation_params
    params.require(:donation).permit(:user, :amount_given, :campaign_id, :user_id)
  end

end
