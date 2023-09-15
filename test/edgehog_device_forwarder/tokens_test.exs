# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.TokensTests do
  alias EdgehogDeviceForwarder.Tokens
  use EdgehogDeviceForwarder.CacheCase

  setup %{sample_token: token, empty_socket: socket} do
    Tokens.register(token, socket)

    :ok
  end

  test "register/2 saves the socket in cache", %{empty_socket: socket} do
    new_token = "some_other_token"
    assert {:error, :token_not_found} == Tokens.fetch(new_token)
    assert :ok == Tokens.register(new_token, socket)
    assert {:ok, socket} == Tokens.fetch(new_token)
  end

  test "close/1 removes the token from the cache", %{sample_token: token} do
    assert :ok == Tokens.close(token)
    assert {:error, :token_not_found} == Tokens.fetch(token)
  end

  describe "add_device_info/2" do
    test "adds device info to existing token", %{sample_token: token} do
      realm = "some_realm"
      device_id = "some_device_id"
      assert :ok == Tokens.add_device_info(token, device_id, realm)
    end

    test "returns {:error, :token_not_found} when the token isn't in cache" do
      new_token = "some_other_token"
      realm = "some_realm"
      device_id = "some_device_id"

      assert {:error, :token_not_found} ==
               Tokens.add_device_info(new_token, device_id, realm)
    end
  end
end
