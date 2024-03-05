# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Health do
  require Logger

  @doc """
  Returns the status of the forwarder.

  :good means all its processes are working
  :bad means something is not working
  """
  @spec status :: :good | :bad
  def status do
    ets_tables = [:termination_callbacks_table | EdgehogDeviceForwarder.Caches.all_ets_tables()]

    try do
      # Check that ConCache is up and working. It raises on ets errors.
      for cache_id <- ets_tables do
        ConCache.size(cache_id)
      end

      # Check that the TerminationCallbacks process is up
      if nil == GenServer.whereis(EdgehogDeviceForwarder.TerminationCallbacks.Worker) do
        throw("TerminationCallbacks is down")
      end

      :good
    rescue
      _ ->
        Logger.warning("ConCache is not working", tag: "health")
        :bad
    catch
      e ->
        Logger.warning(e, tag: "health")
        :bad
    end
  end
end
