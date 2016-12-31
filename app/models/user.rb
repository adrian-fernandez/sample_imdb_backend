class User < ActiveRecord::Base
  has_secure_password

  validates :username, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password_confirmation, presence: true

  def self.auth(user, password)
    User.find_by_username(user).try(:authenticate, password)
  end

  def self.authenticate_by_token(username, token)
    user = User.find_by_username(username)
    if user && ActiveSupport::SecurityUtils.secure_compare(user.token, token)
      return user
    else
      return nil
    end
  end

  def generate_token
    token = loop do
      token = SecureRandom.hex(128)
      break token unless User.exists?(token: token)
    end
  end
end
