# Card RPG

A Godot 4 roguelike deck-building prototype.

## Current features

- Main menu and run persistence
- Seven-floor branching adventure map
- Battle / Elite / Shop / Event / Rest / Boss nodes
- Three choices per normal map row
- Guaranteed event, rest, shop and elite opportunities on the middle route
- Turn-based combat with draw/discard piles
- Energy system and card costs
- Expanded reward pool with attack, defense, draw, healing, debuff and poison archetypes
- Card block and healing effects
- Relics: Guardian Core / Iron Ring / Lucky Coin / War Drum / Vampire Fang
- Six normal enemy archetypes plus dedicated elite encounters
- Scaling enemies and dedicated boss encounters
- Gold economy and shop purchases
- Random shrine events
- Rest node healing
- Victory / defeat states
- JSON-compatible persistent run data

## Controls

### Map
- `1` - `5`: choose a map node
- `R`: start a new run

### Battle
- `1` / `2` / `3` / `4` / `5`: play a card in hand
- `E`: end turn

### Reward
- `1` / `2` / `3`: choose a card
- `B`: skip reward

### Shop
- `1` / `2` / `3`: buy an item
- `4`: upgrade a card
- `5`: remove a card
- `B`: return to map

### Event / Rest
- `1` / `2`: choose an event
- `1`: rest
- `B`: return to map

### Boss
- `1` / `2` / `3` / `4` / `5`: play a card
- `E`: boss turn
- `B`: finish after victory

Open the project with Godot 4.x and run `scenes/main.tscn`.

## Presentation layer

- Clickable card UI
- Card hover lift effect
- Enemy and hero HP bars
- Combat damage feedback
- Mouse-clickable map nodes and end-turn button
- Animated procedural hero and enemy visuals
- Attack flash and floating damage numbers
- Fireball projectile visual effect
- Ice Lance projectile visual effect
- Card type visual styles and colored borders
- Attack / skill / power / status labels
- Production asset folder structure for art and audio
- Central visual theme API
- Replaceable character art layer
- Layered dark-fantasy background and framed panels
- Audio manager interface ready for SFX assets

## Vertical slice status

The repository contains a complete playable vertical slice: map routing, normal and elite battles, card combat, rewards, upgrades/removal, shops, events, rest, relics, multi-phase bosses, persistence and presentation feedback are all wired together.

## Phase 3 — Content expansion complete

Phase 3 increases replayability without introducing external dependencies:

- Reward pool expanded from 10 to 18 base cards
- Added Quick Jab / Fortify / Poison Dart / Cleave / Siphon / Adrenaline / Shatter / Riposte, each with an upgrade path
- Added Plague Witch / Blood Hound / Stone Warden enemy archetypes
- Enemy intent patterns now cover poison, guard and weakening behaviors across the expanded roster
- Existing relic and combat systems remain compatible with the new content
- Save format remains JSON-compatible and backward compatible

The next development layer can focus on production art/audio, richer boss mechanics, balance telemetry and a larger event/relic pool.

## Run

Open the project with Godot 4.x and run the configured main scene.
