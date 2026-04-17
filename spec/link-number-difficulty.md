# Link Number - Tài Liệu Độ Khó (Theo Code Hiện Tại)

## 1. Mục tiêu tài liệu
Tài liệu này giải thích chi tiết độ khó của game Link Number:
- Khó ở đâu.
- Khó như thế nào theo từng giai đoạn.
- Cơ chế sinh level (đặc biệt từ level 21 trở đi).
- Ví dụ minh hoạ cụ thể để dễ kiểm tra và cân bằng.

Nguồn tham chiếu chính:
- `lib/src/ui/link_number/interactor/link_number_engine.dart`
- `lib/src/ui/link_number/interactor/link_number_snapshot.dart`

## 2. Tổng quan nhanh về độ khó
Độ khó được tạo từ 6 lớp:

| Lớp độ khó | Được quyết định bởi | Tác động lên trải nghiệm |
|---|---|---|
| Áp lực mục tiêu | `GoalCount` hoặc `GoalScore`, target/move | Người chơi phải đạt nhiều hơn trong ít lượt hơn |
| Áp lực lượt đi | `moves` giảm dần theo stage/level | Sai 1-2 nước sẽ đắt hơn ở late game |
| Áp lực spawn | Trọng số sinh số mới theo stage (`2..64`) | Càng về sau càng nhiều số lớn, khó nối chuỗi hữu ích |
| Áp lực luật nối | Chỉ cho `x -> x` hoặc `x -> 2x` | Chuỗi hợp lệ hiếm dần khi board phân mảnh |
| Áp lực chuyển mode | Pattern mode + fairness guards | Người chơi phải thay đổi tư duy Count/Score liên tục |
| Áp lực ngẫu nhiên có kiểm soát | Spawn anti-cluster + anti-bias + playable-pair guard | Tránh board chết cứng nhưng vẫn giữ độ thách thức |

Thông số global hiện tại:
- `kDifficultyScalar = 1.0`, nghĩa là game đang chạy ở mức chuẩn (không buff/nerf toàn cục).

## 3. Khung stage và quy tắc chính

| Stage | Range level | Định hướng độ khó |
|---|---|---|
| Stage 1 | 1-5 | Onboarding, mục tiêu nhẹ, nhiều moves |
| Stage 2 | 6-12 | Easy, bắt đầu trộn Count/Score |
| Stage 3 | 13-20 | Normal, tăng target và giảm moves rõ rệt |
| Stage 4 | 21-35 | Hard, auto-generate, pattern Score thiên nhiều hơn |
| Stage 5 | 36-50 | Expert, Score xuất hiện dày hơn |
| Stage 6 | 51+ | Endgame theo season, có xu hướng bão hoà ở very late game |

## 4. Level 1-20 (preset hard-code)
Level 1-20 dùng preset cố định trong `_presetLevels`.

Lưu ý:
- Cột `Áp lực/move` chỉ để so sánh xu hướng trong cùng mode.
- `GoalCount`: `Áp lực/move = tổng required / moves`.
- `GoalScore`: `Áp lực/move = scoreTarget / moves`.

| Level | Stage | Mode | Moves | Target | Tổng mục tiêu | Áp lực/move |
|---:|---:|---|---:|---|---:|---:|
| 1 | 1 | GoalCount | 16 | `4x8, 8x7` | 15 | 0.94 |
| 2 | 1 | GoalCount | 15 | `4x9, 8x8` | 17 | 1.13 |
| 3 | 1 | GoalCount | 15 | `4x10, 8x9` | 19 | 1.27 |
| 4 | 1 | GoalCount | 14 | `4x11, 8x10` | 21 | 1.50 |
| 5 | 1 | GoalCount | 14 | `4x12, 8x10` | 22 | 1.57 |
| 6 | 2 | GoalCount | 14 | `4x12, 8x11, 16x3` | 26 | 1.86 |
| 7 | 2 | GoalCount | 13 | `4x12, 8x12, 16x4` | 28 | 2.15 |
| 8 | 2 | GoalScore | 13 | `360` | 360 | 27.69 |
| 9 | 2 | GoalCount | 13 | `4x13, 8x12, 16x5` | 30 | 2.31 |
| 10 | 2 | GoalCount | 13 | `4x13, 8x13, 16x5` | 31 | 2.38 |
| 11 | 2 | GoalScore | 12 | `390` | 390 | 32.50 |
| 12 | 2 | GoalCount | 12 | `4x14, 8x13, 16x6` | 33 | 2.75 |
| 13 | 3 | GoalCount | 12 | `4x14, 8x14, 16x7` | 35 | 2.92 |
| 14 | 3 | GoalScore | 12 | `420` | 420 | 35.00 |
| 15 | 3 | GoalCount | 11 | `4x15, 8x14, 16x8` | 37 | 3.36 |
| 16 | 3 | GoalScore | 11 | `450` | 450 | 40.91 |
| 17 | 3 | GoalCount | 11 | `4x15, 8x15, 16x8` | 38 | 3.45 |
| 18 | 3 | GoalScore | 11 | `470` | 470 | 42.73 |
| 19 | 3 | GoalCount | 11 | `4x16, 8x15, 16x9` | 40 | 3.64 |
| 20 | 3 | GoalScore | 10 | `500` | 500 | 50.00 |

Nhận xét nhanh:
- Từ level 1 đến 20, xu hướng chính là `moves` giảm và `target` tăng.
- `GoalScore` ở level cao có áp lực rất lớn vì target/move tăng mạnh.

## 5. Level 21+ (auto-generate) sinh như thế nào
Nếu không tìm thấy trong preset, engine sinh config theo công thức.

### 5.1 Quy trình sinh config
1. Xác định `baseMode` theo stage pattern.
2. Áp `fairness guards` để ra `resolvedMode` thực tế.
3. Tính `moves` theo stage.
4. Nếu mode là `GoalScore`: tính `scoreTarget`.
5. Nếu mode là `GoalCount`: tính `totalRequired` rồi chia về các mốc value.
6. Gán `spawnWeights` theo stage.

### 5.2 Pattern mode theo stage

| Range level | Pattern base |
|---|---|
| 21-35 | `Score -> Count -> Score` (lặp) |
| 36-50 | `Score -> Score -> Count` (lặp) |
| 51+ | `Score -> Score -> Count` (lặp) |

`Fairness guards` có thể đổi mode thực tế:
- Fail `GoalScore` liên tiếp >= 2: ép level kế tiếp về `GoalCount`.
- Win `GoalCount` liên tiếp >= 3: ưu tiên `GoalScore`.
- Không cho cùng mode quá 2 level liên tiếp.

### 5.3 Công thức moves

| Range level | Rule moves |
|---|---|
| 21-35 | Base `10`, riêng `25` và `30` là `11` (recovery) |
| 36-50 | Base `9`, riêng `40` và `45` là `10` (recovery) |
| 51+ | Theo season, có sàn `8`; level đầu mỗi season được `+1 move` recovery |

Season được tính:
- `season = ((level - 51) ~/ 10) + 1`
- `levelInSeason = (level - 51) % 10`

### 5.4 Công thức target

#### GoalScore
- `21-35`: bắt đầu `520`, mỗi lần gặp level Score tăng `+20`.
- `36-50`: bắt đầu `800`, mỗi lần gặp level Score tăng `+25`.
- `51+`:
  - `baseScore = 980 + 30 * levelInSeason`
  - `multiplier = min(1.8, 1 + 0.04 * season)`
  - `scoreTarget = round(baseScore * multiplier)`

#### GoalCount
- `21-35`: tổng required bắt đầu `45`, mỗi lần gặp Count tăng `+2`.
- `36-50`: bắt đầu `58`, mỗi lần gặp Count tăng `+2`.
- `51+`:
  - `baseCount = 66 + 2 * levelInSeason`
  - `multiplier = min(1.8, 1 + 0.04 * season)`
  - `totalRequired = round(baseCount * multiplier)`

#### Chia tổng required về từng mốc value
- Từ level 21: dùng `4, 8, 16`.
- Từ level 28: thêm `32`.
- Từ level 45: thêm `64`.
- Engine chia theo tỉ lệ và chỉnh vòng lặp để tổng cuối cùng khớp `totalRequired`.

## 6. Ví dụ minh hoạ cụ thể

### Ví dụ A: Level 25 (trường hợp Count)
- Stage 4.
- Moves: `11` (recovery của Stage 4).
- Pattern base tại 25 là `Count`.
- Tổng required Count tại mốc này: `47`.
- Với bộ value `4,8,16`, chia ra thực tế:
  - `4x16, 8x18, 16x13` (tổng 47).

### Ví dụ B: Level 40 (trường hợp Score)
- Stage 5.
- Moves: `10` (recovery của Stage 5).
- Pattern base tại 40 là `Score`.
- Score target tại 40: `875`.
- Áp lực score/move: `87.5`.

### Ví dụ C: Level 100 (trường hợp Score)
- Stage 6, season 5, `levelInSeason = 9`.
- Multiplier: `1.20`.
- Base score: `1250`.
- Score target: `1500`.
- Moves: `8` (không phải recovery level).

### Ví dụ D: Level 281 (trường hợp Count)
- Stage 6, season 24, `levelInSeason = 0`.
- Multiplier đã chạm trần `1.8`.
- Base count: `66`, total required: `119`.
- Vì `level >= 45`, bộ value gồm `4,8,16,32,64`.
- Một phân bổ hợp lệ theo thuật toán hiện tại:
  - `4x39, 8x44, 16x19, 32x12, 64x5`.
- Moves: `9` (recovery level đầu season).

## 7. Random số mới sau merge: khó ở chỗ nào

Sau mỗi merge hợp lệ:
1. Xoá/gộp chuỗi.
2. `gravity`.
3. Spawn ô mới vào vị trí `0`.
4. Nếu số cặp chơi được < 4 thì inject cặp đảm bảo.

### 7.1 Trọng số spawn cơ sở theo stage
Đây là trọng số cơ sở trước khi anti-cluster điều chỉnh.

| Stage | 2 | 4 | 8 | 16 | 32 | 64 |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 40 | 32 | 20 | 8 | - | - |
| 2 | 34 | 30 | 24 | 10 | 2 | - |
| 3 | 28 | 28 | 26 | 14 | 4 | - |
| 4 | 22 | 24 | 28 | 18 | 6 | 2 |
| 5 | 16 | 22 | 30 | 20 | 9 | 3 |
| 6 | 12 | 20 | 30 | 23 | 11 | 4 |

### 7.2 Anti-cluster và anti-bias
Mỗi ô spawn:
- Engine random 5 candidate theo trọng số.
- Chấm điểm từng candidate:
  - Điểm nền theo trọng số.
  - Trừ phạt nếu hàng xóm cùng số nhiều.
  - Trừ phạt nếu value đó đang quá nhiều trên board.
  - Nếu hàng xóm cùng số >= 3 thì trừ cực mạnh.
- Chọn candidate có điểm cao nhất.

Ý nghĩa:
- Không cho board bị "đồng màu" quá nhanh.
- Vẫn giữ cảm giác random nhưng giảm trường hợp quá dễ hoặc quá vô lý.

## 8. Vì sao tăng số lớn lại khó hơn
Khi tỉ lệ `16/32/64` tăng:
- Chuỗi `x -> x` hoặc `x -> 2x` khó kéo dài hơn.
- Board dễ phân mảnh thành cụm khó ăn khớp.
- Nước đi "đúng mục tiêu" giảm, đặc biệt với level Count đang cần gom value cụ thể.
- Sai một lượt ở mốc moves thấp gây mất nhịp rất lớn.

## 9. Bão hoà độ khó ở endgame (có thật)
Ở Stage 6 rất cao level, độ khó có xu hướng bão hoà vì:
- `moves` chạm sàn `8` (trừ level recovery là `9`).
- `multiplier` target bị cap ở `1.8x`.
- Spawn profile Stage 6 là cố định, không tăng thêm theo level.

### Ví dụ score target cùng vị trí trong season

| Level | Season | Multiplier | Moves | Score target (khi mode là Score) |
|---:|---:|---:|---:|---:|
| 100 | 5 | 1.20 | 8 | 1500 |
| 130 | 8 | 1.32 | 8 | 1650 |
| 160 | 11 | 1.44 | 8 | 1800 |
| 190 | 14 | 1.56 | 8 | 1950 |
| 220 | 17 | 1.68 | 8 | 2100 |
| 250 | 20 | 1.80 (cap) | 8 | 2250 |
| 280 | 23 | 1.80 (cap) | 8 | 2250 |

Kết luận:
- Sau khi chạm cap (từ season 20, bắt đầu level 241), độ khó không tăng vô hạn.
- Nó chuyển sang dạng plateau + dao động theo vị trí trong season.

## 10. Checklist dùng khi cân bằng độ khó
1. Kiểm tra target/move của level mới có nhảy quá gắt so với level trước không.
2. Kiểm tra tỷ lệ xuất hiện `32/64` có làm đứt mạch chơi quá nhiều không.
3. Đảm bảo level Count không yêu cầu quá nhiều value hiếm trong moves thấp.
4. Kiểm tra tỷ lệ win first-attempt theo stage.
5. Kiểm tra số lần board gần dead-end dù có playable-pair guard.
6. Theo dõi chuỗi fail của mode Score để tránh tạo "nút thắt" liên tiếp.
7. Với level rất cao, cân nhắc mở rộng thêm cơ chế nếu muốn tránh plateau.
8. Khi chỉnh độ khó, ưu tiên thay đổi từng biến nhỏ để dễ đo tác động.
