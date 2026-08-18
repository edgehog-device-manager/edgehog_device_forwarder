# Copyright 2023-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.CacheCase do
  use ExUnit.CaseTemplate
  alias EdgehogDeviceForwarder.Supervisors.TerminationCallbacks
  alias EdgehogDeviceForwarder.Caches

  setup_all :cache_setup_all
  setup :cache_setup

  def cache_setup_all(_context), do: [valid_token: "some_token"]

  def cache_setup(_context) do
    # Clean ets caches between tests
    Supervisor.terminate_child(EdgehogDeviceForwarder.Supervisor, TerminationCallbacks)
    Supervisor.terminate_child(EdgehogDeviceForwarder.Supervisor, Caches)
    Supervisor.restart_child(EdgehogDeviceForwarder.Supervisor, Caches)
    Supervisor.restart_child(EdgehogDeviceForwarder.Supervisor, TerminationCallbacks)

    [socket: self()]
  end
end
