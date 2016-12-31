class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    user = User.auth(params[:username], params[:password])

    if user
      render json: user, status: 200
    else
      render json: "Invalid user or password", status: :unauthorized
    end
  end
end
