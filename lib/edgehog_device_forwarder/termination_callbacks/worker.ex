# Copyright 2023-2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.TerminationCallbacks.Worker do
  @moduledoc """
  Executes callbacks when the monitored processes exit.
  """

  use GenServer

  @cache_id :termination_callbacks_table

  @doc """
  Execute callback `on_close` when the given `pid` exits.

  The callback is guaranteed to be executed at least once.
  """
  @spec add(pid, (-> any)) :: :ok
  def add(pid, on_close) when is_pid(pid) and is_function(on_close, 0) do
    :ok = GenServer.call(__MODULE__, {:add, pid, on_close})
  end

  @spec start_link(any) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    # If the server is restarted, our pid changed
    #   hence, to receive the :DOWN, we need to re-monitor existing processes
    #   Process.monitor also sends the :DOWN for already dead pid, so we don't need to check that.
    ets_ref = ConCache.ets(@cache_id)

    for {pid, _} <- :ets.tab2list(ets_ref) do
      Process.monitor(pid)
    end

    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:add, pid, on_close}, _from, state)
      when is_pid(pid) and is_function(on_close, 0) do
    Process.monitor(pid)
    ConCache.put(@cache_id, pid, on_close)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # always run the callback at least once before deleting it
    callback = ConCache.get(@cache_id, pid)
    unless callback == nil, do: callback.()
    ConCache.delete(@cache_id, pid)

    {:noreply, state}
  end
end
