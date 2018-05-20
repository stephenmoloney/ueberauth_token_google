defmodule UeberauthTokenGoogle.MixProject do
  use Mix.Project
  @version "0.1.0"
  @elixir_versions ">= 1.6.0"

  def project do
    [
      app: :ueberauth_token_google,
      version: @version,
      elixir: @elixir_versions,
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ueberauth_token, github: "quiqupltd/ueberauth_token"},
      {:httpipe, "~> 0.9.0"},
      {:httpipe_adapters_hackney, "~> 0.11.0"},
      {:jason, "~> 1.0"},
      {:mapail, "~> 1.0"},

      # dev/test
      {:credo, "~> 0.9.2", only: [:dev, :test], runtime: false},
      {:mox, "~> 0.3", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp elixirc_options(:dev), do: []
  defp elixirc_options(_), do: [warnings_as_errors: true]
end
