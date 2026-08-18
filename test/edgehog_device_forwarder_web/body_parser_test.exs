# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.BodyParserTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias EdgehogDeviceForwarderWeb.BodyParser

  def more_reader(_conn, _opts), do: {:more, "data", nil}
  def timeout_reader(_conn, _opts), do: {:error, :timeout}
  def error_reader(_conn, _opts), do: {:error, :bad_request}

  test "raises RequestTooLargeError when the body reader returns :more" do
    conn = conn(:get, "/")

    assert_raise Plug.Parsers.RequestTooLargeError, fn ->
      BodyParser.call(conn, {{__MODULE__, :more_reader, []}, []})
    end
  end

  test "raises TimeoutError when the body reader returns {:error, :timeout}" do
    conn = conn(:get, "/")

    assert_raise Plug.TimeoutError, fn ->
      BodyParser.call(conn, {{__MODULE__, :timeout_reader, []}, []})
    end
  end

  test "raises BadRequestError when the body reader returns another error" do
    conn = conn(:get, "/")

    assert_raise Plug.BadRequestError, fn ->
      BodyParser.call(conn, {{__MODULE__, :error_reader, []}, []})
    end
  end
end
