# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UserControllerTest do
  use EdgehogDeviceForwarder.ForwarderCase
  use EdgehogDeviceForwarderWeb.ConnCase

  @cookie_name "edgehog_forwarder_session"

  describe "handle_in/2" do
    test "redirects the request to the forwarder", %{
      conn: conn,
      ping_pong_token: token,
      http_request: request
    } do
      conn = put_session_cookie(conn, token, "http", 80)

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(200)
    end

    test "works with https", %{
      conn: conn,
      ping_pong_token: token,
      http_request: request
    } do
      conn = put_session_cookie(conn, token, "https", 80)

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(200)
    end

    test "upgrades to websocket on 101 upgrade websocket", %{
      conn: conn,
      ping_pong_token: token,
      http_upgrade_request: request
    } do
      conn = conn |> put_session_cookie(token, "http", 80) |> add_request_headers(request.headers)

      conn = %{conn | req_headers: [{"host", "localhost"} | conn.req_headers]}

      conn = get(conn, "/", request.body)

      assert conn.state == :upgraded
    end

    test "upgrades to websocket when the session JWT is in the query parameter", %{
      conn: conn,
      ping_pong_token: token,
      http_upgrade_request: request
    } do
      jwt = encode_jwt(%{session: token, protocol: "http", port: 80})

      conn = add_request_headers(conn, request.headers)
      conn = %{conn | req_headers: [{"host", "localhost"} | conn.req_headers]}

      conn = get(conn, "/?x-edgehog-forwarder-session=" <> jwt, request.body)

      assert conn.state == :upgraded

      # headers Plug.Cowboy.Handler copies verbatim into cowboy via
      # set_resp_header/3; a set-cookie here exits with
      # {:response_error, :invalid_header, ...} and kills the handshake
      refute "set-cookie" in for({k, _} <- conn.resp_headers, do: String.downcase(k))
    end

    test "returns 404 when no device is connected with the given token", %{
      conn: conn,
      http_request: request
    } do
      conn = put_session_cookie(conn, "not_connected_token", "http", 80)

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(404)
    end

    test "returns 400 with an invalid request port", %{
      conn: conn,
      http_request: request,
      ping_pong_token: token
    } do
      conn = put_session_cookie(conn, token, "http", 70000)

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(400)
    end

    test "returns 501 for an unsupported protocol", %{
      conn: conn,
      http_request: request
    } do
      conn = put_session_cookie(conn, "some_token", "ftp", 80)

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(501)
    end

    test "returns 401 when the session cookie is missing", %{
      conn: conn,
      http_request: request
    } do
      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(401)
    end

    test "returns 401 when the session cookie is invalid", %{
      conn: conn,
      http_request: request
    } do
      conn = put_req_cookie(conn, @cookie_name, "invalid_cookie")

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(401)
    end

    test "returns 408 if it reaches timeout", %{
      conn: conn,
      http_request: request,
      timeout_token: token
    } do
      conn = put_session_cookie(conn, token, "http", 80)

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(408)
    end
  end

  def add_header({header, value}, conn), do: Plug.Conn.put_req_header(conn, header, value)
  def add_request_headers(conn, headers), do: Enum.reduce(headers, conn, &add_header/2)
end
