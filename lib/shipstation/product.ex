defmodule Shipstation.Product do
  @moduledoc ~s"""
  Manage Products hosted on your account
  """

  @doc ~s"""
  Get product
  """
  @spec get(id :: integer) :: Shipstation.response_type
  def get(id) do
    uri = %{Shipstation.base_uri | path: "/products/#{id}"}
    Shipstation.call_api(:get, uri, %{})
  end

  @doc ~s"""
  List all matching products
  """
  @spec list() :: Shipstation.response_type
  def list() do
    uri = %{Shipstation.base_uri | path: "/products"}
    Shipstation.call_api(:get, uri, %{})
  end

  @spec list(filter :: Shipstation.Structs.ProductFilter.t) :: Shipstation.response_type
  def list(filter = %Shipstation.Structs.ProductFilter{}) do
    uri = %{Shipstation.base_uri | path: "/products"}
    Shipstation.call_api(:get, uri, filter)
  end

  @doc ~s"""
  Updates an existing product. This call does not currently support partial
  updates - the entire product must be provided in order for the update to work
  as expected.
  """
  @spec update(product_id :: integer, product :: Shipstation.Structs.Product.t) :: Shipstation.response_type
  def update(product_id, product = %Shipstation.Structs.Product{}) do
    uri = %{Shipstation.base_uri | path: "/products/#{product_id}"}
    Shipstation.call_api(:put, uri, product)
  end

end
