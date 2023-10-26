# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.MessageCase do
  use ExUnit.CaseTemplate

  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: HTTP

  setup_all do
    request =
      %HTTP.Request{
        path: "/",
        method: "GET",
        query_string: "",
        headers: %{"example" => "header", "content-type" => "plain/text"},
        body: "contents",
        port: 80
      }

    response =
      %HTTP.Response{
        status_code: 200,
        headers: %{"content-type" => "plain/text"},
        body: "contents"
      }

    [
      http_request: request,
      http_response: response
    ]
  end
end
