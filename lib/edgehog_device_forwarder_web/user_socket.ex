# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UserSocket do
  @moduledoc """
  Socket used for a WebSocket connection between the user client and the forwarder server.
  """

  @behaviour WebSock

  alias EdgehogDeviceForwarder.Forwarder
  alias EdgehogDeviceForwarder.WebSockets
  alias EdgehogDeviceForwarder.WebSockets.Data

  require Logger

  @doc """
  Executed when upgrading the HTTP Request to a WebSocket.
  """
  @spec init(Data.t()) :: {:ok, Data.t()} | {:stop, {:error, :http_request_not_found}, Data.t()}
  def init(state) do
    case WebSockets.upgrade(state.socket_id, self(), state) do
      :ok -> {:ok, state}
      {:error, reason} -> {:stop, {:error, reason}, state}
    end
  end

  @doc """
  Executed when a message is received from the user.
  """
  def handle_in({message, opts}, state) do
    message_type = Keyword.fetch!(opts, :opcode)
    Forwarder.ws_to_device(state, {message_type, message})
    {:ok, state}
  end

  @doc """
  Executed when a message is received from the device
  """
  def handle_info({:error, reason}, state) do
    {:stop, {:error, reason}, state}
  end

  def handle_info({:close, close_details}, state) do
    {:stop, :normal, close_details, state}
  end

  def handle_info(message, state) do
    {:push, message, state}
  end
end
