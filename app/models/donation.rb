class Donation < ActiveRecord::Base
  
  acts_as_paranoid

  belongs_to :donor, class_name: User
  belongs_to :user
  belongs_to :campaign

  monetize :amount_given_cents

  after_create :tally

  protected

  def tally
    campaign.amount_raised_cents += amount_given_cents
    campaign.save!
  end
end
