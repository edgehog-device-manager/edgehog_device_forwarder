# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UserControllerTest do
  use EdgehogDeviceForwarder.ForwarderCase
  use EdgehogDeviceForwarderWeb.ConnCase

  alias EdgehogDeviceForwarderWeb.SessionCookie

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

    test "returns 400 when the session cookie is missing", %{
      conn: conn,
      http_request: request
    } do
      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(400)
    end

    test "returns 400 when the session cookie is invalid", %{
      conn: conn,
      http_request: request
    } do
      conn = put_req_cookie(conn, @cookie_name, "invalid_cookie")

      conn
      |> add_request_headers(request.headers)
      |> get("/", request.body)
      |> response(400)
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

    test "redirects to the host and sets a signed cookie", %{conn: conn} do
      conn = get(conn, "/?session=some_token&protocol=http&port=80")

      assert redirected_to(conn, 302) =~ conn.host

      assert %{@cookie_name => cookie} = conn.resp_cookies

      assert {:ok, %{session: "some_token", protocol: "http", port: 80}} =
               build_conn()
               |> put_req_cookie(@cookie_name, cookie.value)
               |> SessionCookie.fetch()
    end
  end

  def add_header({header, value}, conn), do: Plug.Conn.put_req_header(conn, header, value)
  def add_request_headers(conn, headers), do: Enum.reduce(headers, conn, &add_header/2)
end
