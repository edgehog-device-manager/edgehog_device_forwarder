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

  alias EdgehogDeviceForwarderWeb.Guardian

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
         {:ok, claims} <- Guardian.decode_and_verify(jwt),
         {:ok, session} <- parse_session(claims) do
      {:ok, session}
    else
      _ -> {:error, :invalid_token}
    end
  end

  @spec fetch_cookie(Plug.Conn.t()) :: {:ok, String.t()} | {:error, :invalid_token}
  defp fetch_cookie(conn) do
    case fetch_cookies(conn).req_cookies do
      %{@cookie_name => jwt} -> {:ok, jwt}
      _ -> {:error, :invalid_token}
    end
  end

  defp parse_session(%{"session" => session, "protocol" => protocol, "port" => port})
       when is_binary(session) and is_binary(protocol) do
    with {:ok, port} <- parse_port(port) do
      {:ok, %{session: session, protocol: protocol, port: port}}
    end
  end

  defp parse_session(_), do: {:error, :invalid_token}

  @spec parse_port(String.t() | integer()) :: {:ok, integer()} | {:error, :invalid_request_port}
  defp parse_port(port) when is_binary(port) do
    case Integer.parse(port) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_request_port}
    end
  end

  defp parse_port(port) when is_integer(port), do: {:ok, port}

  defp parse_port(_port), do: {:error, :invalid_request_port}
end
