# Copyright 2023-2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Tokens do
  @moduledoc """
  Interface to the cache for the device Tokens.
  """

  alias EdgehogDeviceForwarder.Tokens.Data
  alias EdgehogDeviceForwarder.TerminationCallbacks
  require Logger

  @cache_id EdgehogDeviceForwarder.Caches.cache_id_for(__MODULE__)
  @type token :: String.t()
  @type device_id :: Data.device_id()
  @type realm :: Data.realm()
  @type device_socket :: Data.device_socket()

  @doc """
  Saves device information in cache.
  """
  @spec add_device_info(token, device_id, realm) ::
          :ok | {:error, :token_not_found}
  def add_device_info(token, device_id, realm) do
    ConCache.update(@cache_id, token, fn
      nil -> {:error, :token_not_found}
      token_data -> {:ok, Data.put_device_info(token_data, device_id, realm)}
    end)
  end

  @doc """
  Makes a reservation for a token.
  """
  @spec reserve(token) :: :ok | {:error, :token_already_exists}
  def reserve(token) do
    case ConCache.insert_new(@cache_id, token, :reserved) do
      :ok -> :ok
      {:error, :already_exists} -> {:error, :token_already_exists}
    end
  end

  @doc """
  Registers the device socket under the specified token.

  The token has to be reserved before attempting the registration.
  """
  @spec register(token, device_socket) :: :ok | {:error, :invalid_data}
  def register(token, socket) do
    ConCache.update(@cache_id, token, fn
      :reserved ->
        add_termination_callback(socket, token)
        {:ok, %Data{socket: socket}}

      other ->
        "tokens: register: token #{inspect(token)}: found #{inspect(other)}"
        |> Logger.notice(tag: "token_data_error")

        {:error, :invalid_data}
    end)
  end

  @doc """
  Removes the connection to the specified token.
  """
  @spec close(token) :: :ok
  def close(token) do
    ConCache.delete(@cache_id, token)

    "connection closed for token #{inspect(token)}"
    |> Logger.info(tag: "device_event")
  end

  @doc """
  Fetch token data form the cache.
  """
  @spec fetch(token) :: {:ok, Data.t()} | {:error, :token_not_found}
  def fetch(token) do
    case ConCache.get(@cache_id, token) do
      nil -> {:error, :token_not_found}
      data -> {:ok, data}
    end
  end

  @doc """
  Fetch the device socket from the token.
  """
  @spec fetch_device_socket(token) :: {:ok, device_socket} | {:error, :token_not_found}
  def fetch_device_socket(token) do
    with {:ok, %Data{socket: socket}} <- fetch(token) do
      {:ok, socket}
    end
  end

  @spec add_termination_callback(device_socket, token) :: :ok
  defp add_termination_callback(socket, token) do
    TerminationCallbacks.add(socket, fn -> close(token) end)
  end
end
