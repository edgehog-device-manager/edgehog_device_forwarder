# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.ErrorJSON do
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
