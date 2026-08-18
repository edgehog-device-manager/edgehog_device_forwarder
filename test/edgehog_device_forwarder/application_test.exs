# Copyright 2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.ApplicationTest do
  use ExUnit.Case
  use Mimic

  alias EdgehogDeviceForwarder.Application

  test "config_change/3 forwards the changed config to the endpoint" do
    expect(EdgehogDeviceForwarderWeb.Endpoint, :config_change, fn _changed, _removed ->
      :ok
    end)

    assert :ok == Application.config_change(%{}, %{}, [])
  end
end
