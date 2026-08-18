# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.SessionCookieTest do
  use EdgehogDeviceForwarderWeb.ConnCase

  alias EdgehogDeviceForwarderWeb.SessionCookie

  @cookie_name "edgehog_forwarder_session"

  describe "fetch/1" do
    test "decodes the session from a valid JWT cookie" do
      jwt = encode_jwt(%{session: "token", protocol: "http", port: 80})

      conn = put_cookie(jwt)

      assert {:ok, %{session: "token", protocol: "http", port: 80}} ==
               SessionCookie.fetch(conn)
    end

    test "returns an error when the cookie is missing" do
      conn = build_conn()

      assert {:error, :invalid_token} == SessionCookie.fetch(conn)
    end

    test "returns an error when the JWT is malformed" do
      conn = put_cookie("not_a_jwt")

      assert {:error, :invalid_token} == SessionCookie.fetch(conn)
    end

    test "returns an error when the payload is not valid base64" do
      jwt = "header.%%%invalid.signature"

      conn = put_cookie(jwt)

      assert {:error, :invalid_token} == SessionCookie.fetch(conn)
    end

    test "returns an error when the payload is not valid JSON" do
      payload = Base.url_encode64("not json", padding: false)
      jwt = "header.#{payload}.signature"

      conn = put_cookie(jwt)

      assert {:error, :invalid_token} == SessionCookie.fetch(conn)
    end

    test "returns an error when a field is missing from the payload" do
      jwt = encode_jwt(%{session: "token", protocol: "http"})

      conn = put_cookie(jwt)

      assert {:error, :invalid_token} == SessionCookie.fetch(conn)
    end

    test "returns an error when the fields have the wrong type" do
      jwt = encode_jwt(%{session: "token", protocol: "http", port: "80"})

      conn = put_cookie(jwt)

      assert {:error, :invalid_token} == SessionCookie.fetch(conn)
    end
  end

  defp encode_jwt(payload) do
    header = Base.url_encode64(~s({"alg":"none","typ":"JWT"}), padding: false)
    payload = Base.url_encode64(Jason.encode!(payload), padding: false)
    signature = Base.url_encode64("signature", padding: false)

    Enum.join([header, payload, signature], ".")
  end

  defp put_cookie(jwt), do: Plug.Test.put_req_cookie(build_conn(), @cookie_name, jwt)
end
