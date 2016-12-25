class ApplicationController < ActionController::API
  before_filter :check_auth_token

  def index
    page = allowed_params.fetch(:number, 1).to_i
    limit = get_limit

    items = objects.page(page).per(limit)

    render json: items,
           each_serializer: serializer_name,
           meta: meta_attributes(items)
  end

  def show
    item = model_name.find(params[:id])

    render json: item,
           each_serializer: serializer_name
  end

  protected

  def get_limit
    limit = allowed_params.fetch(:limit, 10).to_i

    return 10 if limit <= 0
    return 50 if limit > 50

    limit
  end

  def meta_attributes(resource, extra_meta = {})
    {
      prev_page: resource.prev_page, # use resource.previous_page when using will_paginate
      next_page: resource.next_page,
      total_pages: resource.total_pages,
      total_count: resource.total_count
    }.merge(extra_meta)
  end

  def check_auth_token
    public_controllers = ['users', 'sessions', 'movies']

    unless public_controllers.include?(params[:controller])
      token = request.headers['AUTH-TOKEN']
      return render json: { error: 401, message: "Unauthorized: missing AUTH-TOKEN" }, status: :unauthorized unless token

      user = User.authenticate_by_token(token)
      return render json: { error: 401, message: "Unauthorized: the AUTH-TOKEN doesn't correspond to any user." }, status: :unauthorized unless user
    end
  end

  def json_resource_errors
    {
      errors: resource.errors.keys.map{ |attribute| {
                field: attribute,
                messages: resource.errors[attribute]
               } }
    }
  end
end
