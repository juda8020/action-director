# Action Director

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Godot 4.7 desktop application with a GDScript Godot runtime addon. The first
binary targets Windows and macOS. The repository remains buildable on Linux for
contributors, but Linux is not a v0.1 release commitment.

## Users

Independent game developers and small combat-design teams who need to agree on
the timing and game-facing events of a 2D or 3D action before rebuilding it in
their production project.

## Product Purpose

Action Director turns existing animation, audio, and VFX assets into a
deterministic 60-tick action specification. A designer can compare two takes in
a playable rehearsal view, then hand the same specification to a Godot runtime
player instead of rewriting the timing by eye.

## Positioning

This is not an animation authoring package or a general cinematic timeline. It
is an offline action-rehearsal desk where animation clips, combat windows,
hitboxes, motion, feel, camera, and game events share one reviewable contract.

## Operating Context

- Import PNG, WebP, image sequences, WAV, OGG, GLB, glTF, or Mixamo FBX
  assets. Godot 4.7's built-in UFBX path reads skeletons and animation clips
  without requiring Blender.
- The 3D sample bundles a CC0 humanoid, skeleton, mesh, and eleven clips as a
  redistributable Mixamo-compatible demonstration. Raw Mixamo characters and
  animation files are never redistributed; users import files acquired under
  their own Adobe ID.
- The 2D sample bundles an original CC0 eight-frame sword spritesheet and
  advances its declared cells from the same fixed-tick timeline used by events.
- Rehearse a 2D or 3D action; a project never mixes coordinate dimensions.
- Compare any two complete Take copies with identical starting input, including
  non-adjacent versions in projects with three or more Takes.
- Reopen an `.adproject` at the saved primary Take, comparison Take, A/B
  visibility, and playhead tick instead of reconstructing the review state.
- Export `.action.json` as source of truth and optionally cache it as a Godot
  `.tres` resource through the runtime addon.
- Keep unpublished game assets local. The application has no account,
  telemetry, cloud synchronization, or automatic network update.

## Capabilities and Constraints

- Fixed 60 ticks per second; display may use frames or seconds.
- Forward-only branches using hit, block, miss, grounded, airborne,
  charge-tier, and custom boolean conditions.
- Existing animation clips may be trimmed, reversed, looped, blended, and
  retimed. Bone animation, skinning, IK, and model editing are out of scope.
- The Alpha graphical editor adds and deletes tracks and events, changes event
  type, actor, timing, and payload, and duplicates complete takes with undo and
  redo. Marker and branch authoring still requires manual `.action.json` edits.
- Runtime emits requests and events. Damage, collision results, character state
  machines, AI, and networking remain owned by the host game.
- Paired lifecycle signals exist for hitboxes and cancel windows. Hurtboxes and
  other window kinds currently emit only their generic start event; the host
  schedules their end when required.
- The interface supports English, Traditional Chinese, Japanese, and Korean.
  Locale selection stays on the device and falls back safely to English.
- Optional first-run onboarding targets a five-minute A/B success, while the
  replayable in-app tutorial center covers editing, Mixamo, branching, Godot
  handoff, recovery, and shortcuts with real sample actions.
- A searchable offline complete guide ships in all four interface languages and
  explains product purpose, files, track semantics, practical applications,
  Godot ownership boundaries, collaboration, and recovery.

## Evidence on Hand

No customer testimonials, usage benchmarks, or production adoption claims
exist yet. The repository includes redistributable 2D spritesheet and 3D FBX
motion demonstrations for workflow validation only.

## Product Principles

- A useful action must survive the trip from rehearsal to runtime unchanged.
- Timing and differences should be visible, not hidden in inspector fields.
- Project files stay readable, versionable, and recoverable.
- Familiar editor affordances outrank decorative novelty.
- Unknown data is preserved and reported instead of silently discarded.
- Every program update changes `CHANGELOG.md` in the same work unit; an
  unrecorded update is incomplete.

## Accessibility & Inclusion

Core playback, take switching, timeline navigation, save, and export operations
must be keyboard reachable. Status never relies on color alone, and interface
copy names both the problem and the recovery action.
