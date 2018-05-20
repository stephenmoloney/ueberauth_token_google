defmodule UeberauthToken.GoogleProvider.API do
  @moduledoc """
  Functions for fetching data from the google auth api

  ## Configuration options:

  * Can be passed by the application configuration
  * Can be passed directly into the function - those functions will take precedence

      config :ueberauth_token, UeberauthToken.GoogleProvider,
        httpipe_adapter_opts: [
                                pool: :ueberauth_token_google_provider_pool,
                                recv_timeout: 60_000
                              ]
  """
  alias HTTPipe.Conn
  alias __MODULE__.Error

  @base_url "https://www.googleapis.com/oauth2"
  @default_token_url "#{@base_url}/v3/tokeninfo"
  @default_user_url "#{@base_url}/v3/userinfo"
  @default_httpipe_adapter HTTPipe.Adapters.Hackney
  @default_httpipe_adapter_pool :ueberauth_token_google_provider_pool
  @default_httpipe_adapter_recv_timeout 10_000
  @default_httpipe_adapter_opts [
    pool: @default_httpipe_adapter_pool,
    recv_timeout: @default_httpipe_adapter_recv_timeout
  ]

  @callback fetch_data(token :: String.t(), url :: String.t(), opts :: Keyword.t()) ::
              {:ok, map()} | {:error, Error.t()}
  def fetch_data(token, url, opts \\ []) do
    httpipe_adapter = Keyword.get(opts, :httpipe_adapter, httpipe_adapter())
    httpipe_adapter_opts = Keyword.get(opts, :httpipe_adapter_opts, httpipe_adapter_opts())

    Conn.new()
    |> Conn.put_adapter(httpipe_adapter)
    |> Conn.put_adapter_options(httpipe_adapter_opts)
    |> Conn.put_req_method(:post)
    |> Conn.put_req_header("content-type", "application/json")
    |> Conn.put_req_url(url <> "?access_token=#{token}")
    |> Conn.execute()
    |> process_response()
  end

  defp process_response(%HTTPipe.Conn{response: %{body: body, status_code: status}})
       when status >= 200 and status < 400 do
    case Jason.decode(body) do
      {:ok, decoded_body} ->
        {:ok, decoded_body}

      {:error, error = %Jason.DecodeError{}} ->
        {:error,
         %Error{
           key: "jason decoding error",
           message: inspect(error)
         }}
    end
  end

  defp process_response(%HTTPipe.Conn{response: %{body: body, status_code: status}})
       when status >= 400 do
    case Jason.decode(body) do
      {:ok, %{"error" => error, "error_description" => error_description}} ->
        {:error,
         %Error{
           key: error,
           message: error_description
         }}

      {:ok, %{"error_description" => error_description}} ->
        {:error,
         %Error{
           key: "server response",
           message: error_description
         }}

      {:ok, decoded_response} ->
        {:error,
         %Error{
           key: "unexpected server response",
           message: inspect(decoded_response)
         }}
    end
  end

  defp process_response(%HTTPipe.Conn{error: error}) do
    {:error,
     %Error{
       key: "server communication",
       message: inspect(error)
     }}
  end

  @doc false
  @spec token_data_url() :: String.t()
  def token_data_url do
    Application.get_env(:ueberauth_token, __MODULE__)[:token_data_url] || @default_token_url
  end

  @doc false
  @spec user_data_url() :: String.t()
  def user_data_url do
    Application.get_env(:ueberauth_token, __MODULE__)[:user_data_url] || @default_user_url
  end

  @doc false
  @spec httpipe_adapter() :: module()
  def httpipe_adapter do
    Application.get_env(:ueberauth_token, __MODULE__)[:httpipe_adapter] ||
      @default_httpipe_adapter
  end

  @doc false
  @spec httpipe_adapter_opts() :: Keyword.t()
  def httpipe_adapter_opts do
    Application.get_env(:ueberauth_token, __MODULE__)[:httpipe_adapter_opts] ||
      @default_httpipe_adapter_opts
  end
end
