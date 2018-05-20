defmodule UeberauthToken.GoogleProvider.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  alias UeberauthToken.GoogleProvider.{API, APIMock}

  using do
    quote do
      alias Plug.Conn
      alias UeberauthToken.GoogleProvider
      alias UeberauthToken.GoogleProvider.{API, APIMock}
      alias Ueberauth.Auth.{Credentials, Extra, Info}
      import UeberauthToken.GoogleProvider.TestHelpers
      import Mox
    end
  end

  setup_all context do
    Mox.defmock(APIMock, for: API)
    {:ok, context}
  end

  setup context do
    {:ok, context}
  end
end
