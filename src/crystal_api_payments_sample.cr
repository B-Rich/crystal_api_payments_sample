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
crystal_model(Payment, id : (Int32 | Nil) = nil, amount : (Int32 | Nil) = nil, created_at : (Time | Nil) = Time.now)
crystal_resource_convert(payment, Payment)
crystal_resource_migrate(payment, payments, Payment)
crystal_migrate_payment

crystal_model(User, id : (Int32 | Nil) = nil, email : (String | Nil) = nil, hashed_password : (String | Nil) = nil, handle : (String | Nil) = nil)
crystal_resource_convert(user, User)
crystal_resource_migrate(user, users, User)
crystal_migrate_user

struct User
  # Return id in UserHash if user is signed ok
  def self.sign_in(email : String, password : String) : UserHash
    service = CrystalService.instance
    h = {
      "email"           => email,
      "hashed_password" => Crypto::MD5.hex_digest(password),
    }
    result = service.get_filtered_objects("users", h)
    collection = crystal_resource_convert_user(result)

    # try sign in using handle
    if collection.size == 0
      h = {
        "handle"          => email,
        "hashed_password" => Crypto::MD5.hex_digest(password),
      }
      result = service.get_filtered_objects("users", h)
      collection = crystal_resource_convert_user(result)
    end

    uh = UserHash.new
    if collection.size > 0
      uh["id"] = collection[0].id
    end
    return uh
  end

  # Return email and handle if user can be loaded
  def self.load_user(user : Hash) : UserHash
    uh = UserHash.new
    return uh if user["id"].to_s == ""

    service = CrystalService.instance
    h = {
      "id" => user["id"].to_s.to_i.as(Int32),
    }
    result = service.get_filtered_objects("users", h)
    collection = crystal_resource_convert_user(result)

    if collection.size > 0
      uh["email"] = collection[0].email
      uh["handle"] = collection[0].handle
    end
    return uh
  end
end

auth_token_mw = Kemal::AuthToken.new
auth_token_mw.sign_in do |email, password|
  User.sign_in(email, password)
end
auth_token_mw.load_user do |user|
  User.load_user(user)
end

Kemal.config.add_handler(auth_token_mw)
Kemal.config.port = 8002

get "/current_user" do |env|
  env.current_user.to_json
end
