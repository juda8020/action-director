# Action Director 詳細ユーザーガイド

バージョン：v0.1 Alpha  
対象：Windows、macOS、Godot 4.7

## 1. このツールの目的

Action Director は、2D／3Dゲームアクションを完全オフラインで設計・比較するリハーサルツールです。既存のアニメーション、当たり判定、移動、戦闘ウィンドウ、ヒットストップ、カメラ、音、VFX、ゲームイベントを1本の固定60 tickタイムラインにまとめます。

アニメーションだけでは判断できない操作感を可視化し、デザインと実装の時刻ずれを防ぎ、Take A／Bを同じ条件で比較します。編集した `.action.json` は付属Godot Runtimeでも同じ順序で再生されます。

骨格アニメーション、スキニング、モデル修正、ダメージ計算、AI、状態機械の代替ではありません。Mixamo、Blenderなどで素材を用意し、本ツールで「ゲーム内でいつ何を起こすか」を設計します。

## 2. 適した用途と対象外

- 攻撃のstartup、active、recovery調整。
- 軽い／重い、速い／遅いTakeの比較。
- ダッシュ、空中攻撃、無敵、アーマー、キャンセルの設計。
- Mixamoキャラクターを使った3Dリハーサル。
- hit、block、miss、grounded、airborne、charge tier分岐。
- 確定タイミングのGodot 4.7ゲームへの受け渡し。

対象外：骨格・IK・モデル作成、異なる骨格間の自動retarget、ダメージ式、AI、ネットワーク同期、完全な会話／長編カットシーン制作。

## 3. 4つの基本概念

### ActionSpec

1つのアクションを表す正式仕様です。次元、Actor、Asset、Take、Track、Event、Marker、Branchを含みます。`.action.json` が正本で、`.action.tres` は再生成可能なGodotキャッシュです。

### Tick

正式時刻は常に毎秒60 ticksです。tick 20は開始から約0.333秒です。`start_tick`と`end_tick`は両方を含み、開始・終了が17ならtick 17で開いて同じtickで閉じます。

### Take

同じアクションの完全な別案です。複製時にTrack、Event、Marker、Branch、IDを独立コピーするため、Take Bの編集がTake Aへ影響しません。

### Track／Event

Trackは用途別にEventを整理します。Runtimeは見た目の推測ではなく、Eventのtickとpayloadを実行します。

## 4. 画面構成

- **上部ツールバー**：開く、復元、素材読込、保存、書出、Undo／Redo、tick移動、再生、リセット、A/B、チュートリアル、言語。
- **左パネル**：Action、Take、Actor、Asset。2D剣撃／3D突進サンプルも開けます。
- **中央ステージ**：現在Takeと比較Takeを同期表示します。
- **右Inspector**：選択EventのID、種類、開始／終了tick、Payload JSONを編集します。
- **下部Timeline**：全Track、Event範囲、ルーラー、再生位置を表示します。
- **Status bar**：成功、警告、復旧可能なエラー、現在tick／秒を表示します。

## 5. 最初のA/Bリハーサル

1. 初回チュートリアルを使うか、左の「2Dサンプルを開く」を選びます。
2. Spaceで再生します。左右が同じtick・入力条件で動きます。
3. ステージ上部の「最初の差分」を確認します。サンプルTake Bは早く攻撃し、遠く移動し、短く終了します。
4. Timelineのactive window、hitbox、motion Eventを選びます。
5. InspectorでtickまたはPayload JSONを変更し、「イベント変更を適用」します。不正JSON、または現在のActionSpecを無効にする変更は理由を表示し、以前のEventを保持したまま拒否します。
6. Ctrl/Cmd+ZでUndo、Ctrl/Cmd+Shift+Z（WindowsはCtrl+Yも可）でRedoします。
7. `.adproject`を保存し、正式な`.action.json`を書き出します。

最初は1つの関連パラメータだけを変更してください。速度、距離、後隙、演出を同時に変えると、感触が変化した原因を特定できません。

## 6. ファイル管理

- **`.adproject`**：編集用ワークスペース。プロジェクト情報、Asset索引、埋込ActionSpec復元コピーに加え、Primary Take、比較Take、A/B表示状態、Playhead tickを保持します。再度開くと同じレビュー位置へ戻ります。外部Asset読込前に保存してください。
- **`.action.json`**：Godot連携とGitレビューの正式ソース。生成`.tres`だけを正本にしないでください。
- **自動保存**：30秒ごとに埋込ActionSpec、Primary／比較Take、A/B表示状態、Playhead tickを含む復元Workspaceを保存します。異常終了後は「復元」で同じReview位置を再開します。最新の復元Workspaceが破損している場合は直前の有効な30秒Backupを自動で試し、その使用を明示します。破損Fileは書き換えません。確認後すぐ通常Pathへ保存・書出します。旧形式のActionSpecのみの復元Fileも読込可能です。

```text
my-action-project/
├── combat.adproject
├── actions/sword.action.json
└── assets/
    ├── hero.fbx
    ├── whoosh.ogg
    └── impact.webp
```

移動時はフォルダー全体を移動します。Asset消失時はTrackを削除せず再配置します。

## 7. 素材読込

PNG、WebP、WAV、OGG、GLB、glTF、FBXを読めます。保存済みプロジェクトへコピーし、相対パスで記録します。

- 最初の画像は2D Performer代理を置換します。
- audio Eventの`asset_key`をWAV／OGGのAsset keyへ合わせます。
- GLB／glTF／FBXではanimation Eventの`payload.clip`を検出Clip名へ合わせます。
- Clip名が違う場合、Alphaは最初のClipを見えるfallbackとして再生します。正式書出前に正しい名前へ直してください。

まず「**2Dスプライトデモ**」を開くと、付属のオリジナルCC0剣士8フレームが
animation Eventのtickで進みます。Take AとTake Bは同じCellを使いますが、DurationとSpeedが
異なるためキャラクターでも差を確認できます。ActionSpecの`frame_count`と`layout`は
再生に使われます。任意のspritesheetを設定する完全な分割UIはAlpha範囲外のため、JSONまたは
Godot側で最終設定を行います。

## 8. Mixamo FBX手順

左のサンプルから「**3D FBXデモ**」を開いてください。Mixamo FBXと同じ
Godot UFBX経路で、QuaterniusのCC0ヒューマノイド、Skeleton、Mesh、11個の
Animation Clipを読み込みます。AdobeはMixamo素材のプロジェクト利用は認めていますが、
生のCharacterやAnimationファイルの再配布は認めていません。そのため付属デモは
Mixamo素材ではありません。確認後、自分のAdobe IDでFBXを取得して置き換えます。

1. Mixamoでキャラクターとアニメーションを選びます。
2. Formatは **FBX Binary**。キャラクター込みなら **With Skin**。
3. 30 FPSのままで構いません。Action Eventは60 ticksで管理されます。
4. Action Directorで3Dサンプルを開き、`.adproject`を保存します。
5. 「素材を読込」からFBXを選びます。Godot 4.7 UFBXがSkeleton、Mesh、Animationを検出します。
6. Asset TooltipのClip名を確認し、animation Payloadへ設定します：

```json
{
  "clip": "mixamo.com",
  "speed": 1.0,
  "blend": 0.08,
  "reverse": false
}
```

7. 再生してClip、向き、Scale、実際の移動を確認します。

破損FBXは拒否されます。キャラクター＋アニメーションFBXは直接再生できますが、Motion-only FBXには互換Skeletonまたは外部retargetが必要です。異なるSkeleton間の自動retargetは未対応です。

## 9. 各Trackの役割

現在のAlpha GUIでは、種類を選んだTrack／Eventの追加・削除、再生ヘッドへのEvent追加、Take複製、Event type／actor／開始・終了tick／Payload JSONの変更ができます。Track名をクリックするとTrack全体を選択でき、Event／Track削除は元に戻せます。Marker／Branchは第10節のJSON手順で作成します。以下はActionSpec形式の説明も兼ねます。

- **Animation**：`clip`、`speed`、`blend`、`reverse`。映像長とゲームEvent長は別々に考えます。
- **Window**：すべて開始tickで汎用`event_fired`を1回発行します。`kind: "cancel"`だけが追加で`cancel_window_changed(tag, true/false)`の開閉を持ちます。他のWindowに専用Close signalはなく、必要ならHostが`end_tick`から終了をScheduleします。
- **Hitbox／Hurtbox**：Hitboxだけが`hitbox_opened/closed`を持ちます。Hurtboxは開始時の汎用`event_fired`のみで専用Close signalはありません。衝突、Hurtbox終了、Damageはゲームが管理します。
- **Motion**：2D `[x,y]`、3D `[x,y,z]`の`delta`と`local`／`world`の`space`を使います。
- **Feel**：hit stop、shake、slow motion、flashなどの時刻・強さを要求します。
- **Audio／VFX**：`asset_key`をGodot側のAudioStream／PackedSceneへ対応させます。
- **Camera**：追従、切替、Zoom/FOV、ShakeをCamera Adapterへ要求します。
- **Game event**：Projectile生成、Stamina消費など既存ゲームへの明示要求です。
- **Note**：レビュー用メモ。必須ゲームロジックには使用しません。

## 10. 高度なJSON編集とTake A/B

### GUI未対応のMarker／Branchを作る

1. 最も近い内蔵`.action.json`をCopyし、空Fileから始めないでください。
2. Track／EventはTimelineで作成します。Marker／Branchを追加・削除・編集するときだけFileを閉じてText editorを使います。
3. Take、Track、Event、Marker、Branchごとに一意IDを付け、`start_tick <= end_tick <= duration_ticks`を守ります。
4. 2D／3D座標を同じActionSpecへ混在させないでください。Loaderは、2D内の3要素Motion／shape vectorまたは`box`／`sphere`、3D内の2要素vectorまたは`rect`／`circle`を拒否します。`capsule`はどちらでも使えますが、vector要素数はDimensionに合わせます。Branch target markerは`at_tick`より後へ置きます。
5. JSONを保存し、Action Directorの「開く」で再読込します。重複UUID、破損JSON、不正範囲、後方Branchは拒否されます。
6. 読込後、GUIでTrack／Event作成、Event type／actor／tick／Payload調整、Take複製、A/Bリハーサル、書出を行います。

Alphaは外部File変更を監視しません。Text編集ごとにJSONを再度開いてください。`.adproject`の埋込復元Copyも外部JSON変更では自動更新されません。

### 比較方法

1. 正常に完走する基準Takeを作ります。
2. 「Take複製」で独立案を作ります。
3. Primary Takeタブを選び、「比較対象」から任意の別Takeを指定します。Takeが3つ以上でも次のタブだけに制限されません。
4. 「反応可能か」「命中が重く見えるか」など質問を1つ決めます。
5. 1回の比較では関連項目だけ変更します：startup／speed、motion／hitbox、hit stop／shake、recovery／cancel。
6. 同じ開始条件で再生し、最初の差分、総長、移動量、active、cancelを見ます。
7. 選ばなかったTakeもレビュー・巻戻し用に残します。

内蔵剣撃は方法例で、Balance推奨値ではありません。Take Aは72 ticks、Take Bは60 ticksで、Bは早く、遠く、強いshakeを持ち、block時にrecoveryへ分岐します。

## 11. 結果と分岐

2DのHitbox有効中に左クリックで`hit`、右クリックで`block`を報告します。閉じるまで報告がなければ、同じ終了tickの分岐を判定する前に`miss`になります。

```json
{
  "id": "on-block",
  "at_tick": 24,
  "condition": {"kind": "block", "value": true},
  "target_marker": "recovery"
}
```

条件は`hit`、`block`、`miss`、`grounded`、`airborne`、`charge_tier`、`custom_bool`。分岐先は後方Markerのみで、Loopや任意コードは不可です。飛ばされたHitboxとCancel windowはJump前に閉じられます。

## 12. 実際の応用例

- **軽攻撃**：速いstartup＋長いrecoveryと遅いstartup＋短いrecoveryを比較し、cancel windowをゲーム状態機械へ渡します。
- **3D肩突進**：Timeline toolbarでMotion／Hitboxを選び、再生ヘッドへEventを追加します。Motionで衝突Bodyを動かし、胸AnchorのBox hitbox、接触tickのhit stop／shakeを設定します。
- **チャージ攻撃**：JSONで`charge_tier` Branchと後続Markerを作り、Play contextへtierを渡します。
- **Boss防御反応**：JSONでhit／block／miss Branch構造を作り、各反応を設定します。AIとDamageはゲーム側に残します。

## 13. Godot 4.7へ導入

1. `.action.json`を書き出します。
2. `addons/action_director_runtime/`をゲームへコピーし、Project Settings → Pluginsで有効にします。
3. 読込・再生します：

```gdscript
var loaded := ActionSpecCodec.load_json("res://actions/sword.action.json")
if loaded.ok:
    $ActionDirectorPlayer.play(loaded.spec, "Take B", {
        "grounded": true,
        "charge_tier": 0
    })
```

`hitbox_opened`／`closed`、`motion_requested`、`cancel_window_changed`、`event_fired`を既存ゲームへ接続します。衝突確定後に`report_outcome(event_id, "hit")`または`"block"`を呼びます。

Runtimeはtick順序、Branch、Cleanupを管理します。Damage、Target、Collision結果、Input、State、AI、Networkはホストゲームが管理します。

Lifecycle APIは限定的です。Hitboxは`hitbox_opened/closed`、Cancel windowは`cancel_window_changed`を持ちます。Hurtboxと他Windowは開始時`event_fired`のみです。終了が必要ならHostで`end_tick`をScheduleするかRuntime Adapterを拡張してください。

## 14. Version controlとチーム運用

- `.action.json`をGitへCommitし、必要なら`.adproject`も共有します。
- Take名は`Fast Startup`、`Heavy Impact`のように目的を示します。
- Reviewにはstartup、active、recovery、総長、移動、hit stop、cancel差を記載します。
- 未知Eventは警告付きで保持されます。互換性確認前に削除しないでください。
- 重複UUID、破損JSON、後方Branchは拒否されます。Validatorを迂回せずSourceを修正します。

## 15. キーボード

| 操作 | キー |
|---|---|
| 再生／一時停止 | Space |
| 前／次tick | `,`／`.` |
| Reset | R |
| A/B切替 | C |
| Undo | Ctrl/Cmd+Z |
| Redo | Ctrl/Cmd+Shift+Z、WindowsはCtrl+Y |
| 保存 | Ctrl/Cmd+S |
| Timeline Track選択 | Timelineにフォーカス後、上下キー |
| Track内Event選択 | Timelineにフォーカス後、左右キー |
| Timeline Zoom | Ctrl/Cmd+Wheel |
| Seek | Ruler click |
| Tutorial scroll | Page Up/Down、Home、End |
| Tutorial close | Escape |

## 16. トラブル対処

- **素材を読めない**：先に`.adproject`を保存します。
- **FBXにAnimationがない**：FBX Binary、統合CharacterはWith Skinで再取得します。
- **Modelが動かない**：TooltipのClip名と`payload.clip`を完全一致させます。
- **Scale／向きが違う**：DCCまたはMixamo設定でSourceを修正します。
- **音が出ない**：WAV／OGGとEvent `asset_key`の対応を確認します。
- **Branchしない**：`at_tick`前に結果を報告し、Target Markerが後方か確認します。
- **元JSONを移動した**：`.adproject`の埋込ActionSpecを開き、再書出・Asset再配置します。
- **異常終了**：「復元」で30秒Workspace AutosaveのTakeペア、A/B状態、Playheadを再開します。最新Fileが破損している場合は直前の有効なBackupを自動で試します。その後、通常Pathへ保存・書出します。

## 17. Alphaの制限

GUIではTrack／Eventの追加・削除とEvent type／actor／tick／Payload変更ができます。Marker／Branchは`.action.json`の手動編集が必要です。専用開閉signalはHitboxとCancel windowだけで、Hurtboxと他Windowは開始時汎用Eventのみです。自動retarget、完全なspritesheet分割、参照Video、contact sheet、waveform、transform keyframeも未実装です。Bone、Skin、IK、Model、Damage、AI、State、Networkは制作・管理しません。macOS公開配布にはDeveloper ID署名とnotarizationが必要です。

同じActionSpecはEditorとGodot Runtimeで固定60 ticks、同じEvent順序、同じBranch／Cleanup規則により実行されます。
