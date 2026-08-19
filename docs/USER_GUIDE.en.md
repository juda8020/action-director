# Action Director Complete User Guide

Version: v0.1 Alpha  
Platforms: Windows and macOS  
Integration target: Godot 4.7

## 1. What Action Director does

Action Director is a free, open-source, fully offline rehearsal desk for 2D and 3D game actions. It places animation clips, combat windows, hitboxes, movement, hit stop, camera requests, audio, VFX, notes, and game events on one deterministic 60-tick timeline.

It solves three common production problems:

1. An animation alone does not prove how an attack feels. Moving the hitbox four ticks earlier or adding two ticks of hit stop can change the result even when the source animation is unchanged.
2. Designers and gameplay code often drift to different timing. The editor and included Godot Runtime execute the same `.action.json` contract.
3. Iterations are difficult to judge from memory. Independent Take A and Take B versions can replay side by side with a first-difference summary.

Action Director does not create bone animation, skin characters, edit meshes, calculate damage, own AI, or replace the game's state machine. Prepare animation assets in Mixamo, Blender, or another DCC; use Action Director to decide how those assets become a playable action.

## 2. Appropriate uses

- Tune startup, active, and recovery timing for attacks.
- Compare fast/light and slow/heavy versions of an action.
- Stage dashes, jumps, knockback hints, armor, invulnerability, and cancel windows.
- Rehearse Mixamo characters and clips in a 3D stage.
- Preview hit, block, miss, airborne, grounded, or charge-tier branches.
- Hand approved timing to an existing Godot 4.7 game.
- Coordinate short camera, sound, VFX, and custom-event sequences.

Do not use it for bone animation authoring, model repair, automatic cross-skeleton retargeting, damage formulas, network synchronization, full dialogue systems, or long cinematic editing.

## 3. Core concepts

### ActionSpec

The complete portable specification for one action. It contains dimension, actors, assets, takes, tracks, events, markers, and branches. `.action.json` is the version-control-friendly source of truth. `.action.tres` is a regenerable Godot cache.

### Tick

Formal timing always uses 60 ticks per second. Tick 20 is approximately 0.333 seconds after the action begins. `start_tick` and `end_tick` are inclusive. An event whose start and end are both 17 opens and closes on tick 17.

### Take

A complete version of the same action. Take A might be deliberate and heavy; Take B might be faster and travel farther. Duplicating a take generates an independent copy of its tracks, events, markers, branches, and IDs.

### Track and event

A track groups events by purpose. Each event has stable identity, timing, an optional actor, and a type-specific payload. Runtime behavior is driven by events, not by visual assumptions about the animation.

## 4. Interface map

- **Top toolbar:** open, recover, import, save project, export action, undo/redo, tick stepping, play, reset, A/B, tutorial, language.
- **Left project panel:** actions, takes, actors, and imported assets; it also opens the built-in 2D and 3D samples.
- **Center rehearsal stage:** the current take and, when comparison is enabled, a synchronized second take.
- **Right Inspector:** the selected event's ID, type, start/end ticks, and Payload JSON.
- **Bottom timeline:** tracks, event ranges, ruler, current playhead, and semantic colors.
- **Status bar:** current tick and seconds, confirmations, compatibility warnings, and recoverable errors.

## 5. First rehearsal: compare the sword takes

1. Start the application. The optional first-run tutorial opens once; choose Tutorial later to reopen it.
2. Choose **Open 2D sample** in the left panel.
3. Press Space. Both stages play from the same tick and input context.
4. Read the first-difference summary above the stages. In the sample, Take B attacks earlier, lunges farther, and ends sooner.
5. Select an active window, hitbox, or motion event on the timeline.
6. Change its tick or Payload JSON in the Inspector and choose **Apply event changes**. Invalid JSON or an edit that would invalidate the current ActionSpec is explained and rejected without replacing the previous event.
7. Use Ctrl/Cmd+Z to undo and Ctrl/Cmd+Shift+Z (or Ctrl+Y on Windows) to redo.
8. Save an `.adproject`, then export an `.action.json`.

Change one related variable group at a time. A useful first experiment is moving Take B's hitbox start from tick 15 to 18. Changing speed, range, recovery, and impact simultaneously makes the cause of the difference difficult to identify.

## 6. Project and file management

### `.adproject`

The editable workspace. It contains project data, the asset index, and an embedded recovery copy of the current ActionSpec. Save it before importing external assets so copied files have a stable project-relative location.

### `.action.json`

The formal portable action. Commit this file to version control and treat it as the integration contract. Never make a generated `.tres` the only source.

### Autosave and recovery

The editor writes a recovery ActionSpec every 30 seconds. After an abnormal exit, choose Recover, inspect the content, and immediately save/export to normal project paths. Recovery is not a replacement for source control.

Recommended layout:

```text
my-action-project/
├── combat.adproject
├── actions/
│   ├── sword_light.action.json
│   └── sword_heavy.action.json
└── assets/
    ├── hero.fbx
    ├── sword_whoosh.ogg
    └── impact.webp
```

Move the whole project folder together. If an external asset is missing, relocate it; do not delete its tracks merely to hide a warning.

## 7. Importing assets

Supported inputs are PNG, WebP, WAV, OGG, GLB, glTF, and FBX. The importer copies the source into the project asset folder and records a relative path.

### 2D image and audio

1. Save the `.adproject`.
2. Choose Import asset and select an image or audio file.
3. The first imported image replaces the 2D performer proxy during rehearsal.
4. Match an audio event's `payload.asset_key` to the imported asset key.

Use **2D Sprite Demo** first to see the bundled original CC0 eight-frame sword
sheet advance from the animation event's fixed ticks. Take A and Take B use the
same cells but different durations and speed, so the comparison is visible in
the character frames as well as the data summary. The Alpha reads declared
`frame_count` and `layout` metadata from ActionSpec, but does not yet provide a
complete graphical slicing setup for arbitrary imported sheets; author that
metadata in JSON or construct the final animation resource in Godot.

### GLB and glTF

The 3D stage tries to play the clip named by an animation event's `payload.clip`. If it cannot find that name, the Alpha visibly falls back to the first available clip. The fallback prevents a silent stage, but the payload should be corrected before integration.

## 8. Complete Mixamo workflow

Start with **3D FBX Demo** in the left sample area. It loads a real CC0
humanoid by Quaternius with a skeleton, mesh, and eleven animation clips through
the same Godot UFBX path used for Mixamo FBX. The bundled file is deliberately
not a Mixamo asset: Adobe permits use in projects but does not permit an
open-source tool to redistribute the raw Mixamo character or animation files.
After confirming the demo, replace it with an FBX downloaded under your own
Adobe ID using the steps below.

### Download from Mixamo

1. Select a character and animation.
2. Choose **FBX Binary**.
3. Choose **With Skin** when character and animation should arrive together.
4. Leaving the source at 30 FPS is fine. Action events still use fixed 60-tick storage.

### Import and map the clip

1. Open the 3D sample and save an `.adproject`.
2. Choose Import asset and select the `.fbx`.
3. Godot 4.7 UFBX discovers the skeleton, meshes, and animation clips. A damaged or unparsable model is rejected and its failed copy is removed.
4. Read the detected clip names in the asset tooltip.
5. Set the animation event payload to that exact name:

```json
{
  "clip": "mixamo.com",
  "speed": 1.0,
  "blend": 0.08,
  "reverse": false
}
```

6. Rehearse and verify scale, facing, clip, and actual gameplay motion.

Character-plus-animation FBX can play directly. Motion-only FBX still needs a compatible skeleton or an external retarget workflow. Automatic cross-skeleton retargeting is not included in this Alpha. Fix incorrect source orientation or scale in a DCC tool or by downloading again with consistent settings.

## 9. Tracks and payloads

The Alpha graphical editor can create and delete typed tracks and events, add an event at the playhead, duplicate a complete take, and change an event's type, actor, start/end ticks, or Payload JSON. Select a track by clicking its label; event and track deletion are undoable. Marker and branch authoring still uses the advanced JSON workflow in section 10. The descriptions below are also an ActionSpec format reference.

### Animation

Select a clip and playback behavior. Common fields are `clip`, `speed`, `blend`, and `reverse`. Visual animation length does not automatically define gameplay timing.

### Window

Describe startup, active, recovery, cancel, armor, invulnerability, guard, or buffering windows. Every window produces one generic `event_fired` at its start tick. Only `kind: "cancel"` additionally provides paired `cancel_window_changed(tag, true/false)` lifecycle signals. Other windows currently have no dedicated close signal; a host that needs their end must schedule it from the ActionSpec `end_tick`. No window automatically mutates the host state machine.

### Hitbox and hurtbox

2D shapes can be rect, circle, or capsule. 3D shapes can be box, sphere, or capsule. Payloads identify anchor, offset, and size. A `hitbox` receives paired `hitbox_opened`/`hitbox_closed` signals. A `hurtbox` currently receives only generic `event_fired` at its start and has no dedicated close signal. The game owns overlap, team filtering, hurtbox lifecycle completion, damage, and outcome.

### Motion

`delta` is `[x, y]` in 2D or `[x, y, z]` in 3D. `space` is `local` or `world`. Keep visual root motion distinct from authoritative collision-body movement.

### Feel

Represent hit stop, camera shake, local speed, slow motion, or flash requests. The action specifies timing and intensity; the game owns accessibility reduction and final rendering.

### Audio and VFX

`asset_key` maps to a resource or PackedScene through the audio/VFX adapter. Keep preview and game mappings consistent.

### Camera

Emits camera requests for switching, tracking, zoom/FOV, freezing, or shake. It does not forcibly replace the game's camera controller.

### Game event and note

Use game events for named signals, tags, and parameters such as spawning a projectile or consuming stamina. Notes are review-only communication and should not carry required game logic.

## 10. Advanced JSON authoring and the A/B method

### Creating markers and branches the graphical editor does not yet support

1. Copy the closest built-in `.action.json` instead of starting with an empty file.
2. Create tracks and events in the timeline. Close the file and use a text editor only when adding, deleting, or editing markers and branches.
3. Give every take, track, event, marker, and branch a unique ID. Keep `start_tick <= end_tick <= duration_ticks`.
4. Never mix 2D and 3D coordinates in one ActionSpec. The loader rejects three-value Motion/shape vectors or `box`/`sphere` in 2D, and two-value vectors or `rect`/`circle` in 3D. `capsule` works in either dimension, but its vectors must still match. A branch target marker must be later than its `at_tick`.
5. Save the JSON and choose Open in Action Director to reload it. Duplicate UUIDs, damaged JSON, invalid ranges, and backward branches are rejected.
6. After it loads, use the graphical editor for track/event authoring, event type/actor/timing/payload refinement, take duplication, A/B rehearsal, and export.

The Alpha does not watch external file changes. Reopen the JSON after each text edit. If an `.adproject` already embeds the action, editing the external JSON does not automatically update that embedded recovery copy.

### Comparison method

1. Build one valid baseline take.
2. Duplicate it to create an independent version.
3. Write one comparison question: “Is this reactable?” or “Does impact feel heavy enough?”
4. Change one connected parameter group:
   - Responsiveness: startup and animation speed.
   - Reach: motion delta and hitbox position/size.
   - Impact: hit stop, shake, audio, and VFX timing.
   - Risk: recovery and cancel window.
5. Rehearse from the same start and input.
6. Inspect first difference, total duration, displacement, active timing, and cancellation—not only spectacle.
7. Preserve the alternative take for review and rollback.

The built-in sword action provides an example, not a balance recommendation. Take A lasts 72 ticks; Take B lasts 60, attacks earlier, lunges farther, shakes harder, and has a block branch to recovery.

## 11. Outcomes and forward branches

During an active 2D hitbox, left-click reports `hit` and right-click reports `block`. If no result arrives before the hitbox closes, Runtime reports `miss` before evaluating branches scheduled for that closing tick.

```json
{
  "id": "on-block",
  "at_tick": 24,
  "condition": {"kind": "block", "value": true},
  "target_marker": "recovery"
}
```

Allowed conditions are `hit`, `block`, `miss`, `grounded`, `airborne`, `charge_tier`, and `custom_bool`. A branch can only move to a later marker. It cannot loop or execute arbitrary code. Hitboxes and cancel windows skipped by a branch are closed before the jump.

## 12. Practical applications

### Light-attack risk

Compare a slower attack with short recovery against a fast attack with longer recovery. Hand the selected cancel-window timing to the game's state machine so the responsiveness tradeoff remains explicit.

### 3D shoulder charge

Import a Mixamo character, choose Motion or Hitbox in the timeline toolbar, and add events at the playhead. Drive authoritative motion with the motion track, configure a chest-anchored 3D box hitbox, and place hit stop and shake at contact. The host game creates or enables its Area3D when `hitbox_opened` fires.

### Charged attack

Create the `charge_tier` branch and later markers in JSON, then pass `charge_tier` in the play context. Branch to sections with different hitboxes, VFX, and recovery. The input system calculates charge; Action Director schedules the resulting path.

### Boss block response

Create the hit/block/miss branch structure in JSON. Use hit for ordinary recovery, block for a recoil path with longer vulnerability, and miss for the uninterrupted finish. The AI and damage systems remain outside ActionSpec.

## 13. Integrating with Godot 4.7

1. Export `.action.json`.
2. Copy `addons/action_director_runtime/` into the game.
3. Enable the plugin under Project Settings → Plugins.
4. Load and play:

```gdscript
var loaded := ActionSpecCodec.load_json("res://actions/sword.action.json")
if loaded.ok:
    $ActionDirectorPlayer.play(loaded.spec, "Take B", {
        "grounded": true,
        "charge_tier": 0
    })
```

5. Connect runtime signals:

```gdscript
func _ready() -> void:
    $ActionDirectorPlayer.hitbox_opened.connect(_on_hitbox_opened)
    $ActionDirectorPlayer.hitbox_closed.connect(_on_hitbox_closed)
    $ActionDirectorPlayer.motion_requested.connect(_on_motion_requested)
    $ActionDirectorPlayer.cancel_window_changed.connect(_on_cancel_window)
    $ActionDirectorPlayer.event_fired.connect(_on_action_event)

func _on_game_collision(event_id: String, blocked: bool) -> void:
    $ActionDirectorPlayer.report_outcome(
        event_id,
        "block" if blocked else "hit"
    )
```

Use `ActionActorAdapter2D` or `ActionActorAdapter3D`, `ActionCameraAdapter`, and `ActionAudioVfxAdapter` as appropriate. Runtime owns tick order, branches, and cleanup. The host game owns damage, collision decisions, input, character state, targets, AI, and networking.

Lifecycle support is intentionally specific: hitboxes have `hitbox_opened/closed`; cancel windows have `cancel_window_changed`; hurtboxes and other window kinds only receive start-time `event_fired`. Schedule their `end_tick` in the host or extend the Runtime Adapter when paired lifecycle is required.

## 14. Collaboration and version control

- Commit `.action.json`; share `.adproject` when the workspace and asset index are useful to the team.
- Name takes by intent, such as `Fast Startup` or `Heavy Impact`.
- In reviews, list changes to startup, active, recovery, total duration, displacement, hit stop, and cancel windows.
- Unknown event dictionaries are preserved with a compatibility warning. Do not delete them before confirming plugin compatibility.
- Duplicate UUIDs, damaged JSON, and backward branches are rejected. Fix the source rather than bypassing validation.

## 15. Keyboard reference

| Action | Shortcut |
|---|---|
| Play/pause | Space |
| Previous/next tick | `,` / `.` |
| Reset rehearsal | R |
| Toggle A/B | C |
| Undo | Ctrl/Cmd+Z |
| Redo | Ctrl/Cmd+Shift+Z; Ctrl+Y on Windows |
| Save project | Ctrl/Cmd+S |
| Select timeline track | Focus timeline, then Up/Down Arrow |
| Select event in track | Focus timeline, then Left/Right Arrow |
| Timeline zoom | Ctrl/Cmd+Mouse wheel |
| Seek | Click ruler |
| Inspect event | Click event |
| Select track | Click track label |
| Add event | Choose type, then **Add at playhead** |
| Delete selection | **Delete event**, **Delete track**, or Delete key |
| Scroll tutorial | Page Up/Down, Home, End |
| Close tutorial | Escape |

## 16. Troubleshooting

- **Import requires a save:** save an `.adproject` first so assets have a stable relative location.
- **FBX has no animation:** download Mixamo FBX Binary; choose With Skin for a combined character. Motion-only downloads require compatible retargeting.
- **3D model does not animate:** match `payload.clip` exactly to a detected clip in the asset tooltip.
- **Scale or facing is wrong:** correct the source transform in a DCC or redownload with consistent Mixamo settings.
- **Audio is silent:** verify WAV/OGG import and match the event `asset_key`.
- **Branch does not run:** report the result before `at_tick`, use a later target marker, and check condition/context values.
- **Original action moved:** open the `.adproject` embedded recovery copy, then export again and relocate external assets.
- **Abnormal exit:** choose Recover, inspect the 30-second autosave, then save it normally.

## 17. Alpha boundaries

The graphical editor now creates and deletes tracks and events and edits event type, actor, timing, and payload. Marker and branch authoring still requires manual `.action.json` editing. Dedicated paired lifecycle signals currently exist only for hitboxes and cancel windows; hurtboxes and other windows receive start-time generic events. The Alpha also does not include automatic cross-skeleton retargeting, a full spritesheet slicer, reference-video calibration, contact-sheet rendering, waveforms, or transform keyframes. It does not author bones, skinning, IK, or models and does not calculate damage, AI, state, or networking. Public macOS distribution still requires Developer ID signing and notarization.

These boundaries do not change the core contract: the same ActionSpec runs in rehearsal and Godot Runtime at fixed 60-tick timing with deterministic event order and branch cleanup.
