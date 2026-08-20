class_name ActionTutorialCatalog
extends RefCounted

const CHAPTER_IDS := ["overview", "quick_start", "workspace", "timeline", "mixamo", "branching", "applications", "godot", "troubleshooting", "shortcuts"]

const CONTENT := {
	"en": {
		"overview": {"title": "What Action Director is for", "summary": "Understand the problem this tool solves, what it owns, and what remains in your game.", "time": "4 min", "action": "open_2d", "steps": [
			["Turn assets into a playable contract", "Action Director schedules existing animation, hitboxes, movement, combat windows, feel, camera, audio, VFX, and game events on one fixed 60-tick timeline."],
			["Judge gameplay, not animation alone", "The same clip can feel different when startup, reach, hit stop, recovery, or cancellation changes. Take A/B makes those choices visible and repeatable."],
			["Share the same timing", "The editor and Godot Runtime execute the same .action.json, reducing timing drift between design notes and gameplay code."],
			["Keep ownership clear", "This tool does not author bones, calculate damage, choose targets, run AI, or replace the game's state machine. It emits deterministic timing and requests."],
		]},
		"quick_start": {"title": "Five-minute A/B rehearsal", "summary": "Open a working action and see why two takes feel different.", "time": "5 min", "action": "open_2d", "steps": [
			["Open the 2D spritesheet demo", "The bundled original eight-frame sword fighter is sliced and advanced by timeline ticks, so Take A and Take B show a real frame-animation timing difference."],
			["Play both takes", "Press Space. The paired stages run Take A and Take B from the same tick and input context."],
			["Read the difference", "The line above the stages reports the first semantic difference and duration delta. Click that event in the timeline to inspect it."],
			["Edit one event", "Change start/end tick or Payload JSON in the right inspector, then choose Apply event changes. Invalid ActionSpec edits are explained and leave the previous event unchanged; use Undo for accepted edits."],
			["Save your result", "Save an .adproject for the workspace, then Export an .action.json as the version-controlled source of truth."],
		]},
		"timeline": {"title": "Timeline and combat timing", "summary": "Place animation, hitbox, movement, feel, audio, VFX, camera, and game events on fixed ticks.", "time": "8 min", "action": "open_2d", "steps": [
			["Author on the timeline", "Choose a type, then Add at playhead. The editor reuses a compatible selected track or creates one; Add track creates an empty lane."],
			["Navigate", "Click the ruler to seek. Focus the timeline, then use Up/Down to select tracks and Left/Right to select events. Comma and period step exact ticks."],
			["Read an event", "Each color has a stable meaning. The event begins at start_tick and remains active through end_tick, inclusively."],
			["Edit safely", "Select an event, edit its type, actor, timing, or JSON object, and apply. Delete event/track is undoable. Markers and branches still use .action.json."],
			["Compare takes", "Duplicate Take creates a full independent copy with new IDs. A/B comparison ignores those regenerated IDs and reports real timing or payload changes."],
		]},
		"workspace": {"title": "Projects, source files, and recovery", "summary": "Keep editable workspaces, portable action specs, and imported assets organized safely.", "time": "5 min", "action": "none", "steps": [
			["Save the workspace", ".adproject stores project data, the asset index, and an embedded ActionSpec recovery copy. Save it before importing assets so relative paths are stable."],
			["Export the source of truth", ".action.json is the portable, version-control-friendly contract. Generated .action.tres files are caches, never the only source."],
			["Keep the folder together", "Store the .adproject, actions, and assets under one project folder. Relocate missing assets instead of deleting their tracks."],
			["Recover deliberately", "Recover opens the 30-second autosave. Inspect it, then immediately save and export to normal paths; autosave does not replace Git."],
		]},
		"mixamo": {"title": "Import a Mixamo character", "summary": "Bring a skinned FBX directly into the 3D rehearsal stage with Godot UFBX.", "time": "6 min", "action": "open_3d", "steps": [
			["Try the bundled compatibility demo", "Open 3D FBX Demo to see a real CC0 humanoid, skeleton, mesh, and eleven animation clips playing through the same UFBX path. It is redistributable and is not a Mixamo asset."],
			["Download correctly", "In Mixamo choose FBX Binary. Use With Skin when the character and animation should arrive together; keep the default 30 FPS setting—the action timeline still stores 60 ticks."],
			["Save a project first", "Open the 3D sample and save the workspace as .adproject. Imported files must have a stable project-relative folder."],
			["Import the FBX", "Choose Import, select the .fbx, and wait for skeleton, mesh, and animation discovery. A damaged FBX is rejected and never added to the project."],
			["Match the clip", "Set the animation event payload clip to the detected clip name shown in the asset tooltip. If it does not match, rehearsal uses the first available clip as a visible fallback."],
			["Know the boundary", "Character-plus-animation FBX plays directly. Automatic retargeting between unrelated skeletons is not included in this Alpha."],
		]},
		"branching": {"title": "Hit, block, miss, and branches", "summary": "Preview the result-driven path without turning the timeline into a programming language.", "time": "7 min", "action": "open_2d", "steps": [
			["Create structure in JSON", "The Alpha can rehearse existing branches but cannot author them in the graphical interface. Add markers and forward branches in .action.json, then reopen it."],
			["Reach the active hitbox", "Play or step until the red hitbox is visible."],
			["Report a result", "Left-click the active hitbox for HIT; right-click for BLOCK. If no result arrives before it closes, runtime records MISS before evaluating branches on that closing tick."],
			["Follow the branch", "Branches execute only at their scheduled tick and move forward to a marker. The stage shows the branch ID and target marker."],
			["Check cleanup", "Skipped hitboxes and cancel windows close before the branch jumps, keeping the editor and Godot runtime in the same state."],
		]},
		"applications": {"title": "Applying the tool to real game work", "summary": "Use the same workflow for light attacks, 3D charges, charged actions, and boss reactions.", "time": "6 min", "action": "open_2d", "steps": [
			["Tune attack risk", "Compare faster startup with longer recovery, or safer recovery with slower startup. Send cancel-window changes to the host state machine."],
			["Build a 3D charge", "Drive authoritative movement with a motion track, open a chest-anchored box hitbox, and place hit stop and shake at contact."],
			["Stage charged actions", "Pass charge_tier in the play context and branch forward to different hitbox, VFX, and recovery sections."],
			["Handle boss outcomes", "Use hit, block, and miss paths for different reactions while damage and AI remain in the host game."],
			["Review one question at a time", "Choose the primary Take tab and any other version in Compare with, change one connected parameter group, then record the timing difference before choosing."],
		]},
		"godot": {"title": "Export and play in Godot", "summary": "Move the same ActionSpec from rehearsal into an existing Godot 4.7 game.", "time": "10 min", "action": "none", "steps": [
			["Export the source", "Export .action.json. Keep JSON as the source of truth; .tres is a generated cache."],
			["Install the addon", "Copy addons/action_director_runtime into the game project, then enable Action Director Runtime in Project Settings > Plugins."],
			["Import and connect", "Load the generated ActionSpec and add ActionDirectorPlayer. Connect actor, camera, and audio/VFX adapters to your existing character systems."],
			["Play", "Call player.play(action_spec, take_name, context). Report collision results with report_outcome and request a cancel with request_cancel."],
			["Keep ownership clear", "The runtime emits timing and requests. Your game still owns damage, collision decisions, state machines, AI, and networking."],
			["Use the actual lifecycle API", "Hitboxes have opened/closed signals and cancel windows have cancel_window_changed. Hurtboxes and other windows only emit event_fired at start; schedule their end_tick in the host if needed."],
		]},
		"troubleshooting": {"title": "Import and recovery troubleshooting", "summary": "Fix the failures most likely to interrupt a first project.", "time": "4 min", "action": "none", "steps": [
			["Import asks you to save", "Save an .adproject first. This gives assets a stable relative directory."],
			["FBX has no animation", "Download again from Mixamo as FBX Binary. For a combined character, use With Skin. Motion-only files need a compatible retarget workflow."],
			["Model is too large or rotated", "This Alpha preserves imported transforms. Correct source scale/orientation in the DCC or use Mixamo defaults before import."],
			["Original action moved", "Open the .adproject; it contains an embedded ActionSpec recovery copy. Relocate external assets instead of deleting their tracks."],
			["Crash recovery", "Choose Recover to open the 30-second autosave, then immediately save/export it to a normal project path."],
		]},
		"shortcuts": {"title": "Keyboard reference", "summary": "Operate the core rehearsal loop without leaving the keyboard.", "time": "1 min", "action": "none", "steps": [
			["Playback", "Space: play/pause · Comma: previous tick · Period: next tick · R: reset · C: A/B on/off"],
			["Editing", "Ctrl/Cmd+Z: undo · Ctrl/Cmd+Shift+Z or Ctrl+Y: redo · Ctrl/Cmd+S: save project"],
			["Timeline", "Focus timeline · Up/Down: select track · Left/Right: select event · Ctrl/Cmd+wheel: zoom · click ruler: seek · Delete: remove selection"],
		]},
	},
	"zh_TW": {
		"overview": {"title": "動作導演台的用途", "summary": "先理解它解決什麼問題、負責哪些時序，以及哪些工作仍由遊戲掌管。", "time": "4 分鐘", "action": "open_2d", "steps": [
			["把素材變成可執行契約", "動作導演台把既有動畫、攻擊框、位移、戰鬥窗口、手感、鏡頭、音效、VFX 與遊戲事件排在固定 60 ticks 時間軸。"],
			["判斷遊戲手感，而非只看動畫", "同一片段只要前搖、距離、hit stop、後搖或取消不同，手感就會改變；Take A/B 讓差異可見且可重播。"],
			["讓策劃與程式共用時序", "編輯器與 Godot Runtime 執行同一份 .action.json，減少設計筆記和實際程式各用一套時間的問題。"],
			["清楚分工", "本工具不製作骨架、不計算傷害、不選目標、不控制 AI，也不取代狀態機；它負責確定性的事件時間與請求。"],
		]},
		"quick_start": {"title": "五分鐘完成 A/B 試打", "summary": "開啟可直接操作的動作，親眼看見兩個 Take 的手感差異。", "time": "5 分鐘", "action": "open_2d", "steps": [
			["開啟 2D 逐格動作範例", "內附原創 8 格劍士動作，會依時間軸 tick 切格播放，因此 Take A 與 Take B 會真實呈現逐格動畫的時序差異。"],
			["同時播放兩個 Take", "按 Space。左右舞台會以相同 tick 與輸入條件播放 Take A、Take B。"],
			["閱讀差異", "舞台上方會顯示首次語意差異與長度差。到時間軸點選該事件，即可在右側檢查。"],
			["修改一個事件", "在 Inspector 改開始／結束 tick 或 Payload JSON，再按「套用事件修改」。若修改會使 ActionSpec 無效，程式會說明原因並保留原事件；已接受的修改仍可復原。"],
			["保存成果", "先儲存 .adproject 工作區，再匯出 .action.json 作為版本控制的正式來源。"],
		]},
		"timeline": {"title": "時間軸與戰鬥時序", "summary": "用固定 tick 編排動畫、攻擊框、位移、手感、音效、VFX、鏡頭與遊戲事件。", "time": "8 分鐘", "action": "open_2d", "steps": [
			["直接在時間軸編排", "先選事件類型，再按「加到播放頭」。程式會沿用相容軌道，沒有時自動建立；「新增軌道」可建立空白軌道。"],
			["精確定位", "點時間尺跳轉；聚焦時間軸後用上／下選軌道、左／右選事件；逗號與句點逐 tick 移動。"],
			["閱讀事件", "每種顏色代表固定語意。事件從 start_tick 開始，包含 end_tick 在內都維持有效。"],
			["安全修改", "選事件後可改類型、演員、時間或 JSON；事件與軌道刪除都能復原。Marker 與 branch 目前仍使用 .action.json。"],
			["比較 Take", "「複製 Take」會建立完整獨立副本與新 ID；A/B 比較忽略重建 ID，只回報真正的時序或 payload 差異。"],
		]},
		"workspace": {"title": "專案、正式檔案與復原", "summary": "正確管理工作區、ActionSpec、外部素材與異常復原。", "time": "5 分鐘", "action": "none", "steps": [
			["保存工作區", ".adproject 保存專案資料、素材索引與內嵌 ActionSpec 復原副本。匯入素材前先儲存，才能建立穩定相對路徑。"],
			["匯出正式來源", ".action.json 是可攜、適合版本控制的正式契約；.action.tres 是可重建快取，不能作為唯一來源。"],
			["整個資料夾一起管理", "把 .adproject、actions 與 assets 放在同一專案資料夾；素材遺失時重新定位，不要刪除軌道。"],
			["正確使用復原", "「復原」會開啟每 30 秒自動存檔。確認內容後立刻保存並匯出到正常路徑；自動存檔不能取代 Git。"],
		]},
		"mixamo": {"title": "匯入 Mixamo 角色", "summary": "透過 Godot UFBX，把帶骨架的 FBX 直接放進 3D 預演舞台。", "time": "6 分鐘", "action": "open_3d", "steps": [
			["先試內附相容範例", "開啟「3D FBX 範例」，即可看到真實 CC0 雙足角色、骨架、網格與 11 段動畫透過同一條 UFBX 路徑播放。它可合法再散布，不是 Mixamo 素材。"],
			["正確下載", "在 Mixamo 選 FBX Binary。角色與動畫一起下載時選 With Skin；維持 30 FPS 即可，動作時間軸仍以 60 ticks 儲存。"],
			["先儲存專案", "開啟 3D 範例並存成 .adproject，讓匯入檔案有穩定的專案相對資料夾。"],
			["匯入 FBX", "按「匯入素材」選擇 .fbx，等待骨架、網格與動畫片段辨識。毀損 FBX 會被拒絕，不會加入專案。"],
			["對應動畫片段", "把動畫事件 payload 的 clip 設成素材 Tooltip 顯示的片段名稱；名稱不同時，預演會以第一段動畫作為可見 fallback。"],
			["了解邊界", "角色加動畫的 FBX 可直接播放；Alpha 尚不會在不同骨架之間自動 retarget。"],
		]},
		"branching": {"title": "命中、格擋、落空與分支", "summary": "預演結果導向的路徑，但不把時間軸變成任意程式語言。", "time": "7 分鐘", "action": "open_2d", "steps": [
			["先在 JSON 建立結構", "Alpha 能試打既有分支，但圖形介面還不能建立。請在 .action.json 新增 marker 與向後續前進的 branch，再重新開啟。"],
			["走到有效攻擊框", "播放或逐格移動，直到紅色攻擊框出現。"],
			["回報結果", "在有效攻擊框按左鍵回報命中、右鍵回報格擋；關閉前沒有結果時，Runtime 會先自動記為落空，再判斷同一 tick 的分支。"],
			["觀察分支", "分支只在排定 tick 執行，並向後續標記前進；舞台會顯示分支 ID 與目標標記。"],
			["確認清理", "被跳過的攻擊框與取消窗口會在跳轉前關閉，確保編輯器與 Godot Runtime 狀態一致。"],
		]},
		"applications": {"title": "如何應用到實際遊戲", "summary": "把同一套流程用在輕攻擊、3D 衝撞、蓄力技能與 Boss 反應。", "time": "6 分鐘", "action": "open_2d", "steps": [
			["調整攻擊風險", "比較快速前搖配長後搖，或慢前搖配安全恢復；再把取消窗口交給遊戲狀態機執行。"],
			["製作 3D 衝撞", "用 motion 軌道推進真正角色位置，在胸口錨點開啟 box hitbox，並在接觸 tick 放 hit stop 與震動。"],
			["製作蓄力技能", "從 play context 傳入 charge_tier，向後分支到不同攻擊框、VFX 與後搖區段。"],
			["設計 Boss 結果反應", "讓 hit、block、miss 走不同演出路徑，但傷害與 AI 仍留在遊戲端。"],
			["一次回答一個問題", "先選主要 Take 分頁，再從「比較對象」指定任一其他版本；只改一組相關參數，重播並記錄時序差異後再選版本。"],
		]},
		"godot": {"title": "匯出並在 Godot 播放", "summary": "把預演用的同一份 ActionSpec 接到既有 Godot 4.7 遊戲。", "time": "10 分鐘", "action": "none", "steps": [
			["匯出來源", "匯出 .action.json。JSON 是正式來源，.tres 只是可重新產生的快取。"],
			["安裝 Addon", "把 addons/action_director_runtime 複製進遊戲專案，再到 Project Settings > Plugins 啟用。"],
			["匯入並接線", "載入 ActionSpec，加入 ActionDirectorPlayer，並用 Actor、Camera、Audio/VFX Adapter 接到既有角色系統。"],
			["播放", "呼叫 player.play(action_spec, take_name, context)；碰撞結果用 report_outcome，取消則用 request_cancel。"],
			["維持責任邊界", "Runtime 只發出時間事件與請求；傷害、碰撞判定、狀態機、AI、連線仍由遊戲掌管。"],
			["依實際生命週期 API 接線", "hitbox 有 opened/closed，cancel window 有 cancel_window_changed；hurtbox 與其他 window 只有開始時 event_fired，需要結束時請由遊戲依 end_tick 排程。"],
		]},
		"troubleshooting": {"title": "匯入與復原疑難排解", "summary": "處理最容易中斷第一個專案的問題。", "time": "4 分鐘", "action": "none", "steps": [
			["匯入前要求儲存", "先儲存 .adproject，素材才能放進穩定的相對路徑。"],
			["FBX 沒有動畫", "從 Mixamo 重新下載 FBX Binary；合併角色請選 With Skin。只有動作的 FBX 需要相容骨架／retarget 流程。"],
			["模型太大或方向錯誤", "Alpha 會保留匯入 Transform；請在 DCC 修正尺度與方向，或以 Mixamo 預設重新下載。"],
			["原始動作被移動", "直接開啟 .adproject，它內嵌 ActionSpec 復原副本；遺失外部素材時重新定位，不要刪除軌道。"],
			["崩潰復原", "按「復原」開啟每 30 秒自動存檔，接著立刻存到正常專案路徑。"],
		]},
		"shortcuts": {"title": "鍵盤快捷鍵", "summary": "不離開鍵盤完成核心預演循環。", "time": "1 分鐘", "action": "none", "steps": [
			["播放", "Space：播放／暫停 · 逗號：前一 tick · 句點：下一 tick · R：重設 · C：A/B 開關"],
			["編輯", "Ctrl/Cmd+Z：復原 · Ctrl/Cmd+Shift+Z 或 Ctrl+Y：重做 · Ctrl/Cmd+S：儲存專案"],
			["時間軸", "聚焦時間軸 · 上／下：選軌道 · 左／右：選事件 · Ctrl/Cmd+滾輪：縮放 · 點時間尺：跳轉 · Delete：刪除選取項目"],
		]},
	},
	"ja": {
		"overview": {"title": "Action Directorの目的", "summary": "解決する問題、担当する時刻、ゲーム側に残す責任を理解します。", "time": "4分", "action": "open_2d", "steps": [
			["素材を実行契約へ", "既存Animation、Hitbox、Motion、Window、Feel、Camera、Audio、VFX、Game eventを固定60 tickへ配置します。"],
			["Animationだけで判断しない", "同じClipでもstartup、距離、hit stop、recovery、cancelで操作感が変わり、Take A/Bで再現可能に比較できます。"],
			["同じ時刻を共有", "EditorとGodot Runtimeが同じ.action.jsonを実行し、設計資料とコードの時刻ずれを減らします。"],
			["責任を分離", "Bone制作、Damage、Target、AI、State machineは担当せず、確定的な時刻と要求だけを発行します。"],
		]},
		"quick_start": {"title": "5分でA/Bリハーサル", "summary": "実動サンプルで2つのTakeの感触が違う理由を確認します。", "time": "5分", "action": "open_2d", "steps": [
			["2Dスプライトデモを開く", "付属のオリジナル8フレーム剣士をTimeline tickで切り替え、Take AとTake Bのフレームアニメ時間差を実際に確認できます。"],
			["2つのTakeを再生", "Spaceを押すと、左右のステージが同じtickと入力条件でTake A/Bを再生します。"],
			["差分を読む", "ステージ上部に最初の意味的差分と長さの差が表示されます。タイムラインでイベントを選び、右側で確認します。"],
			["イベントを編集", "開始／終了tickまたはPayload JSONを変更し、「イベント変更を適用」を押します。ActionSpecが無効になる変更は理由を表示して元のEventを保持し、適用済みの変更は元に戻せます。"],
			["結果を保存", ".adprojectでワークスペースを保存し、バージョン管理用の.action.jsonを書き出します。"],
		]},
		"timeline": {"title": "タイムラインと戦闘タイミング", "summary": "固定tickでアニメーション、当たり判定、移動、演出、音、VFX、カメラ、ゲームイベントを配置します。", "time": "8分", "action": "open_2d", "steps": [
			["タイムラインで作成", "種類を選び「再生ヘッドに追加」を押します。互換トラックを再利用し、なければ自動作成します。空トラックも追加できます。"],
			["正確に移動", "ルーラーをクリックします。タイムラインにフォーカス後、上下でトラック、左右でイベントを選び、カンマ／ピリオドで1tickずつ移動します。"],
			["イベントを読む", "色は固定の意味を持ちます。イベントはstart_tickからend_tickを含む範囲で有効です。"],
			["安全に編集", "Eventの種類、Actor、時間、JSONを編集できます。Event／Track削除は元に戻せます。Marker／Branchはまだ.action.jsonを使います。"],
			["Takeを比較", "Take複製は新しいIDの完全コピーを作ります。A/B比較はIDの違いを無視し、実際の時間・payload差分を示します。"],
		]},
		"workspace": {"title": "Project、正式Source、復元", "summary": "Workspace、ActionSpec、外部Asset、異常終了の復元を安全に管理します。", "time": "5分", "action": "none", "steps": [
			["Workspaceを保存", ".adprojectはProject情報、Asset索引、埋込ActionSpecを保存します。Asset読込前に保存して相対Pathを安定させます。"],
			["正式Sourceを書出", ".action.jsonがVersion control用の正本で、.action.tresは再生成可能なCacheです。"],
			["Folderごと管理", ".adproject、actions、assetsを同じProject folderへ置き、Missing AssetはTrackを消さず再配置します。"],
			["復元を確定保存", "復元は30秒Autosaveを開きます。内容確認後すぐ通常Pathへ保存・書出し、Gitの代用にはしません。"],
		]},
		"mixamo": {"title": "Mixamoキャラクターを読み込む", "summary": "Godot UFBXでスキン付きFBXを3Dリハーサルへ直接読み込みます。", "time": "6分", "action": "open_3d", "steps": [
			["付属互換デモを試す", "「3D FBXデモ」で、実際のCC0ヒューマノイド、Skeleton、Mesh、11個のAnimation Clipを同じUFBX経路で確認できます。再配布可能であり、Mixamo素材ではありません。"],
			["正しくダウンロード", "MixamoでFBX Binaryを選びます。キャラクター込みならWith Skinを使用します。30 FPSのままで構いません。"],
			["先にプロジェクトを保存", "3Dサンプルを開き、.adprojectとして保存して相対素材フォルダーを確定します。"],
			["FBXを読み込む", "「素材を読込」で.fbxを選びます。骨格、メッシュ、アニメーションを検出し、破損ファイルは追加せず拒否します。"],
			["クリップを合わせる", "素材ツールチップのクリップ名をanimationイベントのpayload.clipに設定します。不一致時は最初のクリップをフォールバック再生します。"],
			["制限を理解", "キャラクター＋アニメーションFBXは直接再生できます。異なる骨格間の自動リターゲットはAlpha範囲外です。"],
		]},
		"branching": {"title": "ヒット、ガード、ミス、分岐", "summary": "任意コードを使わず、結果による経路をリハーサルします。", "time": "7分", "action": "open_2d", "steps": [
			["JSONで構造を作る", "Alphaは既存Branchを再生できますがGUI作成は未対応です。.action.jsonへMarker／前進Branchを追加して再読込します。"],
			["有効なヒットボックスへ", "赤いヒットボックスが出るまで再生またはコマ送りします。"],
			["結果を報告", "左クリックでHIT、右クリックでBLOCK。閉じるまで報告がなければ、同じtickの分岐判定前にMISSになります。"],
			["分岐を追う", "分岐は予定tickでのみ実行され、後方のマーカーへ進みます。ステージに分岐IDと対象が表示されます。"],
			["クリーンアップ確認", "飛ばされるヒットボックスとキャンセル窓は移動前に閉じ、エディターとRuntimeの状態を一致させます。"],
		]},
		"applications": {"title": "実際のゲームへの応用", "summary": "軽攻撃、3D突進、Charge、Boss反応へ同じWorkflowを使います。", "time": "6分", "action": "open_2d", "steps": [
			["攻撃Riskを調整", "速いstartup＋長いrecovery等を比較し、cancel windowをHost state machineへ渡します。"],
			["3D突進を作る", "Motionで実Bodyを動かし、胸AnchorのBox hitboxと接触時hit stop／shakeを配置します。"],
			["Chargeを分岐", "Play contextのcharge_tierから異なるHitbox、VFX、Recovery区間へ前進分岐します。"],
			["Boss結果を演出", "hit、block、missを別経路へ送り、DamageとAIはHost gameに残します。"],
			["質問を1つずつ検証", "Primary Takeタブと「比較対象」で任意の別Takeを選び、関連Parameter群だけ変えて時刻差を記録します。"],
		]},
		"godot": {"title": "Godotへ書き出して再生", "summary": "同じActionSpecを既存のGodot 4.7ゲームへ接続します。", "time": "10分", "action": "none", "steps": [
			["ソースを書き出す", ".action.jsonを書き出します。JSONが正本で、.tresは再生成可能なキャッシュです。"],
			["Addonを導入", "addons/action_director_runtimeをゲームへコピーし、Project Settings > Pluginsで有効にします。"],
			["接続", "ActionSpecを読み、ActionDirectorPlayerとActor／Camera／AudioVFX Adapterを既存システムへ接続します。"],
			["再生", "player.play(action_spec, take_name, context)を呼び、衝突結果はreport_outcome、キャンセルはrequest_cancelで報告します。"],
			["責任を分離", "Runtimeは時刻と要求だけを発行し、ダメージ、衝突判定、状態機械、AI、通信はゲーム側が管理します。"],
			["実際のLifecycle API", "Hitboxはopened/closed、Cancel windowはcancel_window_changed。Hurtboxと他Windowは開始時event_firedのみで、終了はHostがend_tickから処理します。"],
		]},
		"troubleshooting": {"title": "読込と復元のトラブル対処", "summary": "最初のプロジェクトを止めやすい問題を解決します。", "time": "4分", "action": "none", "steps": [
			["読込前に保存を求められる", "先に.adprojectを保存し、素材の安定した相対パスを作ります。"],
			["FBXにアニメーションがない", "MixamoからFBX Binaryで再取得し、統合キャラクターはWith Skinにします。モーションのみは互換骨格が必要です。"],
			["サイズや向きが違う", "Alphaは読込Transformを保持します。DCCで修正するかMixamo既定値で再取得してください。"],
			["元アクションを移動した", ".adprojectにはActionSpec復元コピーがあります。外部素材はトラックを消さず再配置します。"],
			["クラッシュ復元", "「復元」で30秒自動保存を開き、すぐ通常のプロジェクトパスへ保存／書き出します。"],
		]},
		"shortcuts": {"title": "キーボード操作", "summary": "キーボードだけで中心的なリハーサルを行います。", "time": "1分", "action": "none", "steps": [
			["再生", "Space：再生／一時停止 · ,：前tick · .：次tick · R：リセット · C：A/B切替"],
			["編集", "Ctrl/Cmd+Z：元に戻す · Ctrl/Cmd+Shift+ZまたはCtrl+Y：やり直す · Ctrl/Cmd+S：保存"],
			["タイムライン", "フォーカス · 上下：トラック選択 · 左右：イベント選択 · Ctrl/Cmd+ホイール：ズーム · ルーラー：シーク · Delete：選択を削除"],
		]},
	},
	"ko": {
		"overview": {"title": "Action Director의 역할", "summary": "해결하는 문제와 담당 범위, 게임에 남겨야 할 책임을 이해합니다.", "time": "4분", "action": "open_2d", "steps": [
			["에셋을 실행 계약으로", "기존 animation, hitbox, motion, window, feel, camera, audio, VFX, game event를 고정 60 tick 타임라인에 둡니다."],
			["애니메이션만 보지 않기", "같은 clip도 startup, 거리, hit stop, recovery, cancel에 따라 감각이 달라지며 Take A/B로 반복 비교할 수 있습니다."],
			["같은 타이밍 공유", "편집기와 Godot Runtime이 같은 .action.json을 실행해 설계 문서와 코드 사이의 차이를 줄입니다."],
			["책임 분리", "bone 제작, 피해, target, AI, state machine은 담당하지 않고 결정적인 시간과 요청을 발행합니다."],
		]},
		"quick_start": {"title": "5분 A/B 리허설", "summary": "실제 샘플을 열어 두 Take의 감각이 다른 이유를 확인합니다.", "time": "5분", "action": "open_2d", "steps": [
			["2D 스프라이트 데모 열기", "내장 오리지널 8프레임 검사가 타임라인 tick에 따라 전환되어 Take A와 Take B의 실제 프레임 애니메이션 타이밍 차이를 보여 줍니다."],
			["두 Take 재생", "Space를 누르면 좌우 무대가 같은 tick과 입력 조건으로 Take A/B를 재생합니다."],
			["차이 읽기", "무대 위에 최초 의미 차이와 길이 차이가 표시됩니다. 타임라인 이벤트를 눌러 오른쪽에서 확인합니다."],
			["이벤트 수정", "시작/종료 tick 또는 Payload JSON을 수정하고 ‘이벤트 변경 적용’을 누릅니다. ActionSpec을 무효로 만드는 수정은 이유를 표시하고 기존 이벤트를 유지하며, 적용된 수정은 실행 취소할 수 있습니다."],
			["결과 저장", ".adproject로 작업공간을 저장한 뒤 버전 관리용 .action.json을 내보냅니다."],
		]},
		"timeline": {"title": "타임라인과 전투 타이밍", "summary": "고정 tick에 애니메이션, 히트박스, 이동, 연출, 오디오, VFX, 카메라, 게임 이벤트를 배치합니다.", "time": "8분", "action": "open_2d", "steps": [
			["타임라인에서 작성", "유형을 선택하고 ‘재생 헤드에 추가’를 누릅니다. 호환 트랙을 재사용하고 없으면 자동 생성하며 빈 트랙도 추가할 수 있습니다."],
			["정확히 이동", "눈금자를 클릭합니다. 타임라인에 포커스를 둔 뒤 위/아래로 트랙, 왼쪽/오른쪽으로 이벤트를 선택하고 쉼표/마침표로 1 tick씩 이동합니다."],
			["이벤트 읽기", "색상은 고정 의미를 가집니다. 이벤트는 start_tick부터 end_tick을 포함해 활성화됩니다."],
			["안전하게 수정", "이벤트 유형, 액터, 시간, JSON을 수정할 수 있고 이벤트/트랙 삭제는 실행 취소됩니다. Marker/Branch는 아직 .action.json을 사용합니다."],
			["Take 비교", "Take 복제는 새 ID의 완전한 복사본을 만듭니다. A/B는 ID 차이를 무시하고 실제 시간/payload 차이만 보여줍니다."],
		]},
		"workspace": {"title": "프로젝트, 공식 원본, 복구", "summary": "작업공간, ActionSpec, 외부 에셋과 비정상 종료 복구를 안전하게 관리합니다.", "time": "5분", "action": "none", "steps": [
			["작업공간 저장", ".adproject는 프로젝트 정보, Asset 색인, 내장 ActionSpec을 저장합니다. 에셋 가져오기 전에 저장해 상대 경로를 고정합니다."],
			["공식 원본 내보내기", ".action.json이 버전 관리용 원본이며 .action.tres는 다시 만들 수 있는 캐시입니다."],
			["폴더 전체 관리", ".adproject, actions, assets를 같은 프로젝트 폴더에 두고 누락 Asset은 Track을 지우지 말고 다시 지정합니다."],
			["복구 후 정상 저장", "복구는 30초 autosave를 엽니다. 확인 후 즉시 정상 위치로 저장·내보내며 Git 대용으로 사용하지 않습니다."],
		]},
		"mixamo": {"title": "Mixamo 캐릭터 가져오기", "summary": "Godot UFBX로 스킨 FBX를 3D 리허설 무대에 직접 불러옵니다.", "time": "6분", "action": "open_3d", "steps": [
			["내장 호환 데모 체험", "3D FBX 데모를 열어 실제 CC0 휴머노이드, 스켈레톤, 메시, 11개 애니메이션 클립을 같은 UFBX 경로에서 확인하세요. 재배포 가능하며 Mixamo 자산이 아닙니다."],
			["올바르게 다운로드", "Mixamo에서 FBX Binary를 선택하고 캐릭터 포함 시 With Skin을 사용합니다. 30 FPS 설정을 유지해도 됩니다."],
			["프로젝트 먼저 저장", "3D 샘플을 열어 .adproject로 저장하고 상대 에셋 폴더를 확정합니다."],
			["FBX 가져오기", "‘에셋 가져오기’에서 .fbx를 선택합니다. 골격, 메시, 애니메이션을 찾고 손상된 파일은 추가하지 않습니다."],
			["클립 맞추기", "에셋 툴팁의 클립 이름을 animation 이벤트 payload.clip에 입력합니다. 불일치 시 첫 클립을 fallback으로 재생합니다."],
			["범위 이해", "캐릭터+애니메이션 FBX는 바로 재생됩니다. 서로 다른 골격의 자동 retarget은 Alpha 범위 밖입니다."],
		]},
		"branching": {"title": "명중, 방어, 빗나감, 분기", "summary": "임의 코드 없이 결과 기반 경로를 리허설합니다.", "time": "7분", "action": "open_2d", "steps": [
			["JSON에서 구조 만들기", "Alpha는 기존 Branch를 재생하지만 GUI 작성은 지원하지 않습니다. .action.json에 Marker와 앞으로 가는 Branch를 추가해 다시 엽니다."],
			["활성 히트박스로 이동", "빨간 히트박스가 보일 때까지 재생하거나 한 tick씩 이동합니다."],
			["결과 보고", "왼쪽 클릭은 HIT, 오른쪽 클릭은 BLOCK입니다. 닫힐 때까지 결과가 없으면 같은 tick의 분기를 판단하기 전에 MISS가 됩니다."],
			["분기 확인", "분기는 예약 tick에만 실행되고 뒤쪽 마커로 이동합니다. 무대에 분기 ID와 대상이 표시됩니다."],
			["정리 확인", "건너뛴 히트박스와 취소 창은 점프 전에 닫혀 편집기와 Runtime 상태를 맞춥니다."],
		]},
		"applications": {"title": "실제 게임에 적용하기", "summary": "경공격, 3D 돌진, 차지 액션, Boss 반응에 같은 흐름을 사용합니다.", "time": "6분", "action": "open_2d", "steps": [
			["공격 위험 조절", "빠른 startup+긴 recovery 등을 비교하고 cancel window를 게임 state machine에 전달합니다."],
			["3D 돌진 제작", "Motion으로 실제 body를 이동하고 가슴 anchor Box hitbox와 접촉 시 hit stop/shake를 배치합니다."],
			["차지 액션 분기", "Play context의 charge_tier에서 서로 다른 Hitbox, VFX, Recovery 구간으로 앞으로 분기합니다."],
			["Boss 결과 연출", "hit, block, miss를 다른 경로로 보내되 피해와 AI는 host game에 남깁니다."],
			["질문 하나씩 검증", "기준 Take 탭과 ‘비교 대상’에서 원하는 다른 Take를 고르고 관련 변수만 바꾼 뒤 시간 차이를 기록합니다."],
		]},
		"godot": {"title": "Godot에서 내보내고 재생", "summary": "같은 ActionSpec을 기존 Godot 4.7 게임에 연결합니다.", "time": "10분", "action": "none", "steps": [
			["원본 내보내기", ".action.json을 내보냅니다. JSON이 원본이고 .tres는 다시 만들 수 있는 캐시입니다."],
			["Addon 설치", "addons/action_director_runtime을 게임에 복사하고 Project Settings > Plugins에서 활성화합니다."],
			["연결", "ActionSpec과 ActionDirectorPlayer를 불러오고 Actor/Camera/AudioVFX Adapter를 기존 시스템에 연결합니다."],
			["재생", "player.play(action_spec, take_name, context)를 호출하고 충돌은 report_outcome, 취소는 request_cancel로 보고합니다."],
			["책임 분리", "Runtime은 타이밍과 요청만 발행합니다. 피해, 충돌 판단, 상태 머신, AI, 네트워크는 게임이 관리합니다."],
			["실제 Lifecycle API", "Hitbox는 opened/closed, Cancel window는 cancel_window_changed를 가집니다. Hurtbox와 다른 Window는 시작 시 event_fired만 있고 종료는 Host가 end_tick으로 처리합니다."],
		]},
		"troubleshooting": {"title": "가져오기와 복구 문제 해결", "summary": "첫 프로젝트를 막기 쉬운 문제를 해결합니다.", "time": "4분", "action": "none", "steps": [
			["가져오기 전에 저장 요청", "먼저 .adproject를 저장해 안정적인 상대 에셋 경로를 만듭니다."],
			["FBX에 애니메이션 없음", "Mixamo에서 FBX Binary로 다시 받고 통합 캐릭터는 With Skin을 사용합니다. 모션 전용은 호환 골격이 필요합니다."],
			["크기나 방향 오류", "Alpha는 가져온 Transform을 유지합니다. DCC에서 수정하거나 Mixamo 기본값으로 다시 받으세요."],
			["원본 액션 이동", ".adproject에는 ActionSpec 복구본이 있습니다. 외부 에셋은 트랙을 지우지 말고 다시 지정합니다."],
			["충돌 복구", "‘복구’로 30초 자동 저장을 연 뒤 정상 프로젝트 경로로 즉시 저장/내보냅니다."],
		]},
		"shortcuts": {"title": "키보드 단축키", "summary": "키보드로 핵심 리허설 흐름을 조작합니다.", "time": "1분", "action": "none", "steps": [
			["재생", "Space: 재생/일시정지 · ,: 이전 tick · .: 다음 tick · R: 초기화 · C: A/B 전환"],
			["편집", "Ctrl/Cmd+Z: 실행 취소 · Ctrl/Cmd+Shift+Z 또는 Ctrl+Y: 다시 실행 · Ctrl/Cmd+S: 저장"],
			["타임라인", "포커스 · 위/아래: 트랙 선택 · 왼쪽/오른쪽: 이벤트 선택 · Ctrl/Cmd+휠: 확대 · 눈금자: 이동 · Delete: 선택 삭제"],
		]},
	},
}


static func get_chapter(locale: String, chapter_id: String) -> Dictionary:
	var normalized := ActionLocalization.normalize_locale(locale)
	var catalog: Dictionary = CONTENT.get(normalized, CONTENT["en"])
	return catalog.get(chapter_id, CONTENT["en"].get(chapter_id, {})).duplicate(true)


static func get_chapters(locale: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for chapter_id: String in CHAPTER_IDS:
		var chapter := get_chapter(locale, chapter_id)
		chapter["id"] = chapter_id
		result.append(chapter)
	return result
