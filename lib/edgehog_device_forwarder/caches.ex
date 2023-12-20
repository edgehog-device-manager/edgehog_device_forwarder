# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Caches do
  use Supervisor

  @caches Application.compile_env!(:edgehog_device_forwarder, __MODULE__)

  @spec all() :: keyword(atom())
  def all, do: @caches

  @spec all_ets_tables() :: [atom]
  def all_ets_tables do
    # We need to dedup because HTTPRequests and WebSockets share the same ets table
    Keyword.values(@caches)
    |> Enum.dedup()
  end

  @spec cache_id_for(module()) :: atom()
  def cache_id_for(module), do: Keyword.fetch!(@caches, module)

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_args) do
    all_ets_tables()
    |> Enum.map(&con_cache_child/1)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp con_cache_child(name) do
    params = [name: name, ttl_check_interval: false]
    id = {ConCache, name}

    {ConCache, params}
    |> Supervisor.child_spec(id: id)
  end
end
