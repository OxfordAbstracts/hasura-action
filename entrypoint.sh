#!/bin/sh -l

set -e

if [ -z "$HASURA_ENDPOINT" ]; then
    echo "HASURA_ENDPOINT is required to run commands with the hasura cli"
    exit 126
fi

command="hasura $* --endpoint '$HASURA_ENDPOINT'"

if [ -n "$HASURA_ADMIN_SECRET" ]; then
    command="$command --admin-secret '$HASURA_ADMIN_SECRET'"
fi

if [ -n "$HASURA_WORKDIR" ]; then
    cd $HASURA_WORKDIR
fi

# create mock config file if none found
if [ ! -f config.yaml ]; then
    touch config.yaml
fi

if [ -n "$HASURA_ENGINE_VERSION" ]; then
    hasura update-cli --version $HASURA_ENGINE_VERSION
else
  DETECTED_HASURA_ENGINE_VERSION=$(curl -s "$HASURA_ENDPOINT"/v1/version \
    | jq .version \
    | awk '{split($0,a,"-"); print a[1]}' \
    | awk '{split($0,a,"\""); print a[2]}')

  if [ -n "$DETECTED_HASURA_ENGINE_VERSION" ]; then
      hasura update-cli --version $DETECTED_HASURA_ENGINE_VERSION
  fi
fi

# secrets can be printed, they are protected by Github Actions
echo "Executing $command from ${HASURA_WORKDIR:-./}"

export LD_PRELOAD=/lib/x86_64-linux-gnu/libstdc++.so.6:$LD_PRELOAD

sh -c "$command"
