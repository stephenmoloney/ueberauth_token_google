use Mix.Config

if Mix.env() == :test do
  config :ueberauth_token, UeberauthToken.Config, providers: [UeberauthToken.GoogleProvider]

  config :ueberauth_token, UeberauthToken.GoogleProvider,
    use_cache: {:system, :boolean, "GOOGLE_PROVIDER_USE_CACHE", false},
    cache_name: {:system, :atom, "GOOGLE_PROVIDER_CACHE_NAME", :ueberauth_token_google_provider},
    background_checks: {:system, :boolean, "GOOGLE_PROVIDER_BACKGROUND_CHECKS", false},
    token_info_url:
      {:system, :string, "GOOGLE_PROVIDER_TOKEN_INFO_URL",
       "https://www.googleapis.com/oauth2/v4/token"},
    user_info_url:
      {:system, :string, "GOOGLE_PROVIDER_TOKEN_INFO_URL",
       "https://www.googleapis.com/oauth2/v4/token"},
    httpipe_adapter:
      {:system, :module, "GOOGLE_PROVIDER_HTTPIPE_ADAPTER", HTTPipe.Adapters.Hackney},
    httpipe_adapter_opts: [
      pool: :ueberauth_token_google_provider_pool,
      recv_timeout: 60_000
    ],
    api: {:system, :module, "GOOGLE_PROVIDER_API_MODULE", UeberauthToken.GoogleProvider.APIMock},
    client_id: {:system, :string, "GOOGLE_PROVIDER_CLIENT_ID", "test_client_id"}
end
