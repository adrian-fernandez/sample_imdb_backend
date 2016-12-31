module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :check_auth_token
  end

  def check_auth_token
    token = request.headers['AUTH-TOKEN']
    username = request.headers['AUTH-USER']

    return render json: { error: 401, message: "Unauthorized: missing AUTH-TOKEN" }, status: :unauthorized unless token
    return render json: { error: 401, message: "Unauthorized: missing AUTH-USER" }, status: :unauthorized unless username

    user = User.authenticate_by_token(username, token)
    return render json: { error: 401, message: "Unauthorized: the AUTH-USER and AUTH-TOKEN doesn't correspond to any user." }, status: :unauthorized unless user
  end
end