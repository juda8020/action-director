# Action Director Runtime Addon

Copy `addons/action_director_runtime/` into a Godot 4.7 project and enable it in
Project Settings → Plugins.

```gdscript
var loaded := ActionSpecCodec.load_json("res://actions/sword.action.json")
if loaded.ok:
    $ActionDirectorPlayer.play(loaded.spec, "Take B", {"grounded": true})
```

Connect `hitbox_opened` and `hitbox_closed` to the game's existing collision
system. Report the result with:

```gdscript
$ActionDirectorPlayer.report_outcome(event_id, "hit")
```

The runtime intentionally does not calculate damage, select targets, or own the
character state machine. See `docs/action-spec-schema.md` for the file contract.
