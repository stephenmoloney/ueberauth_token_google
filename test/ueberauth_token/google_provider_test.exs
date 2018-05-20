defmodule UeberauthToken.GoogleProviderTest do
  use UeberauthToken.GoogleProvider.TestCase

  @passing_token passing_access_token()
  @token_url token_url()
  @user_url user_url()

  describe "When the response from the api is succcesful" do
    setup [
      :set_mox_from_context,
      :verify_on_exit!
    ]

    test "get_payload/2", _context do
      expect_success()

      {:ok, actual_payload} = GoogleProvider.get_payload(@passing_token, [])

      assert actual_payload == expected_payload(:passing)
    end

    test "valid_token?/2", _context do
      expect_success()

      assert GoogleProvider.valid_token?(@passing_token)
    end

    test "get_uid/1", _context do
      expect_success()

      {:ok, payload} = GoogleProvider.get_payload(@passing_token, [])
      conn = Conn.put_private(%Conn{}, :ueberauth_token, %{payload: payload})

      assert GoogleProvider.get_uid(conn) == "unique_id"
    end

    test "get_credentials/1", _context do
      expect_success()

      {:ok, payload} = GoogleProvider.get_payload(@passing_token, [])
      conn = Conn.put_private(%Conn{}, :ueberauth_token, %{payload: payload})

      assert GoogleProvider.get_credentials(conn) == %Credentials{
               expires: true,
               expires_at: 1_526_774_835,
               other: %{
                 access_type: "online",
                 aud: "test_client_id.apps.googleusercontent.com",
                 azp: "test_client_id.apps.googleusercontent.com"
               },
               refresh_token: nil,
               scopes: [
                 "https://www.googleapis.com/auth/userinfo.profile",
                 "https://www.googleapis.com/auth/userinfo.email"
               ],
               secret: nil,
               token: "passing_access_token",
               token_type: "Bearer"
             }
    end

    test "get_info/1", _context do
      expect_success()

      {:ok, payload} = GoogleProvider.get_payload(@passing_token, [])
      conn = Conn.put_private(%Conn{}, :ueberauth_token, %{payload: payload})

      assert GoogleProvider.get_info(conn) == %Ueberauth.Auth.Info{
               description: nil,
               email: "tester@example.com",
               first_name: "John",
               image: "some_url",
               last_name: "Doe",
               location: nil,
               name: "John Doe",
               nickname: nil,
               phone: nil,
               urls: nil
             }
    end

    test "get_extra/1", _context do
      expect_success()

      {:ok, payload} = GoogleProvider.get_payload(@passing_token, [])
      conn = Conn.put_private(%Conn{}, :ueberauth_token, %{payload: payload})

      assert GoogleProvider.get_extra(conn) == %Extra{raw_info: payload}
    end

    test "get_ttl/1", _context do
      expect_success()

      {:ok, payload} = GoogleProvider.get_payload(@passing_token, [])

      assert GoogleProvider.get_ttl(payload) == 3_511_000
    end
  end

  defp expect_success do
    expect(APIMock, :fetch_data, fn @passing_token, @token_url, _opts ->
      {:ok, get_fixture(:token_data, :success)}
    end)

    expect(APIMock, :fetch_data, fn @passing_token, @user_url, _opts ->
      {:ok, get_fixture(:user_data, :success)}
    end)
  end
end
