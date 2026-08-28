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
- Starter deck plus reward cards: Slash / Ice Lance / Blood Pact
- Card block and healing effects
- Relics: Guardian Core / Iron Ring / Lucky Coin
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
- `1` / `2` / `3`: play the card in hand
- `E`: end turn

### Reward
- `1` / `2` / `3`: choose a card
- `B`: skip reward

### Shop
- `1` / `2` / `3`: buy an item
- `B`: return to map

### Event / Rest
- `1` / `2`: choose an event
- `1`: rest
- `B`: return to map

### Boss
- `1` / `2` / `3`: play a card
- `E`: boss turn
- `B`: finish after victory

Open the project with Godot 4.x and run `scenes/main.tscn`.


## Latest UI update

- Clickable card UI
- Card hover lift effect
- Enemy and hero HP bars
- Combat damage feedback
- Mouse-clickable map nodes and end-turn button

- Animated placeholder hero and enemy visuals
- Attack flash and floating damage numbers
- Fireball projectile visual effect
- Ice Lance projectile visual effect
- Card type visual styles and colored borders
- Attack / skill / power / status labels
- Fixed battle rendering indentation issue


## Playable prototype status

The current repository contains a complete vertical-slice prototype:

- Main menu and run restart
- Procedural node choices
- Normal and elite battles
- Turn-based card combat with energy, draw and discard
- Block, Weak, Vulnerable and Poison
- Card rewards and upgrades/removal
- Shops, events and rest nodes
- Relics and elite rewards
- Multi-phase bosses
- Mouse-clickable battle cards, map nodes and boss cards
- Combat feedback, health bars, hover effects and projectile visuals

## Run

Open the project with Godot 4.x and run the configured main scene.

## Phase 2 — Presentation layer complete

- Production asset folder structure for art and audio
- Central visual theme API
- Replaceable character art layer
- Layered dark-fantasy background and framed panels
- Unified card colors and presentation hooks
- Audio manager interface ready for SFX assets
- Existing hover, projectile, damage, HP-bar and combat feedback retained

The prototype remains dependency-free: external PNG/OGG assets can now be added without rewriting gameplay logic.
