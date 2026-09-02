# My Little Shop 🏪

A small **shop-management game prototype** built with Godot 4.x.

The project started as a card-RPG prototype and has been redirected into a lightweight management game designed to be easy to learn, expand and eventually adapt to mobile / WeChat mini-game controls.

## Current gameplay

**Choose supplier → buy stock → set prices → open the shop → customers browse → sell → pay operating costs → improve staff/store → repeat.**

### v0.5 features

- Physical store floor layout
- Multiple shelves and limited inventory capacity
- Entrance and checkout counter
- Customers visibly move around the shop
- 4 customer types with different preferences and budgets
- Supplier selection with different purchase prices
- Product popularity and market demand
- Daily random market events
- Staff hiring and service-speed bonuses
- Daily operating costs
- Reputation, revenue, profit and lost-customer tracking
- Adjustable selling-price multiplier
- Shop XP and level progression
- Store expansion
- 8 products with unlock levels
- Mouse and keyboard controls
- Procedural UI with no external runtime assets

## Suppliers

| Supplier | Purchase price | Effect |
|---|---:|---|
| Local | 100% | Stable |
| Wholesale | 88% | 12% cheaper |
| Premium | 108% | Better preference matching |

Press **S** or click Supplier to switch supplier before placing orders.

## Events

Each new day can produce a market event:

- **Rainy day** — lower demand
- **Weekend rush** — higher demand
- **Local festival** — higher demand
- **Supplier sale** — higher realized profit
- **Normal market** — no special modifier

## Staff

Staff members cost gold to hire and have a recurring daily operating cost. They also increase customer throughput and patience, making them useful once the store becomes busy.

Press **H** to hire staff when the shop is closed.

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

- **Mouse**: click management buttons and product cards
- **Space**: open / close shop
- **1-8**: restock products
- **N**: start next day
- **S**: change supplier
- **H**: hire staff
- **- / +**: decrease / increase selling price
- **U**: expand the store
- **R**: restart the scene

## How to play

1. Select a supplier. Wholesale is cheaper; Premium is more expensive but helps matching customer preferences.
2. Restock products while the shop is closed.
3. Avoid filling the store with goods that have weak demand.
4. Set a reasonable selling price.
5. Open the shop and watch customer types and inventory.
6. Hire staff when customer traffic starts becoming difficult to handle.
7. Pay attention to the daily event and market demand.
8. Expand only when additional shelf capacity can cover the cost.

## Development roadmap

### v0.3 — Customer simulation ✅
Customer types, preferences, budgets, patience and inventory capacity.

### v0.4 — Store layout ✅
Physical shop floor, shelves, entrance, checkout counter, customer movement and reputation.

### v0.5 — Deeper management ✅
Suppliers, purchase prices, product popularity, daily events, staff hiring and operating costs.

### v0.6 — Game feel

- Better pixel-art / illustrated UI
- Character animations
- Sound effects
- Better purchase/sale feedback
- Save/load
- Mobile-friendly touch UI

### Later

- Multiple stores
- Store districts
- Special events and achievements
- Customer quests
- Product unlock tree
- Optional ads / rewarded video
- WeChat mini-game adaptation

## Technical

- Engine: **Godot 4.x**
- Current viewport: **960 × 540**
- No third-party runtime dependencies
- Main shop scene: `scenes/shop.tscn`
- Current shop logic: `scripts/shop_game_v5.gd`

## Run

Open the project with Godot 4.x and run the configured main scene.

To test the shop directly, open `scenes/shop.tscn` and run it.

## Project status

**Prototype / active development — v0.5**

The core management loop is now taking shape. The next priority is improving game feel and persistence before adding a large amount of content.
