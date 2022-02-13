FROM hexpm/elixir:1.13.3-erlang-23.2.3-alpine-3.15.0 as build

WORKDIR /app

RUN apk add gcc git librdkafka-dev musl-dev

# install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only $MIX_ENV
RUN DEBUG=1 mix deps.compile
#
## build assets
#COPY assets assets
#RUN cd assets && npm install && npm run deploy
#RUN mix phx.digest

# build project
#COPY priv priv
COPY lib lib
RUN mix compile

# build release
# at this point we should copy the rel directory but
# we are not using it so we can omit it
# COPY rel rel
RUN mix release

# prepare release image
FROM hexpm/elixir:1.13.3-erlang-23.2.3-alpine-3.15.0 AS app

# install runtime dependencies
#RUN apk add --update bash openssl postgresql-client

EXPOSE 4000
ENV MIX_ENV=prod

# prepare app directory
RUN mkdir /app
WORKDIR /app

# copy release to app container
COPY --from=build /app/_build/prod/rel/kafkaex_lag_exporter .
# COPY entrypoint.sh .
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
CMD ["/app/bin/kafkaex_lag_exporter", "start"]
