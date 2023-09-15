# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Tokens do
  alias EdgehogDeviceForwarder.Tokens.TokenData

  @tokens EdgehogDeviceForwarder.Cache.for(__MODULE__)
  @type token :: String.t()
  @type device_id :: TokenData.device_id()
  @type realm :: TokenData.realm()
  @type socket :: TokenData.socket()

  @spec add_device_info(token, device_id, realm) ::
          :ok | {:error, :token_not_found}
  def add_device_info(token, device_id, realm) do
    ConCache.update(@tokens, token, fn
      nil -> {:error, :token_not_found}
      token_data -> {:ok, TokenData.put_device_info(token_data, device_id, realm)}
    end)
  end

  @spec register(token, socket) :: :ok | {:error, :already_exists}
  def register(token, socket) do
    # TODO: check if we need to handle socket's process termination ourself.
    # I'd be inclined to say no from
    #   - https://hexdocs.pm/phoenix/Phoenix.Socket.Transport.html#c:terminate/2
    #   - https://hexdocs.pm/phoenix/Phoenix.Socket.Transport.html#module-custom-transports
    ConCache.insert_new(@tokens, token, %TokenData{socket: socket})
  end

  @spec close(token) :: :ok
  def close(token) do
    ConCache.delete(@tokens, token)
  end

  @spec fetch(token) :: {:ok, socket} | {:error, :token_not_found}
  def fetch(token) do
    case ConCache.get(@tokens, token) do
      nil -> {:error, :token_not_found}
      %TokenData{socket: socket} -> {:ok, socket}
    end
  end
end
