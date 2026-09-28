#!/usr/bin/env bash
# Serves build/web on :8080 (used by the Playwright click-through scripts).
cd "$(dirname "$0")/../../build/web" && exec npx --yes http-server -p 8080 -s -c-1 .
