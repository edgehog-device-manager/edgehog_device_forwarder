<!---
  Copyright 2023-2024 SECO Mind Srl
  SPDX-License-Identifier: Apache-2.0
-->

# Edgehog Device Forwarder

Proxy server to facilitate communication with Edgehog devices.
It handles HTTP messages and WebSocket connections between the device and the user client.

It's only been tested with simple WebSocket connections such as
[`ttyd`](https://github.com/tsl0922/ttyd), however it should handle arbitrary requests
as long as you keep in mind its [limitations](#known-issues-and-limitations).

## Running the Forwarder locally

### Start the server

The first component to be available should be this server,
as both the device and the client will connect to it.

#### Manual installation

Run the following command to clone the current repository and navigate to it

```bash
git clone https://github.com/edgehog-device-manager/edgehog_device_forwarder && \
cd edgehog_device_forwarder
```

This project requires **Elixir 1.15** with **OTP 26** to run.
If you use [`asdf`](https://asdf-vm.com/) or [`nix`](https://nixos.org/), you may also use those
to install the officially supported version.

Now use the following command to start the server:

```bash
mix phx.server
```

### Connect a device

You will now need to start the device process.
You can do so from the same machine or another device or virtual machine.
The process should be the same, however make sure port 4000 is allowed by the server's firewall.

To connect to the server you will need to use the e2e-test-forwarder program, available in the
[`edgehog-device-runtime`](https://github.com/edgehog-device-manager/edgehog-device-runtime)
repository.

#### Manual install

> At the time of writing, you need to use a fork of said repository, because not all the code
> has been merged.
> Use the command
>
> ```bash
> git clone https://github.com/rgallor/edgehog-device-runtime -b ws-over-ws && \
> cd edgehog-device-runtime/e2e-test-forwarder
> ```

This is a Rust program, so to compile it you will need
to install [`cargo`](https://www.rust-lang.org/tools/install). Then run it using

```bash
cargo run -- -H server.local -t abcd
```

In this example:

- `abcd` is our connection token, which will be used later to connect to the device;
- `server.local` is the server's host address,
  so make sure to replace it with your actual server address.

> You don't need to open any port on the device,
> as all requests will be performed by the device itself.

If you don't get any error from the `cargo run` command you should be connected!

On the same machine, start a `ttyd` server:

```bash
ttyd -W bash
```

### User connection

All that's left is to actually perform the http requests!

From any device open a web browser and type in the url `http://server.local:4000/v1/abcd/http/7681`.
You should see `ttyd`'s window in your browser!

> As before, you should replace `server.local` and `abcd`
> with your server's host address and your connection token respectively.

## Known issues and limitations

- [ ] maximum message size: 8MB
