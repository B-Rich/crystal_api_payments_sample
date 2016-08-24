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

    h = {"email" => sample_user1_email}
    result = service.get_filtered_objects("users", h)
    collection = crystal_resource_convert_user(result)
    if collection.size == 0
      # create user
      puts "Create user #{sample_user1_email}"
      h = {
        "email" => sample_user1_email,
         "handle" => sample_user1_handle,
         "hashed_password" => Crypto::MD5.hex_digest(sample_user1_password)
       }
      result = service.insert_object("users", h)
      collection = crystal_resource_convert_user(result)

      puts collection.inspect
    end


    #

    # spawn do
    #   Kemal.run
    # end
    #
    # # wait for Kemal is ready
    # while Kemal.config.server.nil?
    #   sleep 0.01
    # end

  end
end
