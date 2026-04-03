# ---- Build stage ----
ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.1.1
ARG ALPINE_VERSION=3.20.3

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS build

ENV MIX_ENV=prod \
    LANG=C.UTF-8

WORKDIR /app

RUN apk add --no-cache build-base

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && \
    mix deps.compile

COPY lib lib
RUN mix compile --warnings-as-errors

RUN mix release

FROM alpine:${ALPINE_VERSION} AS runtime

ENV LANG=C.UTF-8

RUN apk add --no-cache libstdc++ openssl ncurses-libs

ARG APP_USER=cashier
ARG APP_UID=1000
ARG APP_GID=1000

RUN addgroup -g ${APP_GID} ${APP_USER} && \
    adduser -u ${APP_UID} -G ${APP_USER} -h /app -D ${APP_USER}

WORKDIR /app

COPY --from=build --chown=${APP_USER}:${APP_USER} /app/_build/prod/rel/cashier ./

USER ${APP_USER}

ENTRYPOINT ["bin/cashier"]
CMD ["start"]
