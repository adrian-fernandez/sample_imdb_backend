class Director < ActiveRecord::Base
  has_many :movies

  def director_name
    name
  end
end