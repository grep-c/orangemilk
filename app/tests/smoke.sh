#!/bin/sh

set -e

URL=$1

echo "Testing $URL..."

curl -s "$URL" | grep "OMK VERSION"

echo "Smoke test passed"