defmodule UeberauthToken.GoogleProvider.TestHelpers do
  @moduledoc false
  alias UeberauthToken.GoogleProvider.{API, Payload}

  @passing_access_token "passing_access_token"

  def passing_access_token, do: @passing_access_token
  def token_url, do: API.token_data_url()
  def user_url, do: API.user_data_url()

  def get_fixture(filename, success_or_failure \\ :success)

  def get_fixture(filename, :success) when is_atom(filename) do
    get_fixture(Atom.to_string(filename), :success)
  end

  def get_fixture(filename, :success) when is_binary(filename) do
    "test/fixtures/success/#{filename}.json"
    |> File.read!()
    |> Jason.decode!()
  end

  def get_fixture(filename, :failure) when is_atom(filename) do
    get_fixture(Atom.to_string(filename), :success)
  end

  def get_fixture(filename, :failure) when is_binary(filename) do
    "test/fixtures/failure/#{filename}.json"
    |> File.read!()
    |> Jason.decode!()
  end

  def expected_payload(:passing) do
    %Payload{
      email: "tester@example.com",
      exp: "1526774835",
      expires_in: "3511",
      family_name: "Doe",
      given_name: "John",
      name: "John Doe",
      other_token_info: %{
        access_type: "online",
        aud: "test_client_id.apps.googleusercontent.com",
        azp: "test_client_id.apps.googleusercontent.com"
      },
      picture: "some_url",
      provider: UeberauthToken.GoogleProvider,
      scope:
        "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email",
      sub: "unique_id",
      token: "passing_access_token",
      token_type: "Bearer",
      username: nil
    }
  end
end
