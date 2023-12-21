# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.HTTPRequests.Errors do
  @moduledoc """
  Error handling for `EdgehogDeviceForwarder.HTTPRequests`
  """
  require Logger

  alias EdgehogDeviceForwarder.HTTPRequests.Core

  @spec forward_to_invalid_request_id(Core.id(), term) :: {:error, :http_request_not_found}
  def forward_to_invalid_request_id(request_id, nil = _found_value) do
    "http-forward: request_id #{inspect(request_id)}: not found"
    |> Logger.notice(tag: "invalid_http_id")

    {:error, :http_request_not_found}
  end

  def forward_to_invalid_request_id(request_id, found_value) do
    "http-forward: request_id #{inspect(request_id)}: expected :http, got #{inspect(found_value)}"
    |> Logger.notice(tag: "invalid_http_id")

    {:error, :http_request_not_found}
  end
end
