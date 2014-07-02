#!/bin/sh -e

if [ ! -d "web" ]; then
  echo "Error: you must run this script from the client directory."
  exit
fi

PUB_PATH=pub
PUB_ARGS="serve --hostname 127.0.0.1 --port 9191"
DART_PATH=dart
DART_ARGS="bin/server.dart --host 127.0.0.1 --port 9090"
DART_ARGS="$DART_ARGS --pub-host 127.0.0.1 --pub-port 9191"

# Kill any child processes on exit.
trap 'kill $(jobs -pr)' SIGINT SIGTERM EXIT

echo "This script assumes that both *pub* and *dart* are in your PATH."
echo "Launching Observatory server."
echo "Launching pub."
echo ""
echo ""
echo ""
$DART_PATH $DART_ARGS &
$PUB_PATH $PUB_ARGS

