require "crystal_api"

# blank module for spec
module CrystalApiPaymentsSample
end

# DB connection
path = "config/travis.yml"
local_path = "config/database.yml"
path = local_path if File.exists?(local_path)
pg_connect_from_yaml(path)

# initialize models
crystal_model(Payment, id : (Int32 | Nil) = nil, amount : (Int32 | Nil) = nil, created_at : (Time | Nil) = Time.now )
crystal_resource_convert(payment, Payment)
crystal_resource_migrate(payment, payments, Payment)
crystal_migrate_payment

crystal_model(User, id : (Int32 | Nil) = nil, email : (String | Nil) = nil, hashed_password : (String | Nil) = nil, handle : (String | Nil) = nil )
crystal_resource_convert(user, User)
crystal_resource_migrate(user, users, User)
crystal_migrate_user

struct User
  def self.sign_in(email : String, password : String) : UserHash
    h = UserHash.new
    return h
  end

  def self.load_user(user : Hash) : UserHash
    h = UserHash.new
    return h
  end
end
