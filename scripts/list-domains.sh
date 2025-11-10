#!/usr/bin/env bash
# Lists all domain configurations found in the nginx/conf.d directory.

echo "--- Configured Domains ---"
ls -1 nginx/conf.d/ | grep -v '\.gitkeep' | sed 's/\.conf$//'
