require "./spec_helper"

describe CrystalApiPaymentsSample do
  it "run server" do
    sample_user1_email = "email1@email.org"
    sample_user1_handle = "user1"
    sample_user1_password = "password1"

    sample_user2_email = "email2@email.org"
    sample_user2_handle = "user2"
    sample_user2_password = "password1"

    service = CrystalService.instance

    # create user 1
    h = {"email" => sample_user1_email}
    result = service.get_filtered_objects("users", h)
    collection = crystal_resource_convert_user(result)
    if collection.size == 0
      # create user
      puts "Create user #{sample_user1_email}"

      h = {
        "email"           => sample_user1_email,
        "handle"          => sample_user1_handle,
        "hashed_password" => Crypto::MD5.hex_digest(sample_user1_password),
      }
      result = service.insert_object("users", h)
      collection = crystal_resource_convert_user(result)

      puts "User created"
      puts collection.inspect
    else
      puts "User already available"
      puts collection.inspect
    end
    user1 = collection[0]
    user1_id = user1.id

    # create user 2
    h = {"email" => sample_user2_email}
    result = service.get_filtered_objects("users", h)
    collection = crystal_resource_convert_user(result)
    if collection.size == 0
      # create user
      puts "Create user #{sample_user2_email}"

      h = {
        "email"           => sample_user2_email,
        "handle"          => sample_user2_handle,
        "hashed_password" => Crypto::MD5.hex_digest(sample_user2_password),
      }
      result = service.insert_object("users", h)
      collection = crystal_resource_convert_user(result)

      puts "User created"
      puts collection.inspect
    else
      puts "User already available"
      puts collection.inspect
    end
    user2 = collection[0]
    user2_id = user2.id


    # create initial payments
    h = {
      "user_id"           => user1_id,
      "amount"          => 1000,
      "payment_type" => Payment::TYPE_INCOMING,
      "created_at" => Time.now,
    }
    result = service.insert_object("payments", h)

    h = {
      "user_id"           => user1_id,
      "destination_user_id" => user2_id,
      "amount"          => 500,
      "payment_type" => Payment::TYPE_TRANSFER,
      "created_at" => Time.now,
    }
    result = service.insert_object("payments", h)

    h = {
      "user_id"           => user2_id,
      "amount"          => 200,
      "payment_type" => Payment::TYPE_OUTGOING,
      "created_at" => Time.now,
    }
    result = service.insert_object("payments", h)


    # run server
    puts "Run kemal"

    spawn do
      Kemal.run
    end

    # wait for Kemal is ready
    while Kemal.config.server.nil?
      sleep 0.01
    end

    puts "Kemal is ready"

    # sign in
    http = HTTP::Client.new("localhost", Kemal.config.port)
    result = http.post_form("/sign_in", {"email" => sample_user1_email, "password" => sample_user1_password})
    json = JSON.parse(result.body)
    token = json["token"].to_s

    headers = HTTP::Headers.new
    headers["X-Token"] = token

    # not signed request
    http = HTTP::Client.new("localhost", Kemal.config.port)
    result = http.exec("GET", "/current_user")
    json = JSON.parse(result.body)
    json["id"]?.should eq nil
    json["email"]?.should eq nil

    http = HTTP::Client.new("localhost", Kemal.config.port)
    result = http.exec("GET", "/current_user", headers)
    json = JSON.parse(result.body)
    json["email"].should eq sample_user1_email
    json["handle"].should eq sample_user1_handle

    # get user balance
    http = HTTP::Client.new("localhost", Kemal.config.port)
    result = http.exec("GET", "/balance", headers)
    old_balance = result.body.to_s.to_i
    old_balance.should eq user1.balance

    # create transfer
    json_headers = HTTP::Headers.new
    json_headers["X-Token"] = token
    json_headers["Content-Type"] = "application/json"
    json_headers["Accept"] = "application/json"

    transfer_amount = 10
    http = HTTP::Client.new("localhost", Kemal.config.port)
    params = {"destination_user_id" => user2_id, "amount" => transfer_amount}
    result = http.exec("POST", "/transfer", json_headers, params.to_json)
    json = JSON.parse(result.body)

    # puts json.inspect

    # get new user balance
    result = http.exec("GET", "/balance", headers)
    new_balance = result.body.to_s.to_i
    new_balance.should eq user1.balance
    new_balance.should eq (old_balance - transfer_amount)

    # get list of incoming payments
    result = http.exec("GET", "/payments/incoming", headers)
    json = JSON.parse(result.body)
    # puts json.inspect

    # get list of incoming payments
    result = http.exec("GET", "/payments/transfer", headers)
    json = JSON.parse(result.body)
    puts json.inspect


  end
end
