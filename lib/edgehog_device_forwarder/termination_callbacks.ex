# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.TerminationCallbacks do
  use Supervisor

  alias EdgehogDeviceForwarder.TerminationCallbacks.Worker

  @cache_id :termination_callbacks_table

  defdelegate add(pid, on_close), to: Worker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_args) do
    con_cache_child = con_cache_spec()
    children = [con_cache_child, Worker]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp con_cache_spec do
    params = [name: @cache_id, ttl_check_interval: false]
    id = {ConCache, @cache_id}

    {ConCache, params}
    |> Supervisor.child_spec(id: id)
  end
end
