# Copyright 2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.SessionCookie do
  @moduledoc """
  Handles the JWT encoded cookie used to identify the device session.

  A plug that fetches and decodes the session from the request cookie,
  assigning it to `conn.assigns.session`. Halts with a 400 response when
  the cookie is missing or invalid.

  Requests carrying all of the session parameters (`session`, `protocol`
  and `port`) are passed through untouched, so that the controller can
  issue a new session cookie for them.
  """

  @behaviour Plug

  use Gettext, backend: EdgehogDeviceForwarderWeb.Gettext
  import Plug.Conn

  @cookie_name "edgehog_forwarder_session"

  @type session :: %{
          session: String.t(),
          protocol: String.t(),
          port: integer()
        }

  @impl true
  def init(opts), do: opts

  @impl true
  @spec call(Plug.Conn.t(), term) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn
    |> fetch_query_params()
    |> maybe_fetch_session()
  end

  defp maybe_fetch_session(
         %{query_params: %{"port" => _, "protocol" => _, "session" => _}} = conn
       ),
       do: conn

  defp maybe_fetch_session(conn) do
    case fetch(conn) do
      {:ok, session} ->
        assign(conn, :session, session)

      {:error, :invalid_token} ->
        error = dgettext("errors", "Invalid session token")

        conn
        |> send_resp(400, error)
        |> halt()
    end
  end

  @doc """
  Fetches and decodes the session from the request cookie.
  """
  @spec fetch(Plug.Conn.t()) :: {:ok, session} | {:error, :invalid_token}
  def fetch(conn) do
    with {:ok, jwt} <- fetch_cookie(conn),
         {:ok, session} <- decode_jwt(jwt) do
      {:ok, session}
    end
  end

  @spec fetch_cookie(Plug.Conn.t()) :: {:ok, String.t()} | {:error, :invalid_token}
  defp fetch_cookie(conn) do
    case fetch_cookies(conn).req_cookies do
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
