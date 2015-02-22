class Campaign < ActiveRecord::Base
  include RandomString

  acts_as_paranoid

  belongs_to :user
  belongs_to :product
  has_many :donations, dependent: :destroy

  monetize :amount_needed_cents
  monetize :amount_raised_cents

  # Callbacks
  before_validation :set_token
  
  # Validations
  validates :user_id, :product_id, presence: true
  validates :name, length: 3..500, presence: true
  validates :description, length: 0..10000, allow_blank: true
  validates :token, presence: true, uniqueness: { case_sensitive: true }
 
  scope :created_after, ->(date) { where('items.created_at >= :date', date: date) }

  def donate!(donor, amount)
    self.donations.create!(donor: donor, user: user, amount_given: amount)
  end

  protected

  def set_token
    self.token = random_string unless token.present?
  end

end
