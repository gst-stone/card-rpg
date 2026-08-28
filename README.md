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
