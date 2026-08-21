# Action Director Design System

## Direction

Action Director extends the grammar of Godot's Modern editor instead of
inventing a marketing dashboard. The paired rehearsal stages are the focal
object; timing, selected state, and semantic differences remain visible around
them.

## Surfaces

- Base: near-black charcoal `#11151D` and editor panels `#151A23`.
- Separators: cool gray `#343B49`; use one-pixel structure without shadow.
- Focus/action: rehearsal green `#62D7A3`.
- Comparison/impact: amber `#F3B85B`.
- Error/hitbox: red `#FF5B68`.
- Track colors are semantic and stable: animation indigo, windows violet,
  hitbox red, hurtbox blue, motion green, feel amber, audio/VFX cyan, camera
  pink, neutral events gray.

## Typography and controls

Use Godot's platform workhorse font and native control metrics. Monospace is
reserved for JSON, ticks, IDs, and measurements. Buttons name actions and carry
tooltips with the associated shortcut. Keyboard focus uses a two-pixel green
outline and status text always accompanies color.

Interface strings are key-based and support English, Traditional Chinese,
Japanese, and Korean without changing technical IDs, clip names, JSON fields,
or tick measurements. Controls size to their translated labels and the locale
switcher remains visible in the transport bar.

## Layout

The desktop composition is fixed by job: project/material hierarchy left,
paired rehearsal center, current-event inspector right, transport above, and
multitrack timeline below. Panels may resize, but none become floating cards.
The transport uses two compact rows: persistent workspace identity above and
file/history/playback commands below. The rehearsal header keeps primary Take
tabs and an explicit comparison-Take selector above the difference summary so
longer localized labels do not compete with the stage width. Primary and
comparison stages retain
green and amber identities in both 2D and 3D, while the timeline names the
current selection before exposing contextual destructive actions. An empty
Inspector teaches the selection path instead of showing inactive edit fields.
Saving the workspace preserves the active Take pair, A/B visibility, and
playhead tick; reopening resumes that review state without changing ActionSpec.
The v0.1 Alpha desktop workspace supports widths of 1280 pixels and above.
Responsive inspector collapse is a public-release requirement, not an Alpha
claim.

## Motion

Playback is the authored motion. Interface animation is limited to the moving
playhead, hit-stop/impact overlays, and direct state feedback. Decorative entry
animations and ambient glow are excluded from the operating surface.

## Accessibility

All primary transport and file actions remain keyboard reachable. No state is
communicated by color alone. Secondary text maintains readable contrast, and
minimum hit targets follow the native Godot control sizes.

## Onboarding

First launch offers a skippable five-minute path to the product's core proof:
play two real takes, locate their first difference, edit one event, and save.
The same tutorial center remains available from the transport bar. Its chapters
use the current interface language, open real 2D/3D samples, remember completion
locally, and separate quick activation from deeper reference material.
The deeper layer is a searchable offline manual, opened from the tutorial
center. It uses long-form reading measure, persistent search, selectable text,
keyboard scrolling, and the current locale; quick steps stay out of the way of
reference depth.
