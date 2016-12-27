class MoviesController < ApplicationController

  def create
    director = Director.find_or_create_by(name: movie_params[:director])
    actor_imdb_ids = parse_actors

    imdb = movie_params['imdb-id'] || "user_#{Movie.get_next_imdb}"

    movie = Movie.new(title: movie_params[:title],
                      director_id: director.id,
                      actor_ids: actor_imdb_ids,
                      poster: movie_params[:poster],
                      year: movie_params[:year],
                      rate: movie_params[:rate].to_s.gsub(/,/, ".").to_f,
                      imdb_id: imdb
                     )

    if movie.save
      render json: movie, status: 201
    else
      render json: { errors: ErrorSerializer.serialize(movie) }, status: 422
    end
  end

  def suggestions
    if params[:title].present?
      guesser = ImdbParser::MovieGuess.new(params[:title])
      items = guesser.suggestions

      render json: items.to_json
    else
      render json: { message: "Missing required field 'title'", error: 500 }, status: 500
    end
  end

  def get_movie
    if params[:imdb].present?
      importer = ImdbParser::MovieParser.new(params[:imdb], [])
      movie = importer.generate_movie_object

      if movie.valid?
        render json: movie, status: 200
      else
        render json: { errors: ErrorSerializer.serialize(movie) }, status: 422
      end
    else
      render json: { message: "Missing required field 'imdb'", error: 500 }, status: 500
    end
  end

  def batch_create
    file_content = Base64.decode64(params[:data].gsub("data:text/csv;base64,",""))
    movies = file_content.split("\n").map do |x|
      x.split(",")
    end

    result = Movie.import_from_csv_data(movies)

    render json: result, status: 201
  end

  protected

  def movie_params
    params.require(:data).require(:attributes).permit([:title, :director, :actors, :year, :rate, :poster, :imdb, 'imdb-id'])
  end

  def allowed_params
    params.require(:page).permit(:number, :limit, :order_field, :order_direction,
                                 :filter => [:q, :title, :director, :actor_name, :min_rate, :max_rate, :year])
  end

  def objects
    result = Movie

    result = result.search(allowed_params[:filter][:q]) unless allowed_params.fetch(:filter, {}).fetch(:q, '').blank?
    result = result.with_title(allowed_params[:filter][:title]) unless allowed_params.fetch(:filter, {}).fetch(:title, '').blank?
    result = result.with_director(allowed_params[:filter][:director]) unless allowed_params.fetch(:filter, {}).fetch(:director, '').blank?
    result = result.with_year(allowed_params[:filter][:year]) unless allowed_params.fetch(:filter, {}).fetch(:year, '').blank?
    result = result.with_actor_name(allowed_params[:filter][:actor_name]) unless allowed_params.fetch(:filter, {}).fetch(:actor_name, '').blank?
    result = result.with_min_rate(allowed_params[:filter][:min_rate]) unless allowed_params.fetch(:filter, {}).fetch(:min_rate, '').blank?
    result = result.with_max_rate(allowed_params[:filter][:max_rate]) unless allowed_params.fetch(:filter, {}).fetch(:max_rate, '').blank?

    order_hash = {}
    order_hash[order_field] = order_direction

    result.order(order_hash)
  end

  def sortable_fields
    ['title', 'year', 'rate']
  end

  def order_field
    order = sortable_fields.include?(allowed_params[:order_field].to_s) ? allowed_params[:order_field] : :rate
    order
  end

  def order_direction
    order = :desc
    order = :asc if allowed_params[:order_direction] == 'asc'

    order
  end

  def model_name
    Movie
  end

  def serializer_name
    MovieSerializer
  end

  def parse_actors
    return [] if movie_params[:actors].blank?

    actor_names = movie_params[:actors].split(',')
    Actor.add_batch_actors(actor_names)
  end

end
