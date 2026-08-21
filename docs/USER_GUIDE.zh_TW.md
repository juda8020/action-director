# 動作導演台完整使用手冊

版本：v0.1 Alpha  
適用：Windows、macOS、Godot 4.7  
語言：繁體中文

## 1. 這個程式是做什麼的？

動作導演台（Action Director）是一套給獨立遊戲開發者使用的離線動作預演工具。它把「角色動畫什麼時候播放、攻擊框什麼時候出現、角色移動多少、命中時停頓多久、何時可取消、音效與特效何時發生」整理成同一份可檢查的時間規格。

它主要解決三個問題：

1. **只看動畫，很難判斷遊戲手感。** 同一段揮劍動畫，攻擊框提早 4 ticks、位移增加 20 像素、hit stop 多 2 ticks，實際感覺可能完全不同。
2. **策劃與程式容易使用不同時序。** 動作導演台將所有正式事件固定在每秒 60 ticks，編輯器與 Godot Runtime 使用同一份 `.action.json`。
3. **修改後缺乏可比較證據。** Take A／Take B 能同時重播；差異摘要會指出第一個真正不同的時間點，而不是只靠記憶判斷。

它不是骨架動畫製作軟體、3D 建模軟體、傷害計算器或完整戰鬥引擎。角色骨架、蒙皮、動畫片段應先在 Blender、Mixamo 或其他工具中完成；動作導演台負責編排這些既有素材如何成為遊戲動作。

## 2. 適合哪些工作？

- 設計近戰攻擊的前搖、有效期與後搖。
- 比較「重而有力」與「快速俐落」兩種版本。
- 編排衝刺、跳斬、擊退、霸體、無敵與取消窗口。
- 在 3D 舞台預演 Mixamo 角色與動畫。
- 規劃命中、格擋、落空、空中或蓄力結果的後續分支。
- 把策劃確認過的時序交給 Godot 4.7 遊戲執行。
- 製作短演出中的鏡頭、音效、VFX 與自訂遊戲事件。

不適合：製作骨架動畫、修模型、跨骨架自動 retarget、計算傷害、控制 AI、處理網路同步、製作完整長篇過場或對話系統。

## 3. 先理解四個核心概念

### ActionSpec

一個完整動作的正式規格，包含維度、演員、素材、Take、軌道、事件、標記與分支。`.action.json` 是正式來源，適合 Git 版本控制；`.action.tres` 只是 Godot 可重新產生的快取。

### Tick

所有正式時間固定為每秒 60 ticks。tick 20 代表動作開始後約 0.333 秒。事件的 `start_tick` 與 `end_tick` 都包含在有效範圍內；開始與結束同為 17 的事件會在 tick 17 開啟並於同一 tick 關閉。

### Take

同一個動作的完整版本。例如 Take A 是慢而重，Take B 是快而遠。複製 Take 會建立完全獨立的軌道、事件與 ID，之後修改 B 不會偷偷影響 A。

### 軌道與事件

軌道把相同用途的事件排在一起。動畫、攻擊框、位移、戰鬥窗口、手感、音效、VFX、鏡頭與遊戲事件都依 tick 執行。

## 4. 介面導覽

- **上方工具列**：開啟、復原檔、匯入素材、儲存專案、匯出動作、復原／重做、逐 tick、播放、重設、A/B 開關、教學、語言。
- **左側專案區**：動作、Take、演員與素材。也可快速開啟內建 2D 劍擊或 3D 衝撞範例。
- **中央舞台**：顯示目前 Take；開啟 A/B 時左右同步重播。
- **右側 Inspector**：編輯所選事件的 ID、類型、開始／結束 tick 與 Payload JSON。
- **下方時間軸**：顯示所有軌道、事件區間、播放頭與 tick 刻度。
- **最下方狀態列**：顯示成功、警告、錯誤與目前 tick／秒數。

## 5. 第一次使用：完成一次 A/B 劍擊比較

1. 啟動程式。首次啟動會開啟教學中心；也可從工具列按「教學」。
2. 左側按「開啟 2D 範例」。中央會顯示 Take A 與 Take B。
3. 按 Space 播放。觀察兩邊接近假人、紅色攻擊框出現與命中停頓的差別。
4. 查看舞台上方的「首次差異」。內建範例中 Take B 的攻擊更早、突進更遠、總長較短。
5. 在下方時間軸點選一個事件，例如 active window、hitbox 或 motion。
6. 在右側修改 tick 或 Payload JSON，按「套用事件修改」。若 JSON 不合法，或修改會使目前 ActionSpec 無效，程式會說明原因、拒絕修改並保留原資料。
7. 使用 Ctrl/Cmd+Z 復原，或 Ctrl/Cmd+Shift+Z（Windows 亦可 Ctrl+Y）重做。
8. 按「儲存」建立 `.adproject` 工作區，再按「匯出」產生 `.action.json`。

建議第一次只改一個變數，例如把 Take B 的 hitbox 從 tick 15 改為 18。一次改太多會難以判斷是哪個改動造成手感差異。

## 6. 專案與檔案管理

### `.adproject`：工作區

保存目前動作、專案資料夾、素材索引、可復原資料與審核位置。重新開啟時會恢復主要 Take、比較 Take、A／B 顯示狀態與播放 tick。匯入外部素材前必須先儲存專案，因為素材需要穩定的專案相對路徑。

### `.action.json`：正式動作規格

遊戲、版本控制與團隊審查應以此檔案為準。匯出時不要用 `.tres` 取代 JSON；`.tres` 可由 Addon 再生。

### 自動儲存與復原

程式每 30 秒保存目前 ActionSpec 到復原檔。若上次異常關閉，按「復原」打開內容，確認後立刻儲存為正常 `.adproject` 並重新匯出 JSON。自動存檔不是正式版本管理的替代品。

### 推薦資料夾

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

移動專案時請整個資料夾一起移動。外部素材遺失時應重新定位素材，不要為了消除警告而刪除原軌道。

## 7. 素材匯入

目前可匯入 PNG、WebP、WAV、OGG、GLB、glTF 與 FBX。匯入後檔案會複製到專案素材資料夾，以相對路徑記錄。

### 2D 圖片與音訊

1. 儲存 `.adproject`。
2. 按「匯入素材」選 PNG／WebP 或 WAV／OGG。
3. 2D 預演會使用第一個匯入圖片替代演員代理圖。
4. 音效事件的 `payload.asset_key` 必須對應素材 key，事件抵達時才會播放。

請先開啟「**2D 逐格範例**」。內附原創 CC0 授權的 8 格劍士圖，
會依 animation 事件的固定 tick 進格。Take A 與 Take B 使用同一組
影格，但長度與速度不同，因此差異不只顯示在數據摘要，角色動畫
也看得出來。Alpha 已會讀取 ActionSpec 的 `frame_count` 與 `layout`
元資料，但仍未提供任意 spritesheet 的完整圖形化切格設定；可先在
JSON 編寫這些資料，或在 Godot 建立最終動畫資源。

### GLB／glTF

匯入帶動畫的模型後，3D 舞台會嘗試播放動畫事件 `payload.clip` 指定的片段。若名稱不符，Alpha 會用第一個可用片段作為可見 fallback；這能避免舞台完全不動，但正式匯出前仍應改成正確名稱。

## 8. Mixamo 完整工作流程

先從左側範例區開啟「**3D FBX 範例**」。這會用與 Mixamo FBX 相同的
Godot UFBX 路徑，載入 Quaternius 以 CC0 授權的真實雙足角色、骨架、
網格與 11 段動畫。內附檔案刻意不使用 Mixamo 素材：Adobe 允許將其用在遊戲
等專案中，但不允許開源工具再散布 Mixamo 原始角色或動畫檔。確認範例後，
再用自己的 Adobe ID 下載 FBX，並依下列步驟替換。

### 在 Mixamo 下載

1. 選擇角色與動畫。
2. Format 選 **FBX Binary**。
3. 角色與動畫一起使用時選 **With Skin**。
4. FPS 可保留 30；ActionSpec 的事件仍固定在 60 ticks，不會因來源動畫 FPS 改變。

### 在動作導演台匯入

1. 開啟 3D 範例。
2. 先儲存 `.adproject`。
3. 按「匯入素材」選擇 `.fbx`。
4. 等待 Godot 4.7 UFBX 辨識骨架、網格與動畫片段。
5. 在左側素材 Tooltip 查看片段名稱。
6. 選取 animation 事件，把 Payload 中的 `clip` 改成實際片段名稱，例如：

```json
{
  "clip": "mixamo.com",
  "speed": 1.0,
  "blend": 0.08,
  "reverse": false
}
```

7. 播放 3D 預演，確認模型、方向、位移與片段都正確。

### 常見限制

- FBX 損壞、沒有可解析場景或沒有必要資料時會被拒絕，不會留下半匯入素材。
- Motion-only FBX 需要與遊戲角色相容的骨架／retarget 流程。
- Alpha 不會自動把 A 角色的動畫 retarget 到 B 角色骨架。
- 模型尺度或面向錯誤時，請在 DCC 工具修正，或依 Mixamo 預設重新下載。

## 9. 時間軸與軌道如何使用

目前 Alpha 的圖形介面可新增／刪除指定類型的軌道與事件、把事件加到播放頭、複製完整 Take，並修改事件 type、actor、開始／結束 tick 與 Payload JSON。點軌道名稱即可選取整條軌道；刪除事件或軌道都能復原。Marker 與 branch 仍依第 10 節的進階 JSON 流程建立。下列各軌道說明同時也是 ActionSpec 格式參考。

### Animation

指定動畫片段與播放方式。常用 Payload：`clip`、`speed`、`blend`、`reverse`。讓事件長度與動作所需時序一致；動畫畫面與遊戲事件不必完全同長。

### Window

描述 startup（前搖）、active（有效期）、recovery（後搖）、cancel（取消）等戰鬥狀態。所有 window 都會在開始 tick 發出一次通用 `event_fired`；只有 `kind: "cancel"` 另外提供 `cancel_window_changed(tag, true/false)` 成對生命週期。其他 window 目前沒有專用關閉 signal，遊戲若需要結束時間，必須從 ActionSpec 的 `end_tick` 自行排程。這些訊號不會自動替遊戲改狀態機。

### Hitbox／Hurtbox

2D 可用 rect、circle、capsule；3D 可用 box、sphere、capsule。Payload 應記錄 anchor、offset、size 等。`hitbox` 會提供 `hitbox_opened`／`hitbox_closed` 成對 signal；`hurtbox` 目前只在開始 tick 發出通用 `event_fired`，沒有專用關閉 signal。真正的碰撞、hurtbox 生命週期補完與傷害仍由遊戲處理。

### Motion

`delta` 表示位移量，`space` 為 `local` 或 `world`。2D 使用 `[x, y]`，3D 使用 `[x, y, z]`。區分動畫內的視覺移動與真正角色碰撞體位移。

### Feel

可描述 hit stop、鏡頭震動或局部手感事件。規格提供 timing 與 strength；遊戲端決定實際畫面、時間縮放與無障礙選項。

### Audio／VFX

`asset_key` 對應 Godot Adapter 的資源字典。可在命中 tick 放火花，在揮動前放 whoosh。預演用素材 key 必須與遊戲端映射一致。

### Camera

向 `ActionCameraAdapter` 發出跟隨、縮放、FOV 或震動請求。Runtime 不強制替換遊戲攝影機。

### Game event／Note

Game event 適合自訂 signal、標籤與參數，例如生成投射物、扣除耐力、切換武器狀態。Note 只供設計溝通，不應承擔正式遊戲邏輯。

## 10. 進階 JSON 編排與 Take A／B 方法

### 建立圖形介面尚未支援的 Marker 與 Branch

1. 先複製最接近的內建 `.action.json`，不要從完全空白檔開始。
2. Track 與 event 直接在時間軸建立；只有新增、刪除或修改 marker／branch 時才關閉檔案並使用文字編輯器。
3. 每個 take、track、event、marker、branch 都要有不重複的 ID；同一事件須滿足 `start_tick <= end_tick <= duration_ticks`。
4. 2D 與 3D 座標不能在同一 ActionSpec 混用。載入器會拒絕 2D 中的三值 Motion／shape 向量或 `box`／`sphere`，以及 3D 中的二值向量或 `rect`／`circle`；`capsule` 可用於兩種維度，但向量長度仍須一致。新增 branch 時，`target_marker` 的 tick 必須晚於 `at_tick`。
5. 儲存 JSON，回到動作導演台按「開啟」重新載入。重複 UUID、毀損 JSON、非法範圍或向後分支會被拒絕。
6. 載入成功後，用圖形介面新增軌道／事件、修改 type／actor／tick／Payload、複製 Take、A/B 試打並匯出。

動作導演台目前不會監看外部檔案變化；每次文字修改後都要重新開啟 JSON。若你已把動作存進 `.adproject`，外部 JSON 修改不會自動改寫內嵌副本。

### 比較方法

1. 先做一個可正常完成的基準 Take。
2. 按「複製 Take」建立獨立版本。
3. 選擇主要 Take 分頁，再從「比較對象」指定任一其他版本；專案有三個以上 Take 時，不會被限制只能比較下一個分頁。
4. 為每次比較訂一個問題，例如「攻擊是否太難反應？」或「命中是否缺乏重量？」
5. 每次只改一組相關參數：
   - 反應速度：startup、動畫 speed。
   - 攻擊距離：motion delta、hitbox offset／size。
   - 重量感：hit stop、shake、audio／VFX tick。
   - 風險：recovery、cancel window。
6. 使用相同起點與輸入播放兩個 Take。
7. 查看首次差異、總長度與事件時刻，不只看哪個比較華麗。
8. 選出版本後仍保留另一 Take，讓差異可以被審查與回溯。

內建劍擊範例：Take A 共 72 ticks，較慢且恢復長；Take B 共 60 ticks，startup 更短、突進更遠、震動更強，並在格擋時向 recovery 標記分支。這是一個比較方法範例，不代表正式平衡建議。

## 11. 命中、格擋、落空與分支

1. 播放或逐 tick 到紅色攻擊框出現。
2. 在 2D 預演舞台對有效攻擊框按左鍵回報 `hit`，按右鍵回報 `block`。
3. 若攻擊框關閉前沒有回報，Runtime 會先自動設為 `miss`，再判斷排在同一個結束 tick 的分支。
4. 分支在 `at_tick` 檢查條件，成立時只能前往之後的 marker。

```json
{
  "id": "on-block",
  "at_tick": 24,
  "condition": {"kind": "block", "value": true},
  "target_marker": "recovery"
}
```

允許條件：`hit`、`block`、`miss`、`grounded`、`airborne`、`charge_tier`、`custom_bool`。分支不能倒退、循環或執行任意程式碼。被跳過的 hitbox 與 cancel window 會在跳轉前正確關閉，避免 Runtime 留下錯誤狀態。

## 12. 如何應用到實際遊戲設計

### 案例 A：調整輕攻擊手感

- Take A：startup 18 ticks、active 6 ticks、recovery 28 ticks。
- Take B：startup 14 ticks、active 5 ticks、recovery 32 ticks。
- 目標：確認更快出手是否需要更長後搖維持風險。
- 應用：把選定版本匯出，讓 Godot 狀態機在 cancel window 開關時決定能否接閃避。

### 案例 B：3D 肩撞

- 匯入 Mixamo 角色＋動畫。
- 目前需由 JSON 複製／建立 motion 與 hitbox event，再回到程式內微調。
- 用 motion 軌道移動碰撞角色，不依賴模型動畫看起來有前進。
- 在胸口 anchor 設定 3D box hitbox。
- 命中時發出 hit stop 與 camera shake。
- 應用：遊戲碰撞系統收到 `hitbox_opened` 後建立／啟用 Area3D，判定完再呼叫 `report_outcome`。

### 案例 C：蓄力攻擊

- 目前需在 JSON 建立 charge_tier branch 與其後續 marker，再回到程式內試打。
- context 傳入 `charge_tier`。
- 在指定 tick 依 tier 分支到不同 marker。
- 不同路徑安排不同 hitbox、VFX 與 recovery。
- 應用：輸入系統負責算蓄力層級，Action Director 只負責重播已決定層級的時序。

### 案例 D：Boss 格擋反應

- 目前需在 JSON 建立 hit／block／miss 分支結構。
- 命中走正常 recovery。
- block 結果提前跳到反彈動畫與較長後搖。
- miss 讓角色完成原動作。
- 應用：Boss AI 與傷害系統仍在遊戲端；ActionSpec 只定義結果發生後的演出與窗口。

## 13. 匯出到 Godot 4.7

1. 在動作導演台匯出 `.action.json`。
2. 複製 `addons/action_director_runtime/` 到遊戲專案。
3. 到 Project Settings → Plugins 啟用 Action Director Runtime。
4. 載入規格並播放：

```gdscript
var loaded := ActionSpecCodec.load_json("res://actions/sword.action.json")
if loaded.ok:
    $ActionDirectorPlayer.play(loaded.spec, "Take B", {
        "grounded": true,
        "charge_tier": 0
    })
```

5. 將 Runtime signals 接到現有系統：

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

6. 依專案選用 `ActionActorAdapter2D`／`ActionActorAdapter3D`、`ActionCameraAdapter`、`ActionAudioVfxAdapter`。

生命週期 API 要分清楚：`hitbox` 有 `hitbox_opened/closed`，`cancel` window 有 `cancel_window_changed`；`hurtbox` 與其他 window 只有開始時的 `event_fired`。若遊戲需要它們在 `end_tick` 關閉，請由遊戲端依規格排程，或先擴充 Runtime Adapter。

責任邊界：Runtime 管 tick、事件順序、分支與清理；遊戲管傷害、目標、碰撞結果、角色狀態機、AI、輸入與連線。不要讓 Runtime 與遊戲兩邊同時計算同一套傷害或狀態。

## 14. 團隊協作與版本控制

- 將 `.action.json` 加入 Git；是否加入 `.adproject` 依團隊是否需要共享工作區決定。
- 不要把 `.tres` 當唯一來源。
- 一個設計問題建立一個 Take，命名要表達意圖，例如 `Fast Startup`、`Heavy Impact`，不要只用 `New Take 3`。
- Pull Request 描述應列出 startup、active、recovery、總長、位移、hit stop 與 cancel window 的變化。
- 未知事件會被保留並顯示相容性警告；確認外掛版本前不要刪除未知資料。
- 重複 UUID、毀損 JSON、向後分支會被驗證器拒絕；修正來源後再匯出，不要繞過驗證。

## 15. 快捷鍵

| 功能 | 快捷鍵 |
|---|---|
| 播放／暫停 | Space |
| 前一 tick／下一 tick | `,`／`.` |
| 重設預演 | R |
| A/B 比較開關 | C |
| 復原 | Ctrl/Cmd+Z |
| 重做 | Ctrl/Cmd+Shift+Z，Windows 亦可 Ctrl+Y |
| 儲存專案 | Ctrl/Cmd+S |
| 選取時間軸軌道 | 聚焦時間軸，再按上／下方向鍵 |
| 選取軌道事件 | 聚焦時間軸，再按左／右方向鍵 |
| 時間軸縮放 | Ctrl/Cmd+滑鼠滾輪 |
| 時間軸定位 | 點擊時間尺 |
| 檢查事件 | 點擊事件 |
| 選取軌道 | 點擊軌道名稱 |
| 新增事件 | 選擇類型，再按「加到播放頭」 |
| 刪除選取項目 | 「刪除事件」、「刪除軌道」或 Delete 鍵 |
| 教學捲動 | Page Up／Page Down／Home／End |
| 關閉教學 | Esc |

## 16. 疑難排解

### 為什麼不能匯入素材？

先儲存 `.adproject`。沒有專案位置時，程式無法建立可靠的相對素材路徑。

### 為什麼 FBX 沒有動畫？

確認 Mixamo 使用 FBX Binary；角色＋動畫選 With Skin。若只下載動作，必須有相容骨架或外部 retarget 流程。

### 為什麼 3D 模型不動或播放錯片段？

查看素材 Tooltip 的動畫片段名稱，將 animation event 的 `payload.clip` 改成完全相同的名稱。

### 為什麼模型大小或方向不對？

Alpha 保留來源 Transform，請在 Blender 等 DCC 修正尺度／面向，或按 Mixamo 預設重新下載。

### 為什麼聲音沒有播放？

確認已匯入 WAV／OGG，且 audio event 的 `asset_key` 與專案素材 key 一致。

### 為什麼分支沒有發生？

確認結果已在 branch 的 `at_tick` 前回報、條件值正確、target marker 位於分支之後。若 hitbox 關閉前沒有結果，它會成為 miss。

### 原始 `.action.json` 被移動怎麼辦？

開啟 `.adproject`；其中有內嵌 ActionSpec 復原副本。重新匯出到新位置，再重新定位外部素材。

### 程式異常關閉後如何復原？

重新啟動後按「復原」，打開 30 秒自動存檔；檢查內容後立即存成正常專案。

## 17. Alpha 已知邊界

- 尚未提供跨骨架自動 retarget。
- 圖形介面可新增／刪除軌道與事件，也能修改事件 type、actor、tick 與 Payload；marker 與 branch 目前仍需手動編輯 `.action.json`。
- Runtime 只有 hitbox 與 cancel window 提供專用開／關生命週期；hurtbox 與其他 window 只有開始時的通用事件。
- 尚未提供完整 spritesheet 切格、參考影片、contact sheet、波形與 transform keyframe 工具。
- 不製作骨架動畫、蒙皮、IK 或模型。
- 不計算傷害、不負責 AI、狀態機或網路同步。
- macOS 公開散布仍需要 Developer ID 簽署與 Apple notarization。

這些邊界不影響核心契約：同一份 ActionSpec 在預演與 Godot Runtime 中以固定 60 ticks、相同事件順序與分支規則執行。
