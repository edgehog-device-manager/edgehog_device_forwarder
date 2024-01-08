# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.DeviceSocket do
  @moduledoc """
  Socket implementation for the Device-Server communication.
  """

  @behaviour Phoenix.Socket.Transport

  alias Plug.Conn
  alias EdgehogDeviceForwarder.Forwarder
  alias EdgehogDeviceForwarder.Tokens
  alias EdgehogDeviceForwarder.WebSockets
  require Logger

  @type state :: Phoenix.Socket.Transport.state()

  @spec child_spec(keyword) :: :ignore
  def child_spec(_opts) do
    :ignore
  end

  @doc """
  Executed on first connection.

  Rejects the connection if the token isn't present or if the specified token is already in use.
  """
  @spec connect(state) ::
          {:ok, state} | {:error, :unauthenticated} | {:error, :token_already_exists}
  def connect(state) do
    with {:ok, token} <- fetch_token_param(state.params),
         :ok <- Tokens.reserve(token) do
      {:ok, Map.put(state, :token, token)}
    end
  end

  @doc """
  Executed after the connection, in the socket's process.
  """
  @spec init(state) :: {:ok, state}
  def init(state) do
    :ok = Tokens.register(state.token, self())

    "accepting connection with token #{inspect(state.token)}"
    |> Logger.info(tag: "device_event")

    {:ok, state}
  end

  @doc """
  Executed when a message is received from the device.
  """
  @spec handle_in({binary, [{:opcode, :binary}]}, state) ::
          {:ok, state} | {:reply, :ok, WebSockets.message(), state}
  def handle_in({message, [{:opcode, :binary}]}, state) do
    case Forwarder.to_user(message) do
      :ok -> {:ok, state}
      {:reply, reply} -> {:reply, :ok, reply, state}
    end
  end

  @doc """
  Executed when a message is received from the user.
  """
  @spec handle_info(WebSockets.message(), state) :: {:push, WebSockets.message(), state}
  def handle_info(message, state) do
    {:push, message, state}
  end

  @spec terminate(term, state) :: :ok
  def terminate(_reason, _state) do
    :ok
  end

  @doc """
  Error handling for device socket's errors.
  """
  @spec connection_error(Conn.t(), :unauthenticated | :token_already_exists) :: Conn.t()
  def connection_error(conn, :unauthenticated), do: Conn.send_resp(conn, 401, "")
  def connection_error(conn, :token_already_exists), do: Conn.send_resp(conn, 409, "")

  @spec fetch_token_param(map) :: {:ok, String.t()} | {:error, :unauthenticated}
  defp fetch_token_param(params) do
    case Map.fetch(params, "session") do
      {:ok, token} -> {:ok, token}
      :error -> {:error, :unauthenticated}
    end
  end
end
