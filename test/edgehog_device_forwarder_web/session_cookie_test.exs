# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.SessionCookieTest do
  use EdgehogDeviceForwarderWeb.ConnCase

  alias EdgehogDeviceForwarderWeb.SessionCookie

  @cookie_name "edgehog_forwarder_session"

  describe "call/2" do
    test "assigns the session from a valid JWT cookie" do
      jwt = encode_jwt(%{session: "token", protocol: "http", port: 80})

      conn = build_conn() |> put_cookie(jwt) |> SessionCookie.call([])

      refute conn.halted

      assert %{
               session: "token",
               protocol: "http",
               port: 80,
               host: "127.0.0.1",
               insecure_tls_config: false
             } ==
               conn.assigns.session
    end

    test "halts with 401 when the cookie is missing" do
      assert_invalid_token(build_conn())
    end

    test "halts with 400 when the JWT is malformed" do
      build_conn() |> put_cookie("not_a_jwt") |> assert_invalid_token()
    end

    test "halts with 400 when the payload is not valid base64" do
      jwt = "header.%%%invalid.signature"

      build_conn() |> put_cookie(jwt) |> assert_invalid_token()
    end

    test "halts with 400 when the payload is not valid JSON" do
      payload = Base.url_encode64("not json", padding: false)
      jwt = "header.#{payload}.signature"

      build_conn() |> put_cookie(jwt) |> assert_invalid_token()
    end

    test "halts with 400 when a field is missing from the payload" do
      jwt = encode_jwt(%{session: "token", protocol: "http"})

      build_conn() |> put_cookie(jwt) |> assert_invalid_token()
    end

    test "halts with 400 when the fields have the wrong type" do
      jwt = encode_jwt(%{session: "token", protocol: "http", port: "not_a_number"})

      build_conn() |> put_cookie(jwt) |> assert_invalid_token()
    end

    test "accept the query parameter and sets a signed cookie" do
      jwt = encode_jwt(%{session: "token", protocol: "http", port: 80})

      conn = build_conn(:get, "/?x-edgehog-forwarder-session=" <> jwt) |> SessionCookie.call([])

      refute conn.halted

      assert %{
               session: "token",
               protocol: "http",
               port: 80,
               host: "127.0.0.1",
               insecure_tls_config: false
             } ==
               conn.assigns.session

      assert %{@cookie_name => _} = conn.resp_cookies
    end

    defp assert_invalid_token(conn) do
      conn = SessionCookie.call(conn, [])

      assert conn.halted
      assert conn.status == 401
    end
  end

  defp put_cookie(conn, jwt), do: Plug.Test.put_req_cookie(conn, @cookie_name, jwt)
end
