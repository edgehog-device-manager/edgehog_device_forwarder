# Copyright 2023-2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Tokens.Data do
  @moduledoc """
  Cached data for a Token.
  """

  use TypedStruct

  @type device_id :: String.t()
  @type realm :: String.t()
  @type device_socket :: pid()

  typedstruct do
    field :realm, realm()
    field :socket, device_socket(), required: true
    field :device_id, device_id()
  end

  @doc """
  Updates the data to include the device id and realm information.
  """
  @spec put_device_info(t, device_id, realm) :: t
  def put_device_info(data, device_id, realm) do
    %{
      data
      | realm: realm,
        device_id: device_id
    }
  end
end
