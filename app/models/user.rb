# Represents a user created from a social login.
class User < Sequel::Model
  one_to_many :responses

  def self.create_with_omniauth(auth)
    create do |user|
      user.provider = auth[:provider]
      user.uid = auth[:uid]
      user.name = auth[:info][:name]
    end
  end
end
