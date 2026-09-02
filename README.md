# My Little Shop 🏪

A small **shop-management game prototype** built with Godot 4.x.

The project started as a card-RPG prototype and has been redirected into a lightweight management game designed to be easy to learn, expand and eventually adapt to mobile / WeChat mini-game controls.

## Current gameplay

**Buy stock → set prices → open the shop → customers with different needs arrive → sell → earn gold/XP → expand shelves → unlock products → repeat.**

### v0.3 features

- 8 products with different costs, prices and unlock levels
- Limited shelf capacity
- Restocking with capacity checks
- 4 customer types: Worker, Parent, Student, Neighbor
- Customer preferences: quick, healthy, snack and daily
- Customer budgets affect which products they can buy
- Customer patience and lost-customer tracking
- Automatic customer arrivals and sales
- Daily market demand changes
- Adjustable selling-price multiplier
- Revenue, served and lost-customer statistics
- Shop XP and level progression
- New products unlock as the shop grows
- Expansion increases shelf capacity
- Daily cycle
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

## Customer types

- **Worker** — prefers quick food and has a medium budget.
- **Parent** — prefers healthy products and is more patient.
- **Student** — prefers snacks and has a smaller budget.
- **Neighbor** — prefers everyday essentials.

Customers evaluate available products based on their preference, budget and the current market demand.

## Controls

- **Mouse**: click management buttons and products
- **Space**: open / close shop
- **1-8**: restock products
- **N**: start next day
- **- / +**: decrease / increase selling price
- **U**: expand shelves

## How to play

1. Restock products without filling every shelf with slow-moving goods.
2. Set a reasonable price before opening.
3. Open the shop and watch which customer types arrive.
4. Keep popular products in stock.
5. Avoid excessive prices because customers have limited budgets.
6. Close the shop when you need to restock or change prices.
7. Expand shelf capacity and unlock higher-value products.
8. Start the next day and react to changing market demand.

## Development roadmap

### v0.3 — Customer simulation ✅

Customer types, preferences, budgets, patience and shelf capacity are now implemented.

### v0.4 — Store layout

Planned next:

- Place individual shelves
- Different shelf capacities
- Product display bonuses
- Customer walking paths
- Checkout counter
- Small store layout decisions

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
- Current shop logic: `scripts/shop_game_v3.gd`

## Run

Open the project with Godot 4.x and run the configured main scene.

To test the shop directly, open `scenes/shop.tscn` and run it.

## Project status

**Prototype / active development — v0.3**

The current priority is gameplay depth and a fun management loop. Art polish and platform-specific integration will come after the core mechanics are stable.
