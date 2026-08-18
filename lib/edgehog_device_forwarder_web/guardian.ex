# Copyright 2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.Guardian do
  use Guardian, otp_app: :edgehog_device_forwarder

  def subject_for_token(_resource, _claims), do: {:ok, "forwarder_session"}

  def resource_from_claims(claims), do: {:ok, claims}
end
