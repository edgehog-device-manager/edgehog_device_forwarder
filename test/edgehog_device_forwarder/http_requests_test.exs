defmodule EdgehogDeviceForwarder.HTTPRequestsTest do
  use EdgehogDeviceForwarder.CacheCase
  alias EdgehogDeviceForwarder.HTTPRequests

  setup_all do
    [empty_socket_2: spawn(fn -> 1 end)]
  end

  setup %{empty_socket: controller} do
    request_id = HTTPRequests.new(controller)

    [request_id: request_id]
  end

  test "new/1 returns the new message's id and registers the controller", %{
    empty_socket: controller
  } do
    id = HTTPRequests.new(controller)

    assert {:ok, controller} == HTTPRequests.fetch(id, :respond)
  end

  describe "fetch/2" do
    test "gives back the controller", %{empty_socket: controller, request_id: request_id} do
      assert {:ok, controller} == HTTPRequests.fetch(request_id, :respond)
    end

    test "deletes the message from the cache with :respond method", %{request_id: request_id} do
      assert {:ok, _} = HTTPRequests.fetch(request_id, :respond)

      assert {:error, :http_request_not_found} ==
               HTTPRequests.fetch(request_id, :respond)
    end
  end
end
