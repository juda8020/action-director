# Action Director

[Download the latest release](https://github.com/juda8020/action-director/releases/latest) ·
[Read the full introduction and tutorial](https://onemorerunguides.com/dev-tools/action-director/)

Action Director is a free, open-source, offline rehearsal desk for 2D and 3D
combat actions and short game sequences. It turns animation clips, hitboxes,
combat windows, motion, feel, camera, audio, VFX, and game-facing events into a
deterministic 60-tick `ActionSpec` that the included Godot addon can play.

This repository currently contains the **v0.1 Alpha vertical slice**. It proves
the complete path from action JSON to A/B rehearsal to deterministic Godot
runtime playback. Local macOS and Windows debug exports are supported; the
macOS package has not passed Apple notarization and is not a public release.

The Alpha graphical editor creates and deletes tracks and events, edits event
type, actor, timing, and payload, and duplicates complete takes. Marker and
branch authoring currently requires editing `.action.json` and reopening it.

Every project update is recorded in [CHANGELOG.md](CHANGELOG.md). Contribution
and update requirements are documented in [CONTRIBUTING.md](CONTRIBUTING.md).

## What works

- A real 2D eight-frame sword spritesheet demo and a real 3D skeletal FBX
  motion demo, both bundled with redistributable sample assets.
- A/B split rehearsal with an explicit comparison Take selector, frame
  stepping, locked playhead, and first-difference summary. Projects with three
  or more Takes can compare any pair instead of only adjacent versions.
- Complete take duplication with fresh take, track, event, branch, and marker
  IDs so variants remain independent and version-safe.
- Multitrack timeline authoring for animation, windows, hitboxes, hurtboxes,
  motion, feel, audio, VFX, camera, events, and notes. Add an event at the
  playhead, create a typed track, or delete selected structure with undo/redo.
- Event inspector for type, actor, timing, and payload editing with versionable
  JSON export.
- PNG, WebP, WAV, OGG, GLB, glTF, and Mixamo FBX asset ingestion into a local
  project. FBX uses Godot 4.7's built-in UFBX importer and records discovered
  skeletons, meshes, and animation clips.
- A bundled CC0 humanoid FBX with eleven clips gives the 3D sample a real,
  immediately playable Mixamo-compatible demonstration. It is not an Adobe or
  Mixamo asset; users replace it with FBX files downloaded under their own
  Adobe ID.
- English, Traditional Chinese, Japanese, and Korean interface languages with
  a device-local preference and English fallback.
- An in-app tutorial center in all four languages: first-run five-minute A/B
  rehearsal, timeline editing, Mixamo FBX, outcomes and branches, Godot addon
  handoff, troubleshooting, and keyboard reference. Chapters include real
  sample-opening actions and keep completion progress locally.
- A searchable, fully offline complete user guide in English, Traditional
  Chinese, Japanese, and Korean. It explains product purpose, interface,
  project files, every track category, Mixamo setup, A/B methodology, practical
  applications, Godot wiring, team workflow, and recovery—not only button use.
- Rehearsal binding: the bundled 2D demo slices declared spritesheet metadata
  into tick-driven frames; otherwise the first imported image replaces the 2D performer proxy;
  the first imported glTF, GLB, or Mixamo FBX replaces the 3D proxy and plays
  its animation using the timeline clip name (or the first available clip as a
  recoverable fallback); matching WAV or OGG events play during rehearsal.
- `.adproject` workspace save with safe replacement, recovery backup, and the
  active Take pair, A/B visibility, and playhead restored on reopen.
- Thirty-second action autosave and explicit recovery.
- `ActionSpec`, `ActionDirectorPlayer`, 2D/3D actor adapters, camera adapter,
  audio/VFX adapter, and JSON-to-TRES cache utility.
- Forward-only conditional branches and automatic miss fallback.
- No accounts, network requests, telemetry, or automatic updates.

## Run the editor

Godot 4.7 stable is required.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Open the sword or 3D charge sample from the left project panel. Space toggles
playback, comma/period step one tick, R resets, and C toggles A/B comparison.
Choose the primary Take tab, then use **Compare with** to select any other Take
for the synchronized stage and first-difference summary.
Click an event on the timeline to inspect or edit it.
Keyboard users can focus the timeline, move between tracks with Up/Down, and
select events in the active track with Left/Right. The visible focus outline
and selection summary remain available in every interface language.
Choose an event type in the timeline toolbar, then add it at the playhead. The
editor reuses a compatible selected track or creates one automatically. Click a
track label to select the whole track; Delete Event and Delete Track remain
fully undoable.
Save an `.adproject` before importing assets; this gives copied files a stable
project-relative home. The project embeds the current ActionSpec, so it can
reopen even if the original exported action file later moves. It also restores
the primary Take, comparison Take, A/B visibility, and playhead tick so a review
can continue from the same frame.

On first launch, the optional tutorial opens to a five-minute A/B rehearsal.
Experienced users can skip it. Choose **Tutorial** in the transport bar at any
time to reopen a chapter or review shortcuts; choose **Full guide** inside the
tutorial center for the searchable manual. Completion state never leaves the
device. The same manuals are included as Markdown files under `docs/`:

- `USER_GUIDE.en.md`
- `USER_GUIDE.zh_TW.md`
- `USER_GUIDE.ja.md`
- `USER_GUIDE.ko.md`

For Mixamo, download `FBX Binary` with `Skin` when importing a character and
motion together. Action Director preserves the original FBX, uses UFBX to read
it directly, and warns when the download contains no skeleton or animation. A
motion-only FBX may still be used as an animation source once a compatible
character/retarget workflow is added; automatic cross-skeleton retargeting is
not claimed in this Alpha.

## Run tests

```sh
./tests/run-tests.sh
```

Set `GODOT_BIN` when Godot is installed elsewhere. The test suite validates
both sample formats, schema failures, compatibility preservation,
deterministic event order at 30/60/120 FPS, exact event lifetimes, miss
fallback, branch cleanup, project round trips, independent take duplication,
semantic A/B comparison, and the `.tres` cache path.

## Build local packages

Install the Godot 4.7 export templates, then use the `macOS Alpha` and
`Windows Alpha` presets. Generated binaries live under `builds/`, which is
intentionally ignored by Git. These packages are for local Alpha testing;
public macOS distribution still requires Developer ID signing and Apple
notarization.

## Install the runtime addon

Copy `addons/action_director_runtime/` into a Godot 4.7 project and enable it
under Project Settings → Plugins. See the addon's README and
`docs/action-spec-schema.md` for the runtime contract.

## Alpha boundaries

The current importer safely copies supported assets and records relative asset
entries. Timeline tracks and events are graphically authorable, while marker
and branch structure still uses the documented JSON workflow. Mixamo FBX
skeleton/clip discovery and direct preview are included; automatic retargeting
between unrelated skeletons is not. Spritesheet slicing
controls, reference video, contact-sheet rendering, waveform display,
transform keyframes, production signing/notarization, and external usability
evidence remain release work. Bone/skin editing, damage, AI, networking, cloud
collaboration, and AI generation are deliberately outside the product.
Runtime provides paired lifecycle signals for hitboxes and cancel windows;
hurtboxes and other window kinds currently emit only a generic start event, so
the host must schedule their end tick when it needs a close lifecycle.

## License

MIT. Included sample visuals are synthetic primitives authored in code and may
be redistributed with the project.
