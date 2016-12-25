class UsersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    user = User.new(user_params)
    if user.save
      user.generate_token
      render json: { user: user } , status: 200
    else
      render json: { errors: ErrorSerializer.serialize(user) }, status: 422
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation, :password_digest)
  end

end
