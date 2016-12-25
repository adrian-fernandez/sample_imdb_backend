class DirectorSerializer < ActiveModel::Serializer
  attributes(:id, :name)

  has_many :movies, include_data: true
end