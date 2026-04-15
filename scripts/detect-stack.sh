#!/usr/bin/env bash

set -euo pipefail

stacks=()

if [[ -f "composer.json" ]]; then
  stacks+=("laravel")
fi

if [[ -f "next.config.js" || -f "next.config.mjs" || -f "next.config.ts" ]]; then
  stacks+=("nextjs")
fi

if [[ -f "package.json" ]] && grep -qi '"next"' "package.json"; then
  if [[ ! " ${stacks[*]} " =~ " nextjs " ]]; then
    stacks+=("nextjs")
  fi
fi

if [[ -f "app.json" ]] && grep -qi '"expo"' "app.json"; then
  stacks+=("expo")
fi

if [[ -d "android" || -d "ios" ]]; then
  stacks+=("reactnative")
fi

if [[ ${#stacks[@]} -eq 0 ]]; then
  echo "common"
  exit 0
fi

printf '%s\n' "${stacks[@]}" | awk '!seen[$0]++'
