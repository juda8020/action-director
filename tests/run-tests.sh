#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
GODOT_BIN=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
TASK_HOME="$PROJECT_DIR/.godot-home"

mkdir -p "$TASK_HOME/Library/Application Support/Godot"
HOME="$TASK_HOME" "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/test_runner.gd
