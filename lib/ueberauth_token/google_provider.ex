defmodule UeberauthToken.GoogleProvider do
  @moduledoc """
  Provider for implemention of the callbacks for ueberauth_token - a token based workflow.

  See [ueberauth_token](https://github.com/quiqupltd/ueberauth_token)
  """
  alias Ueberauth.Auth.{Credentials, Extra, Info}
  alias __MODULE__.{API, Payload}
  alias __MODULE__.API.Error

  @behaviour UeberauthToken.Strategy

  defmodule Payload do
    @moduledoc false

    defstruct(
      sub: nil,
      provider: UeberauthToken.GoogleProvider,
      token: nil,
      token_type: "Bearer",
      expires_in: 0,
      exp: nil,
      scope: "",
      other_token_info: %{
        access_type: nil,
        aud: nil,
        azp: nil
      },
      name: nil,
      given_name: nil,
      family_name: nil,
      username: nil,
      email: nil,
      picture: nil
    )
  end

  @type t :: %Payload{
          # will be mapped to %Auth{}
          sub: binary() | nil,
          provider: module(),

          # will be mapped to %Credentials{}
          token: binary(),
          token_type: String.t(),
          exp: String.t(),
          expires_in: String.t(),
          scope: String.t(),
          other_token_info: map(),

          # will be mapped to %Info{}
          name: binary() | nil,
          given_name: binary() | nil,
          family_name: binary() | nil,
          username: binary() | nil,
          email: binary() | nil,
          picture: binary() | nil
        }

  @doc """
  Fetches the payload data and builds a `%Payload{}`.

  ## Options

      * `http_adapter` - The adapter to be used for the `%HTTPipe.Conn{}`
      * `http_adapter_opts` - The adapter options for the `%HTTPipe.Conn{}`
      * `client_id` - The client_id for the google client
  """
  @spec get_payload(token :: String.t(), opts :: list()) ::
          {:ok, Payload.t()} | {:error, Error.t()} | {:error, any()}
  @impl true
  def get_payload(token, opts \\ []) do
    with {:ok, token_data} <- api().fetch_data(token, API.token_data_url(), opts),
         {:ok, user_data} <- api().fetch_data(token, API.user_data_url(), opts),
         {:ok, %Payload{other_token_info: %{aud: aud}} = payload} <-
           build_payload(token, token_data, user_data),
         :ok <- validate_client_id(aud, opts) do
      {:ok, payload}
    end
  end

  @doc """
  Validates a token.

  ## Options

      * `http_adapter` - The adapter to be used for the `%HTTPipe.Conn{}`
      * `http_adapter_opts` - The adapter options for the `%HTTPipe.Conn{}`
      * `client_id` - The client_id for the google client
  """
  @spec valid_token?(token :: String.t(), opts :: list()) :: boolean()
  @impl true
  def valid_token?(token, opts \\ []) do
    with {:ok, %Payload{other_token_info: %{aud: aud}}} <- get_payload(token, opts),
         true <- valid_client_id?(aud, opts) do
      true
    else
      _ -> false
    end
  end

  @doc false
  @spec get_uid(conn :: Conn.t()) :: any()
  @impl true
  def get_uid(%{
        private: %{
          ueberauth_token: %{
            payload: %Payload{
              sub: id
            }
          }
        }
      }) do
    id
  end

  @doc false
  @spec get_credentials(conn :: Conn.t()) :: Credentials.t()
  @impl true
  def get_credentials(%{
        private: %{
          ueberauth_token: %{
            payload: %Payload{
              token: access_token,
              token_type: token_type,
              exp: unix_expiry,
              expires_in: expires_in,
              scope: scope,
              other_token_info: other_token_info
            }
          }
        }
      })
      when not is_nil(expires_in) and not is_nil(access_token) and not is_nil(scope) and
             not is_nil(unix_expiry) do
    expires_in = String.to_integer(expires_in)
    unix_expiry = String.to_integer(unix_expiry)
    scope = String.split(scope, " ")
    now = DateTime.to_unix(DateTime.utc_now())
    expires? = is_integer(expires_in)

    expires_at_unix =
      case expires? do
        true -> unix_expiry
        false -> now - 1
      end

    %Credentials{
      token: access_token,
      refresh_token: nil,
      token_type: token_type,
      secret: nil,
      expires: expires?,
      expires_at: expires_at_unix,
      scopes: scope,
      other: other_token_info
    }
  end

  @doc false
  @spec get_info(conn :: Conn.t()) :: Info.t()
  @impl true
  def get_info(%{
        private: %{
          ueberauth_token: %{
            payload: %Payload{
              name: name,
              given_name: first_name,
              family_name: last_name,
              username: username,
              email: email,
              picture: image
            }
          }
        }
      }) do
    %Info{
      name: name,
      first_name: first_name,
      last_name: last_name,
      nickname: username,
      email: email,
      location: nil,
      description: nil,
      image: image,
      phone: nil,
      urls: nil
    }
  end

  @doc false
  @spec get_extra(conn :: Conn.t()) :: Extra.t()
  @impl true
  def get_extra(%{
        private: %{
          ueberauth_token: %{
            payload: %Payload{} = payload
          }
        }
      }) do
    %Extra{
      raw_info: payload
    }
  end

  @doc """
  Gets the ttl from the `%Payload{}`.
  """
  @spec get_ttl(payload :: Payload.t()) :: integer()
  @impl true
  def get_ttl(%Payload{expires_in: expires_in}) do
    expires_in
    |> String.to_integer()
    |> :timer.seconds()
  end

  @doc false
  @spec api() :: module()
  def api do
    Application.get_env(:ueberauth_token, __MODULE__)[:api] || UeberauthToken.GoogleProvider.API
  end

  @doc false
  @spec client_id() :: String.t()
  def client_id do
    Application.get_env(:ueberauth_token, __MODULE__)[:client_id]
  end

  defp build_payload(token, token_data, user_data) do
    with %{} = raw_payload <- Map.merge(token_data, user_data),
         {:ok, %Payload{} = payload} <- Mapail.map_to_struct(raw_payload, Payload) do
      other_token_info =
        raw_payload
        |> Map.take(["access_type", "aud", "azp"])
        |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, String.to_existing_atom(k), v) end)

      {:ok,
       payload
       |> Map.put(:other_token_info, other_token_info)
       |> Map.put(:token, token)}
    end
  end

  defp valid_client_id?(aud, opts) do
    client_id = Keyword.get(opts, :client_id, client_id())
    "#{client_id}.apps.googleusercontent.com" == aud
  end

  defp validate_client_id(aud, opts) do
    if valid_client_id?(aud, opts) do
      :ok
    else
      {:error,
       %Error{key: "confused deputy", message: "the aud #{aud} and #{client_id()} do not match"}}
    end
  end
end
