class MovieSerializer < ActiveModel::Serializer
  attributes(:id, :imdb_id, :title, :year, :rate, :poster, :director, :actors)
end