class User < ActiveRecord::Base
  include Concerns::UserImagesConcern

  acts_as_paranoid
  acts_as_followable
  acts_as_follower
 
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :timeoutable, :lockable, :async


  #mount_uploader :avatar, AvatarUploader

  has_many :authentications, dependent: :destroy, validate: false, inverse_of: :user do
    def grouped_with_oauth
      includes(:oauth_cache).group_by {|a| a.provider }
    end
  end

  # Callbacks
  after_create :send_welcome_emails

  alias_attribute :photo, :avatar
  alias_attribute :display_name, :username

  # Validations
  validates :username, presence: {message: "Please choose a username"},
              format: {with: /\A[A-Za-z\d_\-]+\z/, message: "Username cannot consist of any special characters, only letters and numbers"},
              length: {in: 3..50, message: "Username is too short. Minimum 3 characters."}

  validates :name, presence: {message: "Please enter your full name"},
              length: {in: 2..50, message: "Full Name is too short. Minimum 2 characters."}

  validates :email, presence: {message: "Please enter your email address"},
              length: 3..255,
              format: {with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, message: "Please enter a valid email" }

  validates :bio, length: 3..160, allow_blank: true
  validates :gender, inclusion: { in: %W(m f) }, allow_blank: true
  validates :password, presence: {message: "Please choose a password"}, confirmation: {message: "Password doesnt match confirmation"},
            length: {minimum: 6, maximum: 30, message: 'Password is too short. Minimum 6 characters.'}, if: :password_required?

  # Case insensitive email lookup.
  #
  # See Devise.config.case_insensitive_keys.
  # Devise does not automatically downcase email lookups.
  def self.find_by_email(email)
    find_by(email: email.downcase)
    # Use ILIKE if using PostgreSQL and Devise.config.case_insensitive_keys=[]
    #where('email ILIKE ?', email).first
  end

  protected

  # Override Devise to allow for Authentication or password.
  #
  # An invalid authentication is allowed for a new record since the record
  # needs to first be saved before the authentication.user_id can be set.
  def password_required?
    if authentications.empty?
      super || encrypted_password.blank?
    elsif new_record?
      false
    else
      super || encrypted_password.blank? && authentications.find{|a| a.valid?}.nil?
    end
  end

  # Merge attributes from Authentication if User attribute is blank.
  #
  # If User has fields that do not match the Authentication field name,
  # modify this method as needed.
  def reverse_merge_attributes_from_auth(auth)
    auth.oauth_data.each do |k, v|
      self[k] = v if self.respond_to?("#{k}=") && self[k].blank?
    end
  end

  # Do not require email confirmation to login or perform actions
  def confirmation_required?
    false
  end

  def send_welcome_emails
    UserMailer.delay.welcome_email(self.id)
    # UserMailer.delay_for(5.days).find_more_friends_email(self.id)
  end
end
