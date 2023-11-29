defmodule EdgehogDeviceForwarder.Supervisors.TerminationCallbacks do
  use Supervisor

  @table :termination_callbacks_table

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_args) do
    con_cache_child = con_cache_spec()
    children = [con_cache_child, EdgehogDeviceForwarder.TerminationCallbacks]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp con_cache_spec do
    params = [name: @table, ttl_check_interval: false]
    id = {ConCache, @table}

    {ConCache, params}
    |> Supervisor.child_spec(id: id)
  end
end
