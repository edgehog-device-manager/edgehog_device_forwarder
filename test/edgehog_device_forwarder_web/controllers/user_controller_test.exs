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
  end

  def add_header({header, value}, conn), do: Plug.Conn.put_req_header(conn, header, value)
  def add_request_headers(conn, headers), do: Enum.reduce(headers, conn, &add_header/2)
end
