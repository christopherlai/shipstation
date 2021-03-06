defmodule Shipstation.Client do
  @moduledoc ~s"""
    Shipstation is a piece of software which makes it easy to import, manage and
    ship your orders. They aim to streamline shipping for online sellers, no
    matter where they sell their products online.

    This hex package is designed to allow you to integrate your ecommerce
    product with Shipstation's [publicly accessible
    API](http://www.shipstation.com/developer-api/).
  """

  use HTTPoison.Base
  require Logger
  alias Shipstation.Serializer

  @type response_type :: {atom, map}

  @spec default_headers() :: [tuple]
  def default_headers() do
    [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"},
      {"User-Agent", "shipstation-elixir-client/#{Application.spec(:shipstation, :vsn)}"}
    ]
  end

  @spec base_uri() :: URI.t
  def base_uri,
  do: URI.parse(Application.get_env(:shipstation, :base_uri))

  @doc ~s"""
  This function decides if there is enough data to build a Basic Authentication
  header to add into the request. This is useful because it will attempt to make
  the request without the header if there isn't enough data. You might want to do
  this if you are wanting to create a new account through the API.
  """
  @spec auth() :: [{:basic_auth, {String.t, String.t}}] | []
  def auth do
    case Application.get_env(:shipstation, :auth) do
      %{api_key: nil} -> []
      %{api_secret: nil} -> []
      %{api_key: key, api_secret: secret} ->
        hash = Base.encode64("#{key}:#{secret}")
        [{"Authorization", "Basic #{hash}"}]
      _ -> []
    end
  end

  def call_api(verb, uri, body),
  do: call_api(verb, uri, body, [])

  @doc ~s"""
  This is the function that calls the API on behalf of the rest of the codebase.
  It will compile the component pieces of the request and add in authentication
  information when necessary.
  """
  @spec call_api(verb :: atom, uri :: URI.t, body :: map | list(map), custom_headers :: list(map)) :: response_type
  def call_api(:get, uri = %URI{}, body, custom_headers) do
    # Backoff for as long as the API asks us to.
    if !Shipstation.RequestLimit.should_request?,
      do: Shipstation.RequestLimit.backoff

    headers = default_headers() ++ auth() ++ custom_headers

    params =
      body
      |> Serializer.deep_consolidate
      |> URI.encode_query

    uri = %{uri | query: params} |> URI.parse

    resp = get(uri, headers, httpoison_request_options())

    Shipstation.RequestLimit.set_api_rate(resp)
    handle_response(resp)
  end

  def call_api(verb, uri = %URI{}, body, custom_headers) do
    # Backoff for as long as the API asks us to.
    if !Shipstation.RequestLimit.should_request?,
    do: Shipstation.RequestLimit.backoff

    # Build up final HTTP request to be sent to the API
    payload =
      body
      |> Serializer.deep_consolidate
      |> Poison.encode!
    headers = default_headers() ++ auth() ++ custom_headers

    resp = request(verb, uri, payload, headers, httpoison_request_options())

    Shipstation.RequestLimit.set_api_rate(resp)
    handle_response(resp)
  end

  defp handle_response({:ok, resp = %{body: ""}}),
  do: %{status_code: resp.status_code}

  defp handle_response({:ok, resp = %{body: _}}),
  do: return_json(resp)

  defp handle_response(resp),
  do: resp

  defp return_json(resp) do
    case Poison.decode(resp.body) do
      {:ok, body} ->
        {:ok, %{body: body, status_code: resp.status_code}}
      {:error, _err} ->
        Logger.error("Could not parse JSON: #{resp.body}")
        {:error, "Could not parse JSON: #{resp.body}"}
    end
  end

  defp httpoison_request_options() do
    Application.get_env(:shipstation, :httpoison_options, [])
  end
end
