class Actor < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :imdb_id, presence: true

  def actor_name
    name
  end

  def self.manual_create(name)
    new_id = Actor.last.try(:id) || 1
    puts "MANUAL CREATE: #{new_id}"
    Actor.create(name: name, imdb_id: "user_#{new_id}")
  end

  def self.add_batch_actors(actor_names)
    actor_hash = Actor.all.pluck(:name, :imdb_id).to_h
    actor_ids = []
    actor_names.each do |actor_name|
      sanitized_actor_name = actor_name.strip

      if actor_hash.has_key?(sanitized_actor_name)
        actor_ids << actor_hash[sanitized_actor_name]
      else
        actor = Actor.manual_create(actor_name) unless actor
        actor_ids << actor.imdb_id
      end
    end

    actor_ids
  end

end