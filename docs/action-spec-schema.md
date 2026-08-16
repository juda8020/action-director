# ActionSpec 1.0 contract

`*.action.json` is the source of truth. Generated `*.action.tres` files are
local Godot caches and can be recreated with `ActionSpecImporter`.

## Required root fields

| Field | Contract |
|---|---|
| `schema_version` | Semantic version. Runtime 0.1 supports major version 1. |
| `action_id` | Stable unique string for the action. |
| `dimension` | Exactly `2d` or `3d`; never mixed inside one action. |
| `tick_rate` | Exactly `60` for schema 1.x. |
| `takes` | One or more complete take objects. |

Each take declares its duration, forward markers, branches, and tracks. Each
event has a stable `id`, a supported or preserved `type`, inclusive start/end
ticks, an optional actor ID, and a type-owned `payload` dictionary.

## Supported event types

`animation`, `motion`, `hitbox`, `hurtbox`, `window`, `feel`, `audio`, `vfx`,
`camera`, `game_event`, and `note`.

An unknown event type produces a compatibility warning. Its full dictionary is
preserved during load/edit/export, but the runtime does not execute it.

## Graphical authoring defaults

The timeline toolbar can add or delete tracks and events. Adding an event uses
the selected compatible track, finds another compatible track, or creates one.
New events start at the current playhead and are clamped to the take duration.
Animation events default to a 30-tick span; audio, game-event, and note events
default to one tick; other supported events default to six inclusive ticks.
The first performer actor is selected when one exists. New 2D hitbox/hurtbox
events receive an editable `rect` payload, while 3D events receive an editable
`box` payload. These are safe starting values, not inferred gameplay intent.

Track/event creation, deletion, event type, actor, timing, and payload edits are
undoable in the editor. Marker and branch authoring remains a JSON workflow in
the Alpha.

## Branch rules

- Conditions: hit, block, miss, grounded, airborne, charge_tier, custom_bool.
- The target must be a marker later than the branch tick.
- A branch never executes arbitrary code.
- An unresolved hitbox automatically reports `miss` when the window closes.
- A `miss` branch may run on that same closing tick. Runtime closes the hitbox and
  records the fallback outcome before evaluating branches scheduled for the tick.

## Tick ranges

Start and end ticks are inclusive in files and editor visuals. Runtime opens
events scheduled for a tick, evaluates branches, then closes events whose
inclusive end is that tick. One-tick events therefore open and close during the
same tick. Branch skips and action completion explicitly close any active
windows. This ordering is deterministic across 30, 60, and 120 FPS.
