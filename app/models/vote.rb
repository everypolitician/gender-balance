class Vote < Sequel::Model
  many_to_one :user
end
