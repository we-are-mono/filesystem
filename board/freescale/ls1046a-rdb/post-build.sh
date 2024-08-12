#!/bin/sh

# Make ZSH look pretty.
mkdir -p "$TARGET_DIR/root/.zsh"
git clone --depth 1 --branch v1.23.0 https://github.com/sindresorhus/pure.git "$TARGET_DIR/root/.zsh/pure"

