# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.WebSockets.Data do
  @moduledoc """
  Cached data for a WebSocket connection.
  """

  use TypedStruct

  @type device_socket :: EdgehogDeviceForwarder.Tokens.Data.device_socket()
  @type socket_id :: binary()

  typedstruct do
    field :device, device_socket(), required: true
    field :socket_id, socket_id(), required: true
  end
end
