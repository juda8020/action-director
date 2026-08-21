# Action Director 상세 사용자 가이드

버전: v0.1 Alpha  
대상: Windows, macOS, Godot 4.7

## 1. 이 프로그램의 역할

Action Director는 2D/3D 게임 액션을 완전 오프라인으로 설계하고 비교하는 리허설 도구입니다. 기존 애니메이션, 전투 창, 히트박스, 이동, 히트 스톱, 카메라, 오디오, VFX, 게임 이벤트를 하나의 고정 60 tick 타임라인에 배치합니다.

애니메이션만 봐서는 알기 어려운 실제 조작감을 확인하고, 디자이너와 게임 코드 사이의 타이밍 차이를 막으며, Take A/B를 같은 조건으로 비교합니다. 내보낸 `.action.json`은 포함된 Godot Runtime에서 동일한 이벤트 순서로 실행됩니다.

뼈대 애니메이션 제작, 스키닝, 모델 수정, 피해 계산, AI, 상태 머신을 대신하지 않습니다. Mixamo나 Blender에서 기존 에셋을 준비한 뒤, 이 도구로 “게임에서 언제 무엇이 발생하는가”를 설계합니다.

## 2. 적합한 용도와 범위 밖

- 공격 startup, active, recovery 조정.
- 빠르고 가벼운 Take와 느리고 무거운 Take 비교.
- 돌진, 공중 공격, 무적, 아머, 입력 버퍼, 취소 창 설계.
- Mixamo 캐릭터와 애니메이션의 3D 리허설.
- hit, block, miss, grounded, airborne, charge tier 분기.
- 승인된 타이밍을 Godot 4.7 게임에 전달.

범위 밖: 뼈대/IK/모델 제작, 다른 뼈대 간 자동 retarget, 피해 공식, AI, 네트워크 동기화, 완전한 대화 시스템이나 장편 컷신 편집.

## 3. 핵심 개념

### ActionSpec

한 액션의 공식 사양입니다. dimension, actor, asset, take, track, event, marker, branch를 포함합니다. `.action.json`이 원본이며 `.action.tres`는 다시 만들 수 있는 Godot 캐시입니다.

### Tick

공식 시간은 항상 초당 60 ticks입니다. tick 20은 시작 후 약 0.333초입니다. `start_tick`과 `end_tick`은 모두 포함됩니다. 둘 다 17인 이벤트는 tick 17에서 열리고 같은 tick에서 닫힙니다.

### Take

같은 액션의 완전한 버전입니다. 복제 시 track, event, marker, branch, ID가 독립 복사되므로 Take B 수정이 Take A에 영향을 주지 않습니다.

### Track과 Event

Track은 animation, window, hitbox, motion, feel, audio 같은 목적별로 Event를 모읍니다. Runtime은 애니메이션 외형을 추측하지 않고 Event의 tick과 payload를 실행합니다.

## 4. 화면 구성

- **상단 도구 모음**: 열기, 복구, 에셋 가져오기, 프로젝트 저장, 액션 내보내기, 실행 취소/다시 실행, tick 이동, 재생, 초기화, A/B, 튜토리얼, 언어.
- **왼쪽 프로젝트 패널**: Action, Take, Actor, Asset 및 2D 검격/3D 돌진 샘플.
- **중앙 무대**: 현재 Take와 비교 Take의 동기 리허설.
- **오른쪽 Inspector**: Event ID, type, 시작/끝 tick, Payload JSON 편집.
- **하단 타임라인**: Track, Event 범위, 눈금자, 재생 위치.
- **상태 표시줄**: 성공, 경고, 복구 가능한 오류, 현재 tick/초.

## 5. 첫 A/B 리허설

1. 최초 실행 튜토리얼을 사용하거나 왼쪽에서 **2D 샘플 열기**를 선택합니다.
2. Space를 누르면 양쪽이 같은 tick과 입력 조건으로 재생됩니다.
3. 무대 위의 첫 차이를 확인합니다. 샘플 Take B는 더 일찍 공격하고 더 멀리 이동하며 빨리 끝납니다.
4. 타임라인에서 active window, hitbox 또는 motion Event를 선택합니다.
5. Inspector에서 tick 또는 Payload JSON을 수정하고 **이벤트 변경 적용**을 누릅니다. 잘못된 JSON이나 현재 ActionSpec을 무효로 만드는 수정은 이유를 표시하고 기존 데이터를 유지한 채 거부됩니다.
6. Ctrl/Cmd+Z로 실행 취소, Ctrl/Cmd+Shift+Z(Windows는 Ctrl+Y도 가능)로 다시 실행합니다.
7. `.adproject`를 저장한 뒤 공식 `.action.json`을 내보냅니다.

처음에는 한 묶음의 변수만 바꾸세요. 속도, 거리, recovery, 연출을 한꺼번에 바꾸면 감각 변화의 원인을 알기 어렵습니다.

## 6. 파일 관리

- **`.adproject`**: 편집 작업공간. 프로젝트 정보, Asset 색인, 내장 ActionSpec 복구본과 함께 기본 Take, 비교 Take, A/B 표시 상태, playhead tick을 저장합니다. 다시 열면 같은 검토 위치로 돌아갑니다. 외부 Asset을 가져오기 전에 먼저 저장하세요.
- **`.action.json`**: Godot 통합과 Git 검토의 공식 원본입니다. 생성된 `.tres`만 유일한 원본으로 사용하지 마세요.
- **자동 저장**: 30초마다 복구 ActionSpec을 저장합니다. 비정상 종료 후 **복구**로 열고 정상 위치에 즉시 저장합니다.

```text
my-action-project/
├── combat.adproject
├── actions/sword.action.json
└── assets/
    ├── hero.fbx
    ├── whoosh.ogg
    └── impact.webp
```

이동할 때 폴더 전체를 함께 옮기고, Asset을 잃어버렸다면 Track을 삭제하지 말고 다시 지정합니다.

## 7. 에셋 가져오기

PNG, WebP, WAV, OGG, GLB, glTF, FBX를 지원합니다. 저장된 프로젝트 폴더로 복사하고 상대 경로를 기록합니다.

- 첫 이미지가 2D performer 프록시를 대체합니다.
- audio Event의 `asset_key`를 가져온 WAV/OGG key와 맞춥니다.
- GLB/glTF/FBX animation Event의 `payload.clip`을 감지된 clip 이름과 맞춥니다.
- 이름이 다르면 Alpha가 첫 clip을 보이는 fallback으로 재생하지만, 통합 전에 올바른 이름으로 수정해야 합니다.

먼저 **2D 스프라이트 데모**를 열면 내장 오리지널 CC0 8프레임 검사가 animation Event의
고정 tick에 따라 전환됩니다. Take A와 Take B는 같은 셀을 쓰지만 길이와 속도가 달라 캐릭터
모션에서도 차이를 볼 수 있습니다. ActionSpec의 `frame_count`와 `layout` 메타데이터는 재생에
사용되지만, 임의 spritesheet용 완전한 그래픽 자르기 UI는 아직 Alpha 범위 밖입니다.
JSON이나 Godot에서 최종 설정을 완성하세요.

## 8. Mixamo FBX 전체 절차

왼쪽 샘플에서 **3D FBX 데모**를 여세요. Mixamo FBX와 동일한 Godot UFBX 경로로
Quaternius의 CC0 휴머노이드, 스켈레톤, 메시, 11개 애니메이션 클립을 불러옵니다.
Adobe는 Mixamo 자산을 프로젝트에 사용하는 것은 허용하지만 원본 캐릭터나 애니메이션
파일 재배포는 허용하지 않습니다. 따라서 내장 데모는 Mixamo 자산이 아닙니다.
확인 후 본인 Adobe ID로 FBX를 다운로드해 교체하세요.

1. Mixamo에서 캐릭터와 애니메이션을 선택합니다.
2. Format은 **FBX Binary**, 캐릭터 포함 시 **With Skin**.
3. 30 FPS를 유지해도 됩니다. Action Event는 고정 60 ticks를 사용합니다.
4. Action Director에서 3D 샘플을 열고 `.adproject`를 저장합니다.
5. **에셋 가져오기**에서 FBX를 선택합니다. Godot 4.7 UFBX가 skeleton, mesh, animation을 감지합니다.
6. Asset Tooltip에서 clip 이름을 확인해 animation Payload에 입력합니다.

```json
{
  "clip": "mixamo.com",
  "speed": 1.0,
  "blend": 0.08,
  "reverse": false
}
```

7. 재생하여 clip, 방향, 크기, 실제 이동을 확인합니다.

손상된 FBX는 거부됩니다. 캐릭터+애니메이션 FBX는 바로 재생할 수 있지만 motion-only FBX에는 호환 skeleton 또는 외부 retarget 과정이 필요합니다. 서로 다른 skeleton의 자동 retarget은 포함되지 않습니다.

## 9. Track 사용법

현재 Alpha GUI는 유형별 Track/Event 추가·삭제, 재생 헤드에 Event 추가, Take 복제, Event type/actor/시작·끝 tick/Payload JSON 변경을 지원합니다. Track 이름을 누르면 전체 Track을 선택하며 Event/Track 삭제는 실행 취소할 수 있습니다. Marker/Branch는 10절의 JSON 절차로 만듭니다. 아래 설명은 ActionSpec 형식 참고이기도 합니다.

- **Animation**: `clip`, `speed`, `blend`, `reverse`. 시각적 애니메이션 길이와 게임 Event 길이는 별도로 설계합니다.
- **Window**: 모든 Window는 시작 tick에 일반 `event_fired`를 한 번 발행합니다. `kind: "cancel"`만 추가로 `cancel_window_changed(tag, true/false)` 열림/닫힘을 가집니다. 다른 Window에는 전용 close signal이 없으므로 필요하면 Host가 `end_tick`으로 종료를 예약합니다.
- **Hitbox/Hurtbox**: Hitbox만 `hitbox_opened/closed`를 가집니다. Hurtbox는 시작 시 일반 `event_fired`만 있고 전용 close signal은 없습니다. 충돌, Hurtbox 종료, 피해는 게임이 관리합니다.
- **Motion**: 2D `[x,y]`, 3D `[x,y,z]` `delta`와 `local`/`world` `space`를 사용합니다.
- **Feel**: hit stop, shake, slow motion, flash의 시점과 강도 요청입니다.
- **Audio/VFX**: `asset_key`를 Godot AudioStream/PackedScene에 대응합니다.
- **Camera**: 추적, 전환, zoom/FOV, shake 요청을 Camera Adapter로 보냅니다.
- **Game event**: 투사체 생성, 스태미나 소비 등 기존 게임에 명시적으로 요청합니다.
- **Note**: 검토용 메모이며 필수 게임 로직에 사용하지 않습니다.

## 10. 고급 JSON 편집과 Take A/B

### GUI가 아직 지원하지 않는 Marker/Branch 만들기

1. 가장 가까운 내장 `.action.json`을 복사하고 빈 파일에서 시작하지 않습니다.
2. Track/Event는 Timeline에서 만듭니다. Marker/Branch를 추가·삭제·편집할 때만 파일을 닫고 Text editor를 사용합니다.
3. 모든 Take, Track, Event, Marker, Branch에 고유 ID를 주고 `start_tick <= end_tick <= duration_ticks`를 지킵니다.
4. 한 ActionSpec에 2D/3D 좌표를 섞지 않습니다. Loader는 2D의 3개 값 Motion/shape vector 또는 `box`/`sphere`, 3D의 2개 값 vector 또는 `rect`/`circle`을 거부합니다. `capsule`은 두 Dimension에서 쓸 수 있지만 vector 값 개수는 해당 Dimension과 맞아야 합니다. Branch target marker는 `at_tick` 뒤에 둡니다.
5. JSON 저장 후 Action Director의 **열기**로 다시 불러옵니다. 중복 UUID, 손상 JSON, 잘못된 범위, 뒤쪽이 아닌 Branch는 거부됩니다.
6. 성공 후 GUI에서 Track/Event 작성, Event type/actor/tick/Payload 조정, Take 복제, A/B 리허설, 내보내기를 합니다.

Alpha는 외부 파일 변경을 감시하지 않습니다. Text 편집 후 JSON을 다시 여세요. `.adproject`의 내장 복구본도 외부 JSON 수정으로 자동 갱신되지 않습니다.

### 비교 방법

1. 정상적으로 끝나는 기준 Take를 만듭니다.
2. **Take 복제**로 독립 버전을 만듭니다.
3. 기준 Take 탭을 선택하고 **비교 대상**에서 원하는 다른 Take를 지정합니다. Take가 3개 이상이어도 다음 탭만 비교하도록 제한되지 않습니다.
4. “반응 가능한가?”, “충격이 충분히 무거운가?”처럼 질문 하나를 정합니다.
5. 한 번에 관련 변수만 수정합니다: startup/speed, motion/hitbox, hit stop/shake, recovery/cancel.
6. 같은 시작 조건으로 재생하고 첫 차이, 전체 길이, 이동, active, cancel을 확인합니다.
7. 선택하지 않은 Take도 검토와 롤백을 위해 남깁니다.

내장 검격은 방법 예시일 뿐 밸런스 추천이 아닙니다. Take A는 72 ticks, Take B는 60 ticks이며 B가 더 빠르고 멀리 이동하고 강한 shake와 block-recovery 분기를 가집니다.

## 11. 결과와 분기

2D Hitbox 활성 중 왼쪽 클릭은 `hit`, 오른쪽 클릭은 `block`입니다. 닫힐 때까지 결과가 없으면 같은 종료 tick의 분기를 판단하기 전에 `miss`가 됩니다.

```json
{
  "id": "on-block",
  "at_tick": 24,
  "condition": {"kind": "block", "value": true},
  "target_marker": "recovery"
}
```

조건은 `hit`, `block`, `miss`, `grounded`, `airborne`, `charge_tier`, `custom_bool`입니다. 분기는 이후 Marker로만 이동하며 반복이나 임의 코드를 실행할 수 없습니다. 건너뛴 Hitbox와 Cancel window는 점프 전에 닫힙니다.

## 12. 실제 적용 예

- **경공격 위험도**: 빠른 startup+긴 recovery와 느린 startup+짧은 recovery를 비교하고 cancel window를 게임 상태 머신에 전달합니다.
- **3D 어깨 돌진**: Timeline toolbar에서 Motion/Hitbox를 선택하고 재생 헤드에 Event를 추가합니다. 실제 body, 가슴 Box hitbox, 접촉 hit stop/shake를 설정합니다.
- **차지 공격**: JSON으로 `charge_tier` Branch와 이후 Marker를 만들고 Play context에 tier를 전달합니다.
- **Boss 방어 반응**: JSON으로 hit/block/miss Branch 구조를 만든 뒤 각 반응을 설정합니다. AI와 피해는 게임에 남깁니다.

## 13. Godot 4.7 통합

1. `.action.json`을 내보냅니다.
2. `addons/action_director_runtime/`을 게임에 복사하고 Project Settings → Plugins에서 활성화합니다.
3. 로드하고 재생합니다.

```gdscript
var loaded := ActionSpecCodec.load_json("res://actions/sword.action.json")
if loaded.ok:
    $ActionDirectorPlayer.play(loaded.spec, "Take B", {
        "grounded": true,
        "charge_tier": 0
    })
```

`hitbox_opened/closed`, `motion_requested`, `cancel_window_changed`, `event_fired`를 기존 게임에 연결하고 충돌 확정 후 `report_outcome(event_id, "hit")` 또는 `"block"`을 호출합니다.

Runtime은 tick 순서, branch, cleanup을 담당합니다. 피해, 대상, 충돌 결과, 입력, 캐릭터 상태, AI, 네트워크는 게임이 담당합니다.

Lifecycle API는 제한적입니다. Hitbox는 `hitbox_opened/closed`, Cancel window는 `cancel_window_changed`를 가집니다. Hurtbox와 다른 Window는 시작 시 `event_fired`만 있습니다. 종료가 필요하면 Host가 `end_tick`으로 예약하거나 Runtime Adapter를 확장하세요.

## 14. 버전 관리와 협업

- `.action.json`을 Git에 커밋하고 필요하면 `.adproject`도 공유합니다.
- Take 이름은 `Fast Startup`, `Heavy Impact`처럼 의도를 표현합니다.
- 리뷰에는 startup, active, recovery, 전체 길이, 이동, hit stop, cancel 차이를 적습니다.
- 알 수 없는 Event는 경고와 함께 보존됩니다. 호환성을 확인하기 전에 삭제하지 마세요.
- 중복 UUID, 손상 JSON, 뒤쪽이 아닌 Branch는 거부됩니다. 검증을 우회하지 말고 원본을 수정합니다.

## 15. 키보드

| 작업 | 키 |
|---|---|
| 재생/일시정지 | Space |
| 이전/다음 tick | `,`/`.` |
| 초기화 | R |
| A/B 전환 | C |
| 실행 취소 | Ctrl/Cmd+Z |
| 다시 실행 | Ctrl/Cmd+Shift+Z, Windows Ctrl+Y |
| 저장 | Ctrl/Cmd+S |
| 타임라인 트랙 선택 | 타임라인 포커스 후 위/아래 방향키 |
| 트랙 이벤트 선택 | 타임라인 포커스 후 왼쪽/오른쪽 방향키 |
| Timeline 확대 | Ctrl/Cmd+휠 |
| 이동 | 눈금자 클릭 |
| Tutorial 스크롤 | Page Up/Down, Home, End |
| Tutorial 닫기 | Escape |

## 16. 문제 해결

- **가져오기를 할 수 없음**: 먼저 `.adproject`를 저장합니다.
- **FBX에 애니메이션이 없음**: FBX Binary, 캐릭터 통합 시 With Skin으로 다시 받습니다.
- **모델이 움직이지 않음**: Tooltip clip 이름과 `payload.clip`을 정확히 맞춥니다.
- **크기/방향 오류**: DCC 또는 Mixamo 원본 설정에서 수정합니다.
- **소리가 안 남**: WAV/OGG와 Event `asset_key` 대응을 확인합니다.
- **Branch가 실행되지 않음**: `at_tick` 전에 결과가 보고되었는지, target marker가 뒤에 있는지 확인합니다.
- **원본 JSON 이동**: `.adproject` 내장 ActionSpec을 열고 다시 내보내며 외부 Asset을 재지정합니다.
- **비정상 종료**: **복구**로 30초 autosave를 열고 정상 위치에 저장합니다.

## 17. Alpha 제한

GUI는 Track/Event 추가·삭제와 Event type/actor/tick/Payload 변경을 지원합니다. Marker/Branch는 `.action.json` 수동 편집이 필요합니다. 전용 열림/닫힘 signal은 Hitbox와 Cancel window만 있고 Hurtbox와 다른 Window는 시작 시 일반 Event만 있습니다. 자동 retarget, 완전한 spritesheet slicer, 참조 영상, contact sheet, waveform, transform keyframe도 아직 없습니다. 뼈대, skin, IK, model, 피해, AI, state, network를 제작하거나 관리하지 않습니다. macOS 공개 배포에는 Developer ID 서명과 notarization이 필요합니다.

같은 ActionSpec이 편집기와 Godot Runtime에서 고정 60 ticks, 동일한 Event 순서와 Branch/Cleanup 규칙으로 실행됩니다.
