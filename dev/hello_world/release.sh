#!/bin/bash -x

mix local.hex --force
mix deps.get
mix local.rebar --force
mix deps.compile
mix release --name=$1
