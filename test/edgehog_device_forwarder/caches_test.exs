# Copyright 2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.CachesTest do
  use ExUnit.Case, async: true

  alias EdgehogDeviceForwarder.Caches

  test "all/0 returns the configured caches" do
    assert Caches.all() == [
             {EdgehogDeviceForwarder.Tokens, :token_table},
             {EdgehogDeviceForwarder.HTTPRequests, :message_table},
             {EdgehogDeviceForwarder.WebSockets, :message_table}
           ]
  end

  test "cache_id_for/1 returns the cache id for a module" do
    assert Caches.cache_id_for(EdgehogDeviceForwarder.Tokens) == :token_table
    assert Caches.cache_id_for(EdgehogDeviceForwarder.HTTPRequests) == :message_table
    assert Caches.cache_id_for(EdgehogDeviceForwarder.WebSockets) == :message_table
  end

  test "all_ets_tables/0 returns the deduplicated ets tables" do
    assert Caches.all_ets_tables() == [:token_table, :message_table]
  end
end
