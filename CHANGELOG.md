# Action Director 更新紀錄

本檔記錄會影響使用者、整合者或貢獻者的程式變更。日期使用
`YYYY-MM-DD`，版本發布前先寫在「尚未發布」，發布時再移入正式版本。

每次程式更新必須同步修改本檔，至少說明「新增、變更、修正、文件、
測試」其中一類；純排版或內部整理也要在「內部」留下簡短紀錄。

### 基礎功能

- 2D 範例內附原創 CC0 授權的 8 格劍士 spritesheet，開啟
  「2D 逐格範例」即可直接觀察依 tick 切格的攻擊動畫。
- 3D 範例內附 Quaternius CC0 雙足角色 FBX，包含骨架、網格與 11 段
  動畫；開啟「3D FBX 範例」即可直接看到 UFBX 匯入與播放。
- 工作區頂端新增目前動作、Take 數量、2D／3D 維度與 Alpha 狀態，
  不需展開專案樹即可確認編輯情境。
- A／B 摘要新增「跳到差異」，可直接將播放頭移到首個語意差異。
- 在時間軸工具列加入事件類型選擇、「加到播放頭」、「新增軌道」、
  「刪除事件」與「刪除軌道」。
- 支援直接建立與刪除動畫、戰鬥窗口、Hitbox、Hurtbox、位移、手感、
  音效、VFX、鏡頭、遊戲事件與備註軌道／事件。
- Inspector 可修改事件類型與所屬演員。
- 新增 2D／3D 專用預設 Payload；2D Hitbox／Hurtbox 使用 `rect` 與
  二維向量，3D 使用 `box` 與三維向量。
- 新增軌道與事件選取狀態，點擊軌道名稱即可選取整條軌道。

### 變更

- 2D 預演會依 ActionSpec 素材的 `frame_count` 與 `layout` 切出目前
  影格，並參考 animation 事件長度與速度，不再把整張 spritesheet
  壓成一張靜態圖。
- 內附 PNG 與 FBX 會透過 Godot `ResourceLoader` 讀取匯出後的 Texture 與
  PackedScene；外部專案素材仍使用檔案路徑，避免下載版因 PCK 重映射
  而只顯示代理圖。
- 重整頂部工具列為「工作區身分」與「檔案／播放」兩層，匯出、
  播放與 A／B 開關改用明確主要與狀態色。
- 主要 Take 與比較 Take 的舞台改用綠／琥珀色標頭與邊界，2D 與
  3D 預演都顯示角色、Take 名稱與 tick 進度。
- 時間軸新增目前選取摘要；刪除事件／軌道只在有相容選取時啟用，
  縮放會擴展可捲動畫布，不再裁切後段 tick。
- Inspector 未選事件時改為明確空白引導；套用按鈕只在 JSON 有效且
  欄位實際改變後啟用。
- 「複製 Take」改用完整快照加入 Undo／Redo，復原會移除複本，重做會
  恢復複本與原本的比較關係。
- Inspector 的開始與結束 tick 會依目前 Take 長度限制；切換 Take 時
  立即重新綁定上限，避免產生無法匯出的 ActionSpec。
- 時間軸新增操作會優先使用相容的已選軌道，沒有相容軌道時自動建立。
- `.gitignore` 加入 macOS `.DS_Store` 與匯出測試用 Godot home。

### 文件

- README 新增公開 GitHub Releases 下載與 One More Run 完整介紹連結，
  讓程式原始碼、二進位檔與網站教學各自保持清楚邊界。
- 四語程式內教學與完整手冊新增「2D 逐格動作範例」說明，
  並將 2D 與 3D 內附範例的授權、用途與 Alpha 邊界分開記錄。
- 四語程式內教學與完整手冊新增「內附 CC0 相容範例→使用者自行下載
  Mixamo FBX」流程，並明確說明內附檔案不是 Mixamo 素材。
- 新增 CC0 素材來源、授權與 SHA-256 紀錄；不再散布 Adobe Mixamo
  原始角色或動畫檔。
- Windows 與原始碼套件內附 MIT `LICENSE` 與 `THIRD_PARTY_NOTICES.txt`，
  集中列出 2D／3D 範例素材的 CC0 授權來源。
- 更新公開網站「尚未發布」日誌與真實工作台截圖，反映本次 UI
  層級、A／B 差異導覽與編輯狀態改良。
- 更新英文、繁體中文、日文與韓文完整手冊，反映圖形化軌道／事件編排
  與 Inspector 新能力。
- 更新程式內四語教學、README、PRODUCT 與 ActionSpec Schema。
- Marker 與 Branch 仍明確標示為 Alpha 的手動 JSON 工作流程。
- 新增 One More Run 網站的置頂英文長篇介紹，包含誕生背景、問題定義、
  10 分鐘教學、Mixamo 流程、Godot 交接、直接下載與公開更新日誌；網站
  明確區分 Windows Alpha、原始碼／Addon 與尚未公發的 macOS 套件。
- 補充網站產品邊界、頁面契約與可重用設計系統文件，確保後續更新持續
  分離開發者工具與玩家攻略，並保留真實狀態與證據規則。

### 測試

- 測試總數增加至 31 項，新增內附 2D spritesheet 的透明度、
  8 格切片、tick 進格與授權紀錄覆蓋，並保留內附 CC0 FBX 的檔案存在、UFBX 解析、
  Mixamo 相容性、動畫片段與授權紀錄覆蓋；並保留工作區身分、A／B 差異
  按鈕、危險操作
  啟用狀態、Inspector 空白／變更狀態與時間軸縮放畫布覆蓋，並繼續
  涵蓋圖形化編排、2D／3D 預設 Payload、
  匯出安全的 Texture／PackedScene 資源路徑、Inspector 控制、Take 複製
  Undo／Redo，以及 72-tick 切換到 60-tick
  Take 時的時間上限重綁。
- Godot 4.7 測試結果：31／31 通過。
- 獨立完成度審查結果：PASS；沒有本輪未解決的程式阻擋項目。

### 內部

- 新增可重現的網站工作台截圖腳本，讓公開介紹頁能使用真實程式畫面，
  不以示意介面取代目前 Alpha 功能。
- 新增可重現的 3D FBX 範例截圖腳本與公開截圖，同時移除
  `SubViewportContainer.stretch` 開啟時重複手動改寫 viewport 尺寸的執行警告。

## 0.1.0-alpha — 2026-08-13

### 新增

- 建立免費、MIT 授權、完全離線的 Godot 4.7 動作預演桌面程式與 Runtime
  Addon 垂直切片。
- 提供 2D 劍擊與 3D 衝撞範例、固定 60 ticks 時間軸、Take A／B 同步
  試打、首次差異摘要與逐 tick 播放。
- 支援 Animation、Window、Hitbox、Hurtbox、Motion、Feel、Audio、VFX、
  Camera、Game Event 與 Note 事件。
- 支援 PNG、WebP、WAV、OGG、GLB、glTF 與 Mixamo FBX 素材匯入；Mixamo
  FBX 使用 Godot UFBX 讀取骨架、網格與動畫片段。
- 提供 `.adproject` 工作區、`.action.json` 正式規格、自動存檔、崩潰
  復原與 Godot `.tres` 快取匯入器。
- 提供 Hit／Block／Miss 回報、向後續 Marker 前進的條件分支，以及未回報
  結果時的自動 Miss。
- 提供英文、繁體中文、日文與韓文介面、程式內十章教學及四語離線完整
  手冊。
- Runtime 提供 `ActionDirectorPlayer`、2D／3D Actor Adapter、Camera
  Adapter 與 Audio／VFX Adapter。

### 已知限制

- Marker 與 Branch 尚無圖形化編輯器。
- 不提供跨骨架自動 Retarget、骨架動畫、蒙皮、IK、模型編輯、傷害公式、
  AI、角色狀態機或網路同步。
- Hurtbox 與非 Cancel Window 目前只有開始時的通用事件；配對生命週期僅
  適用於 Hitbox 與 Cancel Window。
- macOS 公開發行仍需 Developer ID 簽署與 Notarization。
