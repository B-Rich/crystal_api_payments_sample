require "crystal_api"

# blank module for spec
module CrystalApiPaymentsSample
end

# DB connection
path = "config/travis.yml"
local_path = "config/database.yml"
path = local_path if File.exists?(local_path)
pg_connect_from_yaml(path)

# clear DB
# service = CrystalService.instance
# service.execute_sql("drop table users;")
# service.execute_sql("drop table payments;")

require "./payment"
require "./user"

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

get "/balance" do |env|
  cu = env.current_user
  puts cu.inspect
  if cu["id"]?
    result = env.crystal_service.get_object("users", cu["id"].to_s.to_i)
    resources = crystal_resource_convert_user(result)
    resources[0].balance
  else
    nil
  end
end
