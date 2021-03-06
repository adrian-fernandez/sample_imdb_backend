class Movie < ActiveRecord::Base
  belongs_to :director

  validates :title, presence: true, uniqueness: true
  validates :rate, presence: true
  validates_numericality_of :rate, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0

  delegate :director_name, to: :director

  def actors
    Actor.where(imdb_id: actor_ids)
  end

  def self.search(text)
    where(with_actor_name(text).arel.constraints.reduce(:and)
      .or(with_director(text).arel.constraints.reduce(:and))
      .or(with_title(text).arel.constraints.reduce(:and)))
  end

  def self.with_actor(actor_id)
    where("? = ANY (actor_ids)", actor_id)
  end

  def self.with_title(title)
    where("title iLIKE ?", "%#{title}%")
  end

  def self.with_director(name)
    director_ids = Director.where("name iLIKE ?", "%#{name}%").pluck(:id)
    if director_ids.blank?
      where("false")
    else
      where(director_id: director_ids)
    end
  end

  def self.with_actor_name(name)
    actor_ids = Actor.where("name iLIKE ?", "%#{name}%").pluck(:imdb_id)
    if actor_ids.blank?
      where("false")
    else
      Movie.where("actor_ids && ARRAY[?]::varchar[]", actor_ids)
    end
  end

  def self.with_year(year)
    where("year = ?", year.to_i)
  end

  def self.with_min_rate(rate)
    where("rate >= ?", rate.gsub(/,/,".").to_f)
  end

  def self.with_max_rate(rate)
    where("rate <= ?", rate.gsub(/,/,".").to_f)
  end

  def self.get_next_imdb
    (Movie.last.try(:id) || 0) + 1
  end

  # data = Title,Director,Year,Rate,Actor1;Actor2;Actor3.
  def self.import_from_csv_data(data)
    result = {uploaded_movies: 0,
              imported_movies: 0,
              error_movies: 0}
    last_id = (Movie.last.id || 0) + 1
    data.each do |movie|
      result[:uploaded_movies] += 1
      director_id = Director.find_or_create_by(name: movie[1].to_s)
      actor_ids = Actor.add_batch_actors(movie[4].split(";"))

      movie_title = movie[0]
      guesser = ImdbParser::MovieGuess.new(movie_title)
      fetched_movie = guesser.guess_movie

      if fetched_movie.present? && fetched_movie[:title].downcase.strip == movie_title.downcase.strip
        newMovie = fetched_movie
      else
        newMovie = Movie.new(title: movie_title,
                             director: director_id,
                             year: movie[2],
                             rate: movie[3],
                             actor_ids: actor_ids,
                             imdb_id: "user_#{last_id}")
      end

      if newMovie.save
        result[:imported_movies] += 1
        last_id += 1
      else
        result[:error_movies] += 1
      end
    end

    result
  end

end