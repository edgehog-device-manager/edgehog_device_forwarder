# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UserController do
  @moduledoc """
  Controller for client requests.
  """

  use EdgehogDeviceForwarderWeb, :controller

  alias EdgehogDeviceForwarder.Forwarder
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: HTTP
  alias EdgehogDeviceForwarderWeb.SessionCookie

  action_fallback EdgehogDeviceForwarderWeb.ErrorController

  plug SessionCookie

  @doc """
  Redirect the request to the appropriate device session.
  """
  @spec handle_in(Plug.Conn.t(), any) ::
          Plug.Conn.t()
          | {:error, :invalid_request_port}
          | {:error, :request_timeout}
          | {:error, :token_not_found}
          | {:error, {:invalid_protocol, String.t()}}
  def handle_in(conn, params)

  def handle_in(conn, params) do
    session = conn.assigns.session
    protocol = session.protocol |> String.downcase(:ascii)

    case protocol do
      "http" -> handle_http(conn, params, session)
      "https" -> handle_http(conn, params, session, https: true)
      other -> {:error, {:invalid_protocol, other}}
    end
  end

  @spec handle_http(Plug.Conn.t(), any, SessionCookie.session(), Keyword.t()) ::
          Plug.Conn.t()
          | {:error, :invalid_request_port}
          | {:error, :request_timeout}
          | {:error, :token_not_found}
  defp handle_http(conn, _params, session, opts \\ []) do
    host = session.host
    insecure_tls_config = session.insecure_tls_config

    with {:ok, port} <- fetch_port(session.port) do
      request = build_http_request(conn, host, port, insecure_tls_config)

      case Forwarder.http_to_device(session.session, request, opts) do
        {:respond, response} ->
          conn
          |> merge_resp_headers(response.headers)
          |> send_resp(response.status_code, response.body)
          |> halt()

        {{:upgrade, :websocket}, response, socket_data} ->
          conn
          |> merge_resp_headers(response.headers)
          |> WebSockAdapter.upgrade(EdgehogDeviceForwarderWeb.UserSocket, socket_data, [])
          |> halt()

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec build_http_request(Plug.Conn.t(), String.t(), integer, boolean) :: HTTP.Request.t()
  defp build_http_request(conn, host, port, insecure_tls_config) do
    request = %HTTP.Request{
      host: host,
      path: Enum.join(conn.path_params["path"], "/"),
      method: conn.method,
      query_string: conn.query_string,
      headers: Map.new(conn.req_headers),
      body: conn.assigns.body,
      port: port,
      insecure_tls_config: insecure_tls_config
    }

    request
  end

  @spec fetch_port(integer) :: {:ok, integer} | {:error, :invalid_request_port}
  defp fetch_port(port) when port > 0 and port <= 65535, do: {:ok, port}
  defp fetch_port(_), do: {:error, :invalid_request_port}
end
