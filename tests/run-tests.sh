#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
GODOT_BIN=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
TEST_ROOT=$(mktemp -d /tmp/action-director-tests.XXXXXX)
TEST_PROJECT="$TEST_ROOT/project"
TASK_HOME="$TEST_ROOT/home"

cleanup() {
    rm -rf "$TEST_ROOT"
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM
mkdir -p "$TEST_PROJECT"
cp -R "$PROJECT_DIR/." "$TEST_PROJECT/"
rm -rf \
    "$TEST_PROJECT/.git" \
    "$TEST_PROJECT/.godot" \
    "$TEST_PROJECT/.godot-home" \
    "$TEST_PROJECT/.godot-home-export" \
    "$TEST_PROJECT/builds"
mkdir -p "$TASK_HOME/Library/Application Support/Godot"
(
    cd "$TEST_ROOT"
    HOME="$TASK_HOME" "$GODOT_BIN" --headless --editor --quit --path project
    HOME="$TASK_HOME" "$GODOT_BIN" --headless --path project --script res://tests/test_runner.gd
)
