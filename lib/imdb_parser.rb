module ImdbParser
  class TopMoviesParser
    require 'nokogiri'
    require 'open-uri'

    URL = 'http://www.imdb.com/chart/top'.freeze

    def import
      page = Nokogiri::HTML(open(URL))
      list = page.css('.lister-list tr')

      data_insert = []
      data_update = []
      actors_data = []
      parsed_actor_ids = []
      existing_movies = Movie.all.pluck(:imdb_id)
      list.each do |nokogiri_movie|
        movie_imdb = get_imdb_id(nokogiri_movie)

        if existing_movies.include?(movie_imdb)
          # Only need rate to update
          curr_data = [
                        ActiveRecord::Base.connection.quote(movie_imdb),
                        get_rate(nokogiri_movie)
                      ]
          data_update << "(#{curr_data.join(',')})"
        else
          actor_ids, curr_actor_data = get_actors(movie_imdb, parsed_actor_ids)
          parsed_actor_ids += actor_ids
          actors_data << curr_actor_data
          actor_ids = actor_ids.map do |x|
            ActiveRecord::Base.connection.quote(x)
          end

          curr_data = [
                        ActiveRecord::Base.connection.quote(movie_imdb),
                        ActiveRecord::Base.connection.quote(get_poster_url(nokogiri_movie)),
                        ActiveRecord::Base.connection.quote(get_title(nokogiri_movie)),
                        get_director(nokogiri_movie),
                        get_year(nokogiri_movie),
                        get_rate(nokogiri_movie),
                        "ARRAY[#{actor_ids.join(',')}]"
                      ]
          data_insert << "(#{curr_data.join(',')})"
        end
      end

      unless data_insert.blank?
        sql = "INSERT INTO #{Movie.table_name} (imdb_id, poster, title, director_id, year, rate, actor_ids) VALUES #{data_insert.join(', ')} "\
              "ON CONFLICT (imdb_id) DO NOTHING"
        ActiveRecord::Base.connection.execute(sql)
      end

      unless data_update.blank?
        sql = "INSERT INTO #{Movie.table_name} (imdb_id, rate) VALUES #{data_update.join(', ')} "\
              "ON CONFLICT (imdb_id) DO UPDATE SET rate=excluded.rate"
        ActiveRecord::Base.connection.execute(sql)
      end

      unless actors_data.blank?
        sql = "INSERT INTO #{Actor.table_name} (imdb_id, photo, name) VALUES #{actors_data.flatten.join(', ')}"\
              "ON CONFLICT (imdb_id) DO NOTHING"
        ActiveRecord::Base.connection.execute(sql)
      end
    end

    private

    def get_poster_url(nokogiri_movie)
      nokogiri_movie.css('td.posterColumn a img')
                    .attr('src')
                    .to_s
    end

    def get_title(nokogiri_movie)
      nokogiri_movie.css('td.titleColumn a')
                    .text
    end

    def get_director(nokogiri_movie)
      director_name = nokogiri_movie.css('td.titleColumn a')
                                    .attr('title')
                                    .value
                                    .gsub(/ \(.*/,'')
      get_director_id(director_name)
    end

    def get_director_id(director_name)
      Director.find_or_create_by(name: director_name).id
    end

    def get_year(nokogiri_movie)
      nokogiri_movie.css('td.titleColumn span.secondaryInfo')
                    .text
                    .gsub(/[^\d]/, '')
    end

    def get_rate(nokogiri_movie)
      nokogiri_movie.css('td.imdbRating strong')
                    .text
                    .to_f
    end

    def get_imdb_id(nokogiri_movie)
      nokogiri_movie.css('td.titleColumn a')
                    .attr('href')
                    .to_s
                    .split('/')[2]
    end

    def get_actors(imdb_id, parsed_ids)
      actor_ids, data = MovieActorsParser.new(imdb_id, nil, parsed_actor_ids).import_actors
    end
  end

  class MovieActorsParser
    require 'nokogiri'
    require 'open-uri'

    BLANK_IMG = 'http://ia.media-imdb.com/images/G/01/imdb/images/nopicture/32x44/name-2138558783._CB522736171_.png'.freeze

    attr_accessor :url, :parsed_actor_ids, :page

    def initialize(imdb_id, page, parsed_actor_ids)
      self.url = "http://www.imdb.com/title/#{imdb_id}/"
      self.parsed_actor_ids = parsed_actor_ids

      self.page = page.blank? ? Nokogiri::HTML(open(url)) : page
    end

    def import_actors
      list = page.css('.cast_list tr')

      data = []
      ids = []
      list.each do |nokogiri_movie|
        unless nokogiri_movie == list[0]
         imdb_id = get_actor_imdb_id(nokogiri_movie) rescue nil
         unless imdb_id.nil?
           ids << imdb_id

           unless parsed_actor_ids.include?(imdb_id)
             curr_data = [
                           ActiveRecord::Base.connection.quote(imdb_id),
                           ActiveRecord::Base.connection.quote(get_actor_photo(nokogiri_movie)),
                           ActiveRecord::Base.connection.quote(get_actor_name(nokogiri_movie))
                         ]
              data << "(#{curr_data.join(',')})"
            end
          end
        end
      end

      return ids, data
    end

    def import_actors_and_save
      ids, data = import_actors

      unless data.blank?
        sql = "INSERT INTO #{Actor.table_name} (imdb_id, photo, name) VALUES #{data.flatten.join(', ')}"\
              "ON CONFLICT (imdb_id) DO NOTHING"
        ActiveRecord::Base.connection.execute(sql)
      end

      ids
    end

    def get_actor_imdb_id(nokogiri_movie)
      nokogiri_movie.css("td[itemprop=actor] a")
                    .attr('href')
                    .to_s
                    .split('/')[2]
    end

    def get_actor_photo(nokogiri_movie)
      photo = nokogiri_movie.css('td.primary_photo a img')
                            .attr('loadlate')
                            .to_s
      photo.blank? ? BLANK_IMG : photo
    end

    def get_actor_name(nokogiri_movie)
      nokogiri_movie.css("td[itemprop=actor] a span")
                    .text
    end
  end

  class MovieParser
    require 'nokogiri'
    require 'open-uri'

    BLANK_IMG = 'http://ia.media-imdb.com/images/G/01/imdb/images/nopicture/32x44/name-2138558783._CB522736171_.png'.freeze
    attr_accessor :url, :parsed_actor_ids, :page, :imdb_id

    def initialize(imdb_id, parsed_actor_ids)
      self.imdb_id = imdb_id
      self.url = "http://www.imdb.com/title/#{imdb_id}/"
      self.parsed_actor_ids = parsed_actor_ids
      self.page = Nokogiri::HTML(open(url))
    end

    def generate_movie_object
      director_id = import_director.id
      actor_ids = MovieActorsParser.new(imdb_id, page, parsed_actor_ids).import_actors_and_save

      movie = Movie.new(title: import_title,
                        imdb_id: imdb_id,
                        rate: import_rate,
                        year: import_year,
                        actor_ids: actor_ids,
                        director_id: director_id,
                        poster: import_poster)

      return movie
    end

    def import_year
      page.css("span#titleYear").first.text.gsub(/[^\d]/, '')
    end

    def import_title
      full_title = page.css("h1[itemprop=name]").first.text
      year_text = page.css("span#titleYear").first.text
      title = full_title.gsub(year_text, '').strip
    end

    def import_director
      director = page.css('span[itemprop=director]').first
      director_name = director.css('span[itemprop=name]').text
      
      director = Director.find_by(name: director_name)
      director = Director.create(name: director_name) unless director.present?

      director
    end

    def import_rate
      return nil, nil if page.nil?

      page.css('span[itemprop=ratingValue]').text.gsub(/,/, ".").to_f
    end

    def import_poster
      page.css('div.poster').first.css('img').attr('src').to_s
    end

  end

  class MovieGuess
    require 'net/http'
    require 'uri'

    URL = 'https://v2.sg.media-imdb.com/suggests/[INITIAL]/[TITLE].json'.freeze
    BLANK_IMG = 'http://i.media-imdb.com/images/mobile/film-40x54.png'.freeze
    attr_accessor :url, :title, :json

    def initialize(movie_title)
      self.title = sanitize_string(movie_title)
      self.url = URL.gsub("[TITLE]", title).gsub("[INITIAL]", title[0])
      sanitize_data
    end

    def sanitize_string(str='')
      # Only allow chars, nums and whitespaces
      str.gsub(/[^(\w|\d )]/, " ").gsub(/ /,'_')
    end

    def sanitize_data
      content = Net::HTTP.get(URI.parse(url))
      content = content.gsub("imdb$#{title}(", "")
      content = content.gsub(/\)$/, "")
      self.json = JSON.parse(content)["d"]
    end

    def suggestions
      data = []

      json.count.times do |pos|
        if is_movie?(pos)
          imdb_id = json[pos].fetch('id', '')
          added = Movie.exists?(imdb_id: imdb_id)
          data << { title: json[pos].fetch('l', ''),
                    imdb_id: imdb_id,
                    year: json[pos].fetch('y', ''),
                    added: added,
                    poster: json[pos].fetch('i',[])[0] || BLANK_IMG }
        end
      end
  
      data
    end

    def is_movie?(position)
      json[position]['id'].start_with?('tt') && json[position]['q'] == 'feature'
    end
  end
end