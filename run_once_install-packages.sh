#!/bin/bash
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
mise install
