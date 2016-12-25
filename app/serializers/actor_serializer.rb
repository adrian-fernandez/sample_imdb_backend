class ActorSerializer < ActiveModel::Serializer
  attributes(:id, :imdb_id, :name, :photo)
end