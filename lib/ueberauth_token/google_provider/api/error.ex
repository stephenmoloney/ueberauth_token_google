defmodule UeberauthToken.GoogleProvider.API.Error do
  @moduledoc false
  alias __MODULE__

  @type t :: %Error{
          key: String.t(),
          message: String.t()
        }

  defexception [:key, :message]

  def message(%{key: key, message: message})
      when is_binary(key) and is_binary(message) do
    """
    A #{key} error occurred during the api request due to reason:
    #{message}
    """
  end
end
