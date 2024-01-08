# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UserControllerTest do
  use EdgehogDeviceForwarder.ForwarderCase
  use EdgehogDeviceForwarderWeb.ConnCase

  describe "handle_in/2" do
    test "redirects the request to the forwarder", %{
      conn: conn,
      ping_pong_token: token,
      http_request: request
    } do
      path = "/v1/#{token}/http/80"

      conn
      |> add_request_headers(request.headers)
      |> get(path, request.body)
      |> response(200)
    end

    test "upgrades to websocket on 101 upgrade websocket", %{
      conn: conn,
      ping_pong_token: token,
      http_upgrade_request: request
    } do
      path = "/v1/#{token}/http/80"

      conn = add_request_headers(conn, request.headers)

      # WebSockAdapter doesn't handle Plug's Test adapter so it raises,
      #   but we know the connection is trying to upgrade to websocket
      assert_raise ArgumentError, "Unknown adapter Plug.Adapters.Test.Conn", fn ->
        get(conn, path, request.body)
      end
    end

    test "returns 404 when no device is connected with the given token", %{
      conn: conn,
      http_request: request
    } do
      not_connected_token = "not_connected_token"
      path = "/v1/#{not_connected_token}/http/80"

      conn
      |> add_request_headers(request.headers)
      |> get(path, request.body)
      |> response(404)
    end

    test "returns 400 with an invalid request port", %{
      conn: conn,
      http_request: request,
      ping_pong_token: token
    } do
      path = "/v1/#{token}/http/not_a_port"

      conn
      |> add_request_headers(request.headers)
      |> get(path, request.body)
      |> response(400)
    end

    test "returns 408 if it reaches timeout", %{
      conn: conn,
      http_request: request,
      timeout_token: token
    } do
      path = "/v1/#{token}/http/80"

      conn
      |> add_request_headers(request.headers)
      |> get(path, request.body)
      |> response(408)
    end
  end

  def add_header({header, value}, conn), do: Plug.Conn.put_req_header(conn, header, value)
  def add_request_headers(conn, headers), do: Enum.reduce(headers, conn, &add_header/2)
end
