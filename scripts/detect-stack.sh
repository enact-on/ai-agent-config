#!/bin/bash

###############################################################################
# Tech Stack Detection Script
#
# This script detects the technology stack used in the current directory.
# Output: Comma-separated list of detected stacks (e.g., "laravel,nextjs")
#
# Usage: bash detect-stack.sh
###############################################################################

# Initialize empty stack variable
STACK=""

# Detect Laravel/PHP
if [ -f "composer.json" ]; then
    if grep -q '"laravel"' composer.json 2>/dev/null || \
       grep -q '"illuminate' composer.json 2>/dev/null || \
       grep -q '"php"' composer.json 2>/dev/null; then
        STACK="$STACK,laravel"
    fi
fi

# Detect Next.js
if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
    STACK="$STACK,nextjs"
fi

# Detect Node.js (general, non-Next.js)
if [ -f "package.json" ] && [[ ! "$STACK" =~ nextjs ]]; then
    if grep -q '"express"' package.json 2>/dev/null || \
       grep -q '"fastify"' package.json 2>/dev/null || \
       grep -q '"koa"' package.json 2>/dev/null || \
       grep -q '"hapi"' package.json 2>/dev/null || \
       grep -q '"nest"' package.json 2>/dev/null; then
        STACK="$STACK,nodejs"
    fi
fi

# Detect Expo
if [ -f "app.json" ] && grep -q "expo" app.json 2>/dev/null; then
    STACK="$STACK,expo"
fi

# Detect React Native (non-Expo)
if [ -d "android" ] || [ -d "ios" ]; then
    if [[ ! "$STACK" =~ expo ]]; then
        STACK="$STACK,reactnative"
    fi
fi

# Detect Python (Django, Flask, FastAPI)
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
    if [ -f "manage.py" ] || grep -q '"django"' requirements.txt 2>/dev/null; then
        STACK="$STACK,django"
    elif grep -q '"flask"' requirements.txt 2>/dev/null || grep -q '"Flask"' requirements.txt 2>/dev/null; then
        STACK="$STACK,flask"
    elif grep -q '"fastapi"' requirements.txt 2>/dev/null || grep -q '"uvicorn"' requirements.txt 2>/dev/null; then
        STACK="$STACK,fastapi"
    fi
fi

# Detect Ruby on Rails
if [ -f "Gemfile" ] && grep -q "'rails'" Gemfile 2>/dev/null; then
    STACK="$STACK,rails"
fi

# Detect Go
if [ -f "go.mod" ]; then
    STACK="$STACK,go"
fi

# Remove leading comma
STACK="${STACK#,}"

# Output the detected stack
if [ -z "$STACK" ]; then
    echo "common"
else
    echo "$STACK"
fi
