# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Tokens.TokenData do
  use TypedStruct

  @type device_id :: String.t()
  @type realm :: String.t()
  @type socket :: pid()

  typedstruct do
    field :realm, realm()
    field :socket, socket(), required: true
    field :device_id, device_id()
  end

  @spec put_device_info(t, device_id, realm) :: t
  def put_device_info(data, device_id, realm) do
    %{
      data
      | realm: realm,
        device_id: device_id
    }
  end
end
