# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.CacheCase do
  use ExUnit.CaseTemplate
  alias EdgehogDeviceForwarder.Supervisors.TerminationCallbacks
  alias EdgehogDeviceForwarder.Caches

  setup_all do
    [valid_token: "some_token"]
  end

  setup do
    # Clean ets caches between tests
    Supervisor.terminate_child(EdgehogDeviceForwarder.Supervisor, TerminationCallbacks)
    Supervisor.terminate_child(EdgehogDeviceForwarder.Supervisor, Caches)
    Supervisor.restart_child(EdgehogDeviceForwarder.Supervisor, Caches)
    Supervisor.restart_child(EdgehogDeviceForwarder.Supervisor, TerminationCallbacks)

    [socket: self()]
  end
end
