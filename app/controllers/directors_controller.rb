class DirectorsController < ApplicationController

  protected

  def objects
    Director.order(name: :asc)
  end

  def model_name
    Director
  end

  def serializer_name
    DirectorSerializer
  end

end
