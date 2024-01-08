# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.BodyParser do
  @moduledoc """
  Body parser which just copies the content inside body_params.
  """

  @behaviour Plug

  def init(opts) do
    Keyword.pop(opts, :body_reader, {Plug.Conn, :read_body, []})
  end

  def call(conn, {{mod, fun, args}, opts}) do
    case apply(mod, fun, [conn, opts | args]) do
      {:ok, body, conn} ->
        conn = %{conn | body_params: %{}}
        update_in(conn.assigns, &Map.put(&1, :body, body))

      {:more, _data, _conn} ->
        raise Plug.Parsers.RequestTooLargeError

      {:error, :timeout} ->
        raise Plug.TimeoutError

      {:error, _} ->
        raise Plug.BadRequestError
    end
  end
end
