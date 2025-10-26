#!/bin/bash
echo "--- Настроенные домены ---"
ls -1 nginx/conf.d/ | grep -v '.gitkeep' | sed 's/\.conf$//'
