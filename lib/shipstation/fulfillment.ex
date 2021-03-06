defmodule Shipstation.Fulfillment do
  @moduledoc ~s"""
  List fulfillments that have been logged on your account
  """

  @doc ~s"""
  List fulfillments without Parameters
  """
  @spec list() :: Shipstation.Client.response_type
  def list() do
    uri = %{Shipstation.Client.base_uri | path: "/fulfillments"}
    Shipstation.Client.call_api(:get, uri, %{})
  end

  @doc ~s"""
  Obtains a list of fulfillments that match the specified criteria. Please note the following:

    - Orders that have been marked as shipped either through the UI or the API will appear in the response as they are considered fulfillments.
    - All of the available filters are optional.
  """
  @spec list(filter :: Shipstation.Structs.Fulfillment.t) :: Shipstation.Client.response_type
  def list(filter = %Shipstation.Structs.Fulfillment{}) do
    uri = %{Shipstation.Client.base_uri | path: "/fulfillments"}
    Shipstation.Client.call_api(:get, uri, filter)
  end

end
