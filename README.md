<!---
  Copyright 2023-2024 SECO Mind Srl
  SPDX-License-Identifier: Apache-2.0
-->

# Edgehog Device Forwarder

Proxy server to facilitate communication with Edgehog devices.
It handles HTTP messages and WebSocket connections between the device and the user client.

It's only been tested with simple WebSocket connections such as
[ttyd](https://github.com/tsl0922/ttyd), however it should handle arbitrary requests
as long as you keep in mind the [limitations](#known-issues-and-limitations).

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

> At the time of writing, not all the relevant code has been merged into the main branch.
> Use the following command command instead
>
> ```bash
> git clone https://github.com/noaccOS/edgehog_device_forwarder \
> -b feat/fallback-controller && cd edgehog_device_forwarder
> ```

You will need to install Elixir 1.15 with OTP 26.

> If you use [`asdf`](https://asdf-vm.com), you can use it to install our officially supported
> version, by using the `.tool-versions` file from
> [edgehog's repository](https://github.com/edgehog-device-manager/edgehog/blob/main/.tool-versions)
> and copy it here.

Now use the following command to start the server:

```bash
mix phx.server
```

### Connect a device

You will now need to start the device process.
You can do so from the same machine or another device or virtual machine, the process should look
exactly the same (granted port 4000 is open on the server's firewall).

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

This is a Rust program, so to compile it you will need to install `cargo`. Then run it using

```bash
cargo run -- -H server.local -t abcd
```

In this example

- `abcd` is our connection token, which will be used later to connect to the device
- `server.local` is the server's host address,
  so make sure to replace it with your actual server address

> You don't need to open any port on the device,
> as all requests will be done from the device itself.

If you don't get any error from the `cargo run` command you should be connected!

On the same machine, start a `ttyd` server:

```bash
ttyd -W bash
```

### User connection

All that's left is to actually perform the http requests!

From any device open a web browser and type in the url `http://server.local:4000/v1/abcd/http/7681`.
You should see ttyd's window in your browser!

> As before, you should replace `server.local` and `abcd`
> with your sever's host address and you connection token respectively.

## Known issues and limitations

- [ ] maximum message size: 8MB
