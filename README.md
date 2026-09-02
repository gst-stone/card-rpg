# My Little Shop 🏪

A lightweight **shop-management / tycoon game** built with Godot 4.x.

The project evolved from a card-RPG prototype into a small management game designed around a simple loop, procedural visuals, no runtime asset dependency, and future mobile / WeChat mini-game adaptation.

## v1.0 — Playable milestone ✅

**Stock → price → open → serve customers → earn → settle → upgrade → unlock → repeat.**

v1.0 includes:

- 8 products with level-based unlocks
- 4 customer archetypes with different budgets and preferences
- 3 suppliers with different economics
- Dynamic daily demand and market events
- Adjustable selling prices
- Staff hiring and operating costs
- Store expansion and shelf capacity
- Customer movement, patience and lost sales
- Reputation and XP progression
- Daily settlement screen
- Persistent JSON save/load
- Floating sale and level-up feedback
- 4 milestone missions with rewards
- Lifetime revenue / customer statistics
- Best-day revenue record
- Mouse, keyboard and touch-friendly controls
- Procedural UI with no third-party runtime dependencies

## Economy

### Suppliers

| Supplier | Purchase | Effect |
|---|---:|---|
| Local | 100% | Stable |
| Wholesale | 88% | Cheaper stock |
| Premium | 108% | Better preference matching |

### Market events

- **Rainy day** — demand -10%
- **Weekend rush** — demand +20%
- **Local festival** — demand +12%
- **Supplier sale** — realized profit +10%
- **Heat wave** — demand -4%
- **Normal market** — no modifier

### Customers

| Type | Preference | Budget | Patience |
|---|---|---:|---:|
| Worker | quick | 18g | 8s |
| Parent | healthy | 22g | 9s |
| Student | snack | 14g | 7s |
| Neighbor | daily | 12g | 8.5s |

## Progression

Customer profit generates XP. Leveling increases shelf capacity and unlocks more products.

Milestones:

- **First Sale** — serve 5 customers → 50g
- **Busy Shop** — serve 25 customers → 100g
- **Popular Store** — reach 70 reputation → 150g
- **Big Day** — reach 150g revenue in one day → 120g

## Controls

- **Mouse / touch** — buttons and product cards
- **Space** — open / close shop
- **1-8** — restock products
- **N** — settle / continue to next day
- **S** — change supplier
- **H** — hire staff
- **- / +** — change selling price
- **U** — expand store
- **F5** — save
- **F9** — load
- **F10** — reset save

## Project history

### v0.3 — Customer simulation ✅
Customer types, preferences, budgets, patience and inventory capacity.

### v0.4 — Store layout ✅
Physical shop floor, shelves, entrance, checkout, movement and reputation.

### v0.5 — Deeper management ✅
Suppliers, popularity, market events, staff and operating costs.

### v0.6 — Persistence & feedback ✅
Save/load, daily settlement, floating feedback and touch-friendly controls.

### v1.0 — Playable product milestone ✅
Missions, progression, lifetime statistics, best-day goals, expanded event system and a complete repeatable management loop.

## Future expansion

The core loop is intentionally small so future systems can be added without rewriting the game:

- Multiple stores / districts
- More product categories
- Customer quests and special customers
- Achievement collection
- Upgrade / technology tree
- Decoration and store customization
- More events and seasonal content
- Sound / music asset layer
- Tutorial and onboarding polish
- Mobile-specific UI and haptics
- Optional rewarded-video economy
- WeChat mini-game packaging

## Technical

- Engine: **Godot 4.x**
- Viewport: **960 × 540**
- Main scene: `scenes/shop.tscn`
- Current shop logic: `scripts/shop_game_v1.gd`
- Save file: `user://my_little_shop_v1.json`
- Runtime dependencies: none

## Run

Open the project with Godot 4.x and run `scenes/shop.tscn`.

## Status

**v1.0 — playable prototype milestone.**

The project now has a complete management loop, progression, persistence, missions and enough structure to move into content, art, audio and mobile packaging without changing the core architecture.
