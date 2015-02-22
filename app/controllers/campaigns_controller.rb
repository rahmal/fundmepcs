class CampaignsController  < InheritedResources::Base
  respond_to :html, :json

  actions :new, :create, :show, :edit, :update, :index

  skip_authorization_check
  skip_before_action :authenticate_user!

  def create
    @user = User.create(campaign_params.delete(:user))
    @campaign = Campaign.new(campaign_params)
    create! do |success, failure|
      success.html { redirect_to campaign_path(@campaign)}
      failure.html { redirect_to new_campaign_path(@campaign) }
    end
  end

  protected

  def calc_amount_needed(campaign)
    cost = campaign.delete(:amount_needed).to_f.ceil
    tax  = cost * 0.10
    ship = 10
    in_cents  = (cost + tax + ship) * 100
    campaign.merge(amount_needed_cents: in_cents)
  end

  def campaign_params
    calc_amount_needed(params.require(:campaign).permit(
                         :user, :title, :case, :product_id, :user_id, :amount_needed))
  end
end
