# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UserController do
  @moduledoc """
  Controller for client requests.
  """

  use EdgehogDeviceForwarderWeb, :controller

  alias EdgehogDeviceForwarder.Forwarder
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: HTTP

  action_fallback EdgehogDeviceForwarderWeb.ErrorController

  @doc """
  Redirect the request to the appropriate device session.
  """
  @spec handle_in(Plug.Conn.t(), any) ::
          Plug.Conn.t()
          | {:error, :invalid_request_port}
          | {:error, :request_timeout}
          | {:error, :token_not_found}
          | {:error, {:invalid_protocol, String.t()}}
  def handle_in(conn, params) do
    protocol = conn.path_params["protocol"] |> String.downcase(:ascii)

    case protocol do
      "http" -> handle_http(conn, params)
      other -> {:error, {:invalid_protocol, other}}
    end
  end

  @spec handle_http(Plug.Conn.t(), any) ::
          Plug.Conn.t()
          | {:error, :invalid_request_port}
          | {:error, :request_timeout}
          | {:error, :token_not_found}
  defp handle_http(conn, _params) do
    token = conn.path_params["session"]

    with {:ok, request} <- build_http_request(conn) do
      case Forwarder.http_to_device(token, request) do
        {:respond, response} ->
          conn
          |> merge_resp_headers(response.headers)
          |> send_resp(response.status_code, response.body)
          |> halt()

        {{:upgrade, :websocket}, _response, socket_data} ->
          conn
          |> WebSockAdapter.upgrade(EdgehogDeviceForwarderWeb.UserSocket, socket_data, [])
          |> halt()

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec build_http_request(Plug.Conn.t()) ::
          {:ok, HTTP.Request.t()} | {:error, :invalid_request_port}
  defp build_http_request(conn) do
    with {:ok, port} <- fetch_port(conn) do
      request = %HTTP.Request{
        path: Enum.join(conn.path_params["path"], "/"),
        method: conn.method,
        query_string: conn.query_string,
        headers: Map.new(conn.req_headers),
        body: conn.assigns.body,
        port: port
      }

      {:ok, request}
    end
  end

  @spec fetch_port(Plug.Conn.t()) :: {:ok, integer()} | {:error, :invalid_request_port}
  defp fetch_port(conn) do
    with {port, ""} <- Integer.parse(conn.path_params["port"]),
         true <- valid_port_range?(port) do
      {:ok, port}
    else
      _ -> {:error, :invalid_request_port}
    end
  end

  @spec valid_port_range?(integer) :: boolean
  defp valid_port_range?(port), do: port <= 65535 and port > 0
end
