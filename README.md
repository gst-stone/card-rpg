# My Little Shop 🏪

A small **shop-management game prototype** built with Godot 4.x.

The project started as a card-RPG prototype and has been redirected into a lightweight management game designed to be easy to learn, expand and eventually adapt to mobile / WeChat mini-game controls.

## Current gameplay

**Buy stock → set prices → open the shop → customers enter and browse → products sell → earn gold/XP → expand the store → repeat.**

### v0.4 features

- Physical store floor layout
- Multiple shelves displayed inside the shop
- Shelf capacity and inventory limits
- Checkout counter and entrance
- Customers visibly walk from the entrance into the store
- Customer types with different preferences and budgets
- Customer patience and reputation
- Automatic sales based on customer needs
- Daily market demand changes
- Adjustable selling-price multiplier
- Shop XP and level progression
- Expansion adds shelf capacity and another shelf
- 8 products with unlock levels
- Mouse and keyboard controls
- Procedural UI with no external runtime assets

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

## v0.4 store layout

The shop is no longer only a management panel. The main area represents the physical store:

- Entrance at the lower-left
- Shelves arranged on the shop floor
- Checkout counter on the right side of the floor
- Customers enter from the entrance
- Customers move toward browsing positions
- Customer icons show their type
- Higher shop level adds another shelf section

The layout is intentionally procedural for now, so the project can evolve without requiring a large art pipeline.

## Customer types

- **Worker** — prefers quick food and has a medium budget.
- **Parent** — prefers healthy products and is more patient.
- **Student** — prefers snacks and has a smaller budget.
- **Neighbor** — prefers everyday essentials.

Customers evaluate products using preference, budget and market demand. Excessive prices can make products unavailable to budget-sensitive customers.

## Controls

- **Mouse**: click management buttons and product cards
- **Space**: open / close shop
- **1-8**: restock products
- **N**: start next day
- **- / +**: decrease / increase selling price
- **U**: expand the store
- **R**: restart the scene

## How to play

1. Restock products without filling every shelf with slow-moving goods.
2. Set a reasonable price before opening.
3. Open the shop and watch customers enter.
4. Observe which customer types are visiting.
5. Keep the products those customers want in stock.
6. Close the shop when you need to restock or change prices.
7. Expand the store when the extra capacity can generate enough sales.
8. Start the next day and react to changing market demand.

## Development roadmap

### v0.3 — Customer simulation ✅

Customer types, preferences, budgets, patience and inventory capacity.

### v0.4 — Store layout ✅

- Physical shop floor
- Shelves
- Entrance
- Checkout counter
- Customer movement
- Reputation feedback
- Expansion adds physical shelf space

### v0.5 — Deeper management

- Suppliers and purchase prices
- Product popularity trends
- Daily events
- Staff hiring
- Operating costs
- Daily objectives

### v0.6 — Game feel

- Better pixel-art / illustrated UI
- Character animations
- Sound effects
- More satisfying feedback
- Save/load
- Mobile-friendly touch UI

### Later

- Multiple stores
- Store districts
- Special events
- Achievements
- Optional ads / rewarded video
- WeChat mini-game adaptation

## Technical

- Engine: **Godot 4.x**
- Current viewport: **960 × 540**
- No third-party runtime dependencies
- Main shop scene: `scenes/shop.tscn`
- Current shop logic: `scripts/shop_game_v4.gd`

## Run

Open the project with Godot 4.x and run the configured main scene.

To test the shop directly, open `scenes/shop.tscn` and run it.

## Project status

**Prototype / active development — v0.4**

The next priority is to turn the physical store into a real management system: individual shelf assignments, product display bonuses, purchasing decisions and staff.
