class Product < ActiveRecord::Base

  acts_as_paranoid

  has_many :campaigns

  monetize :cost_cents

  # Validations
  validates :name, length: 3..500, presence: true
  validates :description, length: 0..10000, allow_blank: true
  
end
