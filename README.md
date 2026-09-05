# My Little Shop 🏪

A lightweight **shop-management / tycoon game** built with Godot 4.x.

The project evolved from a card-RPG prototype into a small management game designed around a simple repeatable loop, procedural visuals, no runtime asset dependency, and future mobile / WeChat mini-game adaptation.

## v1.1 — Visual polish milestone ✅

**Stock → price → open → serve → earn → settle → upgrade → unlock → repeat.**

v1.1 includes everything from v1.0 plus:

- Procedural product icons for all 8 products
- Distinct customer appearances by archetype
- Animated customer idle movement and patience bars
- Stronger shop-floor presentation with shelf rows, checkout and entrance
- Gold pulse feedback after sales and mission rewards
- Reputation progress bar in the header
- Market-event banner in the top HUD
- Clearer active OPEN / CLOSE shop state
- Improved touch hitboxes for dashboard and missions close buttons
- Fixed the 960×540 viewport layout so stock cards stay inside the visible screen
- More compact management HUD for desktop and future mobile adaptation

## v1.0 — Final playable milestone ✅

v1.0 established the complete management loop:

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
- Business dashboard with lifetime statistics
- First-run 4-step tutorial
- Bankruptcy / restart protection
- Mouse and keyboard controls with large touch-friendly hit areas
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

- **Mouse / touch** — management buttons and product cards
- **Space** — open / close shop
- **1-8** — restock products
- **N** — settle / continue to next day
- **D** — business dashboard
- **M** — missions
- **U** — change supplier
- **H** — hire staff
- **E** — expand store
- **- / +** — change selling price
- **F5** — save
- **F9** — load
- **F10** — reset save

## First-run flow

The first run guides the player through four steps:

1. Buy initial stock.
2. Adjust the selling price.
3. Open the shop and watch customers buy automatically.
4. Close the shop and settle the day.

After that, the tutorial disappears and the player can focus on optimization.

## Project history

### v0.3 — Customer simulation ✅
Customer types, preferences, budgets, patience and inventory capacity.

### v0.4 — Store layout ✅
Physical shop floor, shelves, entrance, checkout, movement and reputation.

### v0.5 — Deeper management ✅
Suppliers, popularity, market events, staff and operating costs.

### v0.6 — Persistence & feedback ✅
Save/load, daily settlement, floating feedback and touch-friendly controls.

### v1.0 — Final playable milestone ✅
Progression, missions, dashboard, tutorial, bankruptcy handling and a complete repeatable management loop.

### v1.1 — Visual polish milestone ✅
Procedural product icons, differentiated customers, patience bars, stronger HUD feedback, compact 960×540 layout and corrected touch hitboxes.

## Next phase

The core gameplay and first visual pass are now stable. Future work should focus on **content and presentation**:

- Sound effects and background music
- More products and customer behaviors
- Decorations and store customization
- Upgrade / technology tree
- Seasonal events and special customers
- Multiple stores / districts
- Mobile-specific UI, haptics and portrait layout
- Optional rewarded-video economy
- WeChat mini-game packaging

## Technical

- Engine: **Godot 4.x**
- Main scene: `scenes/shop.tscn`
- Current shop logic: `scripts/shop_game_v1.gd`
- Save file: `user://my_little_shop_v1.json`
- Runtime dependencies: none
- Target viewport: **960×540**

## Run

Open the project with Godot 4.x and run `scenes/shop.tscn`.

## Status

**v1.1 — playable visual-polish milestone complete.**

The repository now contains a coherent small management game with onboarding, economy, progression, persistence, missions, dashboard statistics, customer visuals, product icons and failure/restart handling. The next meaningful step is content/audio and mobile packaging rather than adding more abstract systems.
