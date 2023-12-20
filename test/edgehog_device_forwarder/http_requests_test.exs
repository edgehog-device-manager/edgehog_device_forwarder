# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.HTTPRequestsTest do
  use EdgehogDeviceForwarder.CacheCase
  use EdgehogDeviceForwarder.MessageCase
  alias EdgehogDeviceForwarder.HTTPRequests

  setup %{socket: controller} do
    request_id = HTTPRequests.new(controller)

    [request_id: request_id]
  end

  test "new/1 returns the new message's id and registers the controller", %{
    socket: controller,
    http_response: response
  } do
    id = HTTPRequests.new(controller)

    assert :ok == HTTPRequests.forward(id, response)
  end

  describe "forward/2" do
    test "forwards the message to the controller", %{
      http_response: response,
      request_id: request_id
    } do
      assert :ok == HTTPRequests.forward(request_id, response)
      assert_receive {:respond, ^response}
    end

    test "deletes the message from the cache when not upgrading", %{
      request_id: request_id,
      http_response: response
    } do
      assert :ok = HTTPRequests.forward(request_id, response)
      assert {:error, :http_request_not_found} == HTTPRequests.forward(request_id, response)
    end
  end
end
