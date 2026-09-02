# My Little Shop 🏪

A small **shop-management game prototype** built with Godot 4.x.

The project started as a card-RPG prototype and has been redirected into a lightweight management game designed to be easy to learn, expand and eventually adapt to mobile / WeChat mini-game controls.

## Current gameplay

**Choose supplier → buy stock → set prices → open the shop → customers browse → sell → settle the day → improve staff/store → repeat.**

### v0.6 features

- Everything from v0.5
- Automatic save to `user://shop_save.json`
- Load saved progress on startup
- Manual save with **F5**
- Reload save with **F9**
- Reset save with **F10**
- Daily settlement screen
- Revenue / operating cost / profit breakdown
- Served / lost customer summary
- Floating sale and level-up feedback
- Larger touch-friendly management buttons
- Settlement flow designed for mobile adaptation

## Suppliers

| Supplier | Purchase price | Effect |
|---|---:|---|
| Local | 100% | Stable |
| Wholesale | 88% | 12% cheaper |
| Premium | 108% | Better preference matching |

## Events

Each new day can produce a market event: Rainy day, Weekend rush, Local festival, Supplier sale or Normal market.

## Staff

Staff members cost gold to hire and have recurring daily operating costs. They increase customer throughput and patience.

## Products

| Product | Cost | Base price | Unlock | Preference |
|---|---:|---:|---:|---|
| Water | 2g | 4g | Lv.1 | daily |
| Bread | 3g | 6g | Lv.1 | daily |
| Apple | 4g | 8g | Lv.1 | healthy |
| Drink | 5g | 10g | Lv.2 | snack |
| Noodles | 6g | 12g | Lv.2 | quick |
| Milk | 8g | 16g | Lv.3 | healthy |
| Cookie | 10g | 20g | Lv.4 | snack |
| Hotpot | 20g | 40g | Lv.5 | quick |

## Controls

- **Mouse / touch**: management buttons and product cards
- **Space**: open / close shop
- **1-8**: restock products
- **N**: daily settlement / continue to next day
- **S**: change supplier
- **H**: hire staff
- **- / +**: change selling price
- **U**: expand store
- **F5**: save
- **F9**: load
- **F10**: reset save

## Development roadmap

### v0.3 — Customer simulation ✅
Customer types, preferences, budgets, patience and inventory capacity.

### v0.4 — Store layout ✅
Physical shop floor, shelves, entrance, checkout counter, customer movement and reputation.

### v0.5 — Deeper management ✅
Suppliers, purchase prices, product popularity, daily events, staff hiring and operating costs.

### v0.6 — Persistence & game feel ✅
Save/load, daily settlement, floating feedback and larger touch-friendly controls.

### v0.7 — Presentation

- Pixel-art / illustrated visual layer
- Character animation states
- Sound effects and background music
- Better checkout and purchase effects
- Tutorial / first-day onboarding

### Later

- Multiple stores and districts
- Customer quests and achievements
- Product unlock tree
- Special events
- Optional ads / rewarded video
- WeChat mini-game adaptation

## Technical

- Engine: **Godot 4.x**
- Current viewport: **960 × 540**
- No third-party runtime dependencies
- Main scene: `scenes/shop.tscn`
- Current shop logic: `scripts/shop_game_v6.gd`
- Save file: `user://shop_save.json`

## Run

Open the project with Godot 4.x and run `scenes/shop.tscn`.

## Project status

**Prototype / active development — v0.6**

The management loop now has persistence and a clear day-to-day progression. The next priority is presentation, onboarding and stronger moment-to-moment game feel.
