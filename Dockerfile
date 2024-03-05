# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26

ARG IMAGE="elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-alpine"

FROM ${IMAGE} AS builder

RUN apk add git
WORKDIR /app
ENV MIX_ENV="prod"

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

RUN mkdir config
COPY config/config.exs config/$MIX_ENV.exs config/
RUN mix deps.compile

COPY lib lib
RUN mix compile
COPY config/runtime.exs config/

RUN mix release

FROM ${IMAGE}
EXPOSE 4000
WORKDIR "/app"
RUN chown nobody /app
ENV MIX_ENV="prod"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/edgehog_device_forwarder ./
USER nobody

CMD PHX_SERVER=true bin/edgehog_device_forwarder start
