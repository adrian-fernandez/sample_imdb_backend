class User < ActiveRecord::Base
  has_secure_password

  validates :username, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password_confirmation, presence: true

  def self.auth(user, password)
    User.find_by_username(user).try(:authenticate, password)
  end

  def self.authenticate_by_token(token)
    User.find_by_token(token)
  end

  def generate_token
    update_attribute(:token, SecureRandom.hex(128))
  end
end
