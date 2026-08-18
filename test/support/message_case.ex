# Copyright 2023-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.MessageCase do
  use ExUnit.CaseTemplate

  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: HTTP

  setup_all :message_setup_all

  def message_setup_all(_context) do
    request =
      %HTTP.Request{
        path: "/",
        method: "GET",
        query_string: "",
        headers: %{"example" => "header", "content-type" => "plain/text"},
        body: "contents",
        port: 80
      }

    upgrade =
      %HTTP.Request{
        path: "/",
        method: "GET",
        query_string: "",
        headers: %{
          "content-type" => "plain/text",
          "status-code" => "101",
          "connection" => "upgrade",
          "upgrade" => "websocket",
          "sec-websocket-key" => "dGhlIHNhbXBsZSBub25jZQ==",
          "sec-websocket-version" => "13"
        },
        body: "",
        port: 80
      }

    response =
      %HTTP.Response{
        status_code: 200,
        headers: %{"content-type" => "plain/text"},
        body: "contents"
      }

    upgrade_response =
      %HTTP.Response{
        status_code: 101,
        headers: %{"upgrade" => "websocket"},
        body: ""
      }

    [
      http_request: request,
      http_upgrade_request: upgrade,
      http_response: response,
      http_upgrade_response: upgrade_response
    ]
  end
end
