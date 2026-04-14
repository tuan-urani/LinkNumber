# UI Workflow

## Game Menu
**Path**: lib/src/ui/game_menu

### 1. Description
Goal: Show a focused landing screen that leads users into the Link Number game.
Features:
- Splash routes to this menu screen as the first destination.
- Displays only one game card (Link Number) with localized content.
- Navigates to Link Number via GetX route.

### 2. UI Structure
- Screen: `GameMenuPage`
- Components:
- `GameMenuHeader`: menu title and subtitle.
- `GameMenuGameCard`: Link Number entry card with icon, description, and action label.

### 3. User Flow & Logic
1. User opens app and sees splash.
2. After splash delay, app navigates to `GameMenuPage`.
3. User taps the Link Number card.
4. App pushes `LinkNumberPage`.

### 4. Key Dependencies
- `GameMenuController`: source of menu item metadata (Link Number only).
- `AppPages`: game menu route registration and Link Number route mapping.
- `LocaleKey`, `lang_en.dart`, `lang_ja.dart`: menu localization keys and values.

## Link Number
**Path**: lib/src/ui/link_number

### 1. Description
Goal: Provide a puzzle game where users connect adjacent matching numbers to clear goals before moves run out.
Features:
- Drag gesture path selection across adjacent matching tiles.
- Two goal modes: value-count goals and score goals.
- Move counter with win/lose conditions.
- Clear path and restart actions for quick retry.
- In-game skill system with coin economy.
- Arcade feedback effects: animated path glow, merge burst, floating score text, and tile pop.

### 2. UI Structure
- Screen: `LinkNumberPage`
- Components:
- `LinkNumberGoalPanel`: left panel for level/mode, goal, moves, and quick actions.
- `LinkNumberBoard`: center board for drag path, skill tap actions, and result overlay.
- `LinkNumberHudPanel`: right panel for stars, coins, reward button, and skills.
- Mobile responsive behavior:
  - Top panel height is adaptive by screen height (percentage-based with min/max clamp).
  - Compact HUD panel uses internal vertical scroll to avoid overflow on short screens.
  - Skill selection hint is hidden in compact HUD to prioritize core controls.

### 3. User Flow & Logic
1. User enters Link Number from the game menu.
2. User drags across adjacent tiles to form a path using rules:
- same value (`x -> x`) or forward double (`x -> 2x`).
- reverse chain (`x -> x/2`) is not allowed.
3. Engine validates path and merges the whole path into one result tile.
- The result tile is calculated from path sum, then rounded up to nearest power of 2.
- Formula: `mergedValue = nextPowerOfTwo(sum(pathValues))`.
- Examples: `4 -> 4 -> 4 -> 4 = 16`, `4 -> 4 -> 4 -> 4 -> 4 = 32`, `4 -> 4 -> 4 -> 4 -> 4 -> 4 = 32`.
4. Merge turn plays feedback animation:
- path line has moving glow markers while dragging.
- successful merge plays burst ring + floating `+score` at merge point.
- after pan end, path tiles dissolve sequentially as a chain reaction (from path start to end).
- merge commit delay is dynamic by path length (`~220ms + 65ms * (pathLength - 1)`, capped) so chain dissolve can be seen clearly.
- changed tiles play pop scale effect with slight delay (`~190ms`) after merge burst starts.
5. Board applies gravity and respawns new values after each valid merge.
6. Moves decrease by 1 after each completed turn.
7. If current level goal is completed, game moves to win state.
8. If moves reach zero before completing goal, game moves to lose state.
9. User can clear current path or restart to play again.

### 4. Goal Modes
1. `GoalCount` (value + required count):
- Example targets: `4 x13`, `8 x20`, `16 x25`.
- Progress is counted by the number of cleared tiles matching each target value.
- Win condition: all target counts are completed.
2. `GoalScore` (score target):
- Example target: `500`.
- Score increases by total value cleared in each turn (or skill-based clear when applicable).
- Win condition: current score reaches or exceeds target score.

### 5. Difficulty System (Level-based progression)
1. Tracking fields:
- `currentLevel`: current level number (starting from 1).
- `maxUnlockedLevel`: highest level player has unlocked.
2. Difficulty stages by `currentLevel`:
- Stage 1 (`Level 1 - 5`): onboarding.
- Stage 2 (`Level 6 - 12`): easy.
- Stage 3 (`Level 13 - 20`): normal.
- Stage 4 (`Level 21 - 35`): hard.
- Stage 5 (`Level 36 - 50`): expert.
- Stage 6 (`Level 51+`): infinite/endgame.
3. Concrete level plan (`Level 1 - 20`):

| Level | Goal Mode | Moves | Target |
|---|---|---:|---|
| 1 | GoalCount | 16 | `4x8, 8x7` |
| 2 | GoalCount | 15 | `4x9, 8x8` |
| 3 | GoalCount | 15 | `4x10, 8x9` |
| 4 | GoalCount | 14 | `4x11, 8x10` |
| 5 | GoalCount | 14 | `4x12, 8x10` |
| 6 | GoalCount | 14 | `4x12, 8x11, 16x3` |
| 7 | GoalCount | 13 | `4x12, 8x12, 16x4` |
| 8 | GoalScore | 13 | `360` |
| 9 | GoalCount | 13 | `4x13, 8x12, 16x5` |
| 10 | GoalCount | 13 | `4x13, 8x13, 16x5` |
| 11 | GoalScore | 12 | `390` |
| 12 | GoalCount | 12 | `4x14, 8x13, 16x6` |
| 13 | GoalCount | 12 | `4x14, 8x14, 16x7` |
| 14 | GoalScore | 12 | `420` |
| 15 | GoalCount | 11 | `4x15, 8x14, 16x8` |
| 16 | GoalScore | 11 | `450` |
| 17 | GoalCount | 11 | `4x15, 8x15, 16x8` |
| 18 | GoalScore | 11 | `470` |
| 19 | GoalCount | 11 | `4x16, 8x15, 16x9` |
| 20 | GoalScore | 10 | `500` |

4. Generation template for `Level 21+`:
- Stage 4 (`21 - 35`):
  - Moves baseline: `10`.
  - Recovery levels: `25` and `30` use `11` moves.
  - Mode pattern: `Score -> Count -> Score` (repeat).
  - Score target: start at `520`, increase `+20` per level where mode is `GoalScore`.
  - Count target sum: start near `45`, increase `+2` per level where mode is `GoalCount`.
- Stage 5 (`36 - 50`):
  - Moves baseline: `9`.
  - Recovery levels: `40` and `45` use `10` moves.
  - Mode pattern: `Score -> Score -> Count` (repeat).
  - Score target: start at `800`, increase `+25` per level where mode is `GoalScore`.
  - Count target sum: start near `58`, increase `+2` per level where mode is `GoalCount`.
- Stage 6 (`51+`):
  - Every `10` levels is one season.
  - Season multiplier on goals: `+4%` each season, capped at `1.8x`.
  - Moves floor remains `8`; first level of each season is a recovery level (`+1` move from current baseline).
5. Progression rule:
- Difficulty is recalculated only when entering a new level.
- Goal mode and level config are locked during that level and do not change mid-level.

### 6. Difficulty Safety Standards (must pass)
1. Hard limits (never violate):
- `moves` must stay in range `8..16` (no level is allowed to have `moves <= 0`).
- `GoalCount` total required clears must satisfy:
  - `sumRequired <= floor(moves * clearPerMoveCap)`
  - Recommended `clearPerMoveCap` by stage:
    - Stage 1: `2.8`
    - Stage 2: `3.0`
    - Stage 3: `3.2`
    - Stage 4: `3.4`
    - Stage 5: `3.6`
    - Stage 6: `3.8`
- `GoalScore` target must satisfy:
  - `scoreTarget <= floor(moves * scorePerMoveCap)`
  - Recommended `scorePerMoveCap` by stage:
    - Stage 1: `28`
    - Stage 2: `32`
    - Stage 3: `36`
    - Stage 4: `40`
    - Stage 5: `44`
    - Stage 6: `48`
2. Expected win-rate target (first attempt):
- Stage 1: `70% - 85%`
- Stage 2: `60% - 75%`
- Stage 3: `52% - 65%`
- Stage 4: `42% - 55%`
- Stage 5: `32% - 45%`
- Stage 6: `28% - 40%`
3. Auto-balance rule when a level is out of target:
- Compute from real data window: at least `200` attempts/level.
- Cooldown after each balance patch: at least `100` new attempts before next patch.
- If win rate is below stage lower bound:
  1. Increase `moves` by `+1` (up to max 16), else
  2. Reduce goal by `8%`, else
  3. Ease spawn mix slightly for that level.
- If win rate is above stage upper bound:
  1. Decrease `moves` by `-1` (down to min 8), else
  2. Increase goal by `8%`, else
  3. Harder spawn mix slightly for that level.
- Each patch can apply only one adjustment step to avoid oscillation.
4. Release gate:
- A level config cannot be published if it breaks hard limits.
- A level config cannot be published if win rate remains outside target range after one auto-balance cycle.

### 7. Goal Mode Selection Policy (GoalCount vs GoalScore)
1. Base selection by level stage:
- Stage 1 (`Level 1 - 5`): `GoalCount` only.
- Stage 2 (`Level 6 - 12`): cycle `Count, Count, Score` (repeat).
- Stage 3 (`Level 13 - 20`): cycle `Count, Score` (repeat).
- Stage 4 (`Level 21 - 35`): cycle `Score, Count, Score` (repeat).
- Stage 5 (`Level 36 - 50`): cycle `Score, Score, Count` (repeat).
- Stage 6 (`Level 51+`): cycle `Score, Score, Count` (repeat).
2. Fairness guards:
- Do not allow the same goal mode more than 2 consecutive levels.
- If player fails 2 consecutive `GoalScore` levels, force next level to `GoalCount`.
- If player wins 3 consecutive `GoalCount` levels, prioritize `GoalScore` for next level.
3. UX guard:
- Goal mode is locked when level starts and must not switch during the same level.
- Goal widget in HUD must render only the active mode:
  - `GoalCount`: value chips with remaining counts.
  - `GoalScore`: single score progress target.
- Left goal panel includes `Current` preview card:
  - While user is dragging a valid chain (`path length >= 2`), show `nextPowerOfTwo(sum(pathValues))`.
  - When no active chain, show `-`.

### 8. Skill Rules
1. `Skill 1` - Break Tile (`cost: 200 coin`)
- User selects the skill, then taps one tile.
- The selected tile is removed immediately, then gravity + respawn are applied.
- Goal/score progress updates as a normal clear.
- This action does not consume a move.
2. `Skill 2` - Swap 2 Tiles (`consumable`, uses inventory count)
- User selects the skill, then picks tile A and tile B.
- The values at tile A and tile B are swapped.
- No tile is removed by the swap action itself.
- This action does not consume a move.
- If player has 0 swap items, skill is unavailable.
3. Removed skill:
- Previous `Skill 3` (shuffle) is removed from scope and must not appear in UI/spec.

### 9. Economy & HUD
- Coin balance is displayed on the right-side HUD.
- Skill 1 spends coin directly on use.
- Skill 2 shows remaining consumable quantity as a badge.
- Reward ad button can grant extra coin (for example `+200`).
- Skill buttons must reflect state: available, insufficient coin, or out of consumable count.

### 10. Key Dependencies
- `LinkNumberEngine`: core game state transitions and rule validation.
- `LinkNumberController`: state bridge between engine and UI.
- `LocaleKey`, `lang_en.dart`, `lang_ja.dart`: localized game copy.
- `AppPages`: route registration and navigation entry.
