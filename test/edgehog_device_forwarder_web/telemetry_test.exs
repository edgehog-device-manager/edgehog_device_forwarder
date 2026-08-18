# Copyright 2023-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.TelemetryTest do
  use ExUnit.Case, async: true

  test "metrics/0 returns the configured metrics" do
    metrics = EdgehogDeviceForwarderWeb.Telemetry.metrics()

    assert is_list(metrics)
    assert length(metrics) > 0
    assert Enum.all?(metrics, &match?(%Telemetry.Metrics.Summary{}, &1))
  end
end
