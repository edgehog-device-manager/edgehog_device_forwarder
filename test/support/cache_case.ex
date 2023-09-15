# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.CacheCase do
  use ExUnit.CaseTemplate
  alias EdgehogDeviceForwarder.Cache

  setup_all do
    [sample_token: "some_token", empty_socket: spawn(fn -> nil end)]
  end

  setup do
    # Clean cache between tests
    for cache <- Cache.all_ets_tables() do
      Supervisor.terminate_child(Cache, {ConCache, cache})
      Supervisor.restart_child(Cache, {ConCache, cache})
    end
  end
end
