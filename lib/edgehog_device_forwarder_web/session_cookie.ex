# Copyright 2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.SessionCookie do
  @moduledoc """
  Handles the JWT encoded cookie used to identify the device session.
  """

  alias Plug.Conn

  @cookie_name "edgehog_forwarder_session"

  @type session :: %{
          optional(atom) => any(),
          session: String.t(),
          protocol: String.t(),
          port: integer()
        }

  @doc """
  Fetches and decodes the session from the request cookie.
  """
  @spec fetch(Conn.t()) :: {:ok, session} | {:error, :invalid_token}
  def fetch(conn) do
    with {:ok, jwt} <- fetch_cookie(conn),
         {:ok, session} <- decode_jwt(jwt) do
      {:ok, session}
    end
  end

  @spec fetch_cookie(Conn.t()) :: {:ok, String.t()} | {:error, :invalid_token}
  defp fetch_cookie(conn) do
    case Conn.fetch_cookies(conn).req_cookies do
      %{@cookie_name => jwt} -> {:ok, jwt}
      _ -> {:error, :invalid_token}
    end
  end

  # TODO: we don't actually verify the signature yet. Do it once the flow is in place
  @spec decode_jwt(String.t()) :: {:ok, session} | {:error, :invalid_token}
  defp decode_jwt(jwt) do
    with [_header, payload, _signature] <- String.split(jwt, "."),
         {:ok, json} <- Base.url_decode64(payload, padding: false),
         {:ok, data} <- Jason.decode(json),
         {:ok, session} <- parse_session(data) do
      {:ok, session}
    else
      _ -> {:error, :invalid_token}
    end
  end

  @spec parse_session(map) :: {:ok, session} | {:error, :invalid_token}
  defp parse_session(%{
         "session" => session,
         "protocol" => protocol,
         "port" => port
       })
       when is_binary(session) and is_binary(protocol) and is_integer(port) do
    {:ok, %{session: session, protocol: protocol, port: port}}
  end

  defp parse_session(_), do: {:error, :invalid_token}
end
