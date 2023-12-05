# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.TerminationCallbacksTest do
  use ExUnit.Case

  alias EdgehogDeviceForwarder.TerminationCallbacks
  alias EdgehogDeviceForwarder.TerminationCallbacks.Worker

  setup do
    Supervisor.terminate_child(EdgehogDeviceForwarder.Supervisor, TerminationCallbacks)
    Supervisor.restart_child(EdgehogDeviceForwarder.Supervisor, TerminationCallbacks)

    process = spawn(fn -> wait_for_exit() end)
    [process: process]
  end

  test "callback closure is executed once the process exits", %{process: process} do
    message = :done
    me = self()
    send_message_to_self = fn -> send(me, message) end
    TerminationCallbacks.add(process, send_message_to_self)

    send(process, :exit)
    assert_receive ^message
  end

  test "the callback is executed even if the server restarts", %{process: process} do
    message = :done
    me = self()
    send_message_to_self = fn -> send(me, message) end

    TerminationCallbacks.add(process, send_message_to_self)

    Supervisor.terminate_child(TerminationCallbacks, Worker)
    Supervisor.restart_child(TerminationCallbacks, Worker)

    send(process, :exit)
    assert_receive ^message, :timer.seconds(1)
  end

  def wait_for_exit do
    receive do
      :exit -> :ok
    end
  end
end
