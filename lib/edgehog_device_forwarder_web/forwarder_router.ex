# Copyright 2023-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.ForwarderRouter do
  use EdgehogDeviceForwarderWeb, :router

  scope "/", EdgehogDeviceForwarderWeb do
    match :*, "/*path", UserController, :handle_in
  end
end
