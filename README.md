# My Little Shop 🏪

A small **shop-management game prototype** built with Godot 4.x.

The project started as a card-RPG prototype and has now been redirected into a simple, expandable management game. The current goal is to prove the core loop first, then gradually add more depth, content and better presentation.

## Current gameplay

**Buy stock → open the shop → customers arrive → products sell → earn gold/XP → expand → unlock products → repeat.**

### v0.2 features

- Shop management screen
- 8 products with different costs and demand weights
- Inventory / restocking system
- Automatic customer arrivals
- Customer capacity
- Lost customers when the shop is crowded or stock is unavailable
- Product demand weighting
- Daily market demand changes
- Adjustable selling-price multiplier
- Revenue and profit feedback
- Shop XP and level progression
- Product unlocks by shop level
- Shop expansion increases customer capacity
- Daily cycle
- Mouse and keyboard controls
- Lightweight procedural UI with no external assets required

## Products

| Product | Cost | Base price | Unlock |
|---|---:|---:|---:|
| Water | 2g | 4g | Lv.1 |
| Bread | 3g | 6g | Lv.1 |
| Apple | 4g | 8g | Lv.1 |
| Drink | 5g | 10g | Lv.2 |
| Noodles | 6g | 12g | Lv.2 |
| Milk | 8g | 16g | Lv.3 |
| Cookie | 10g | 20g | Lv.4 |
| Hotpot | 20g | 40g | Lv.5 |

## Controls

- **Mouse**: click management buttons and products
- **Space**: open / close shop
- **1-8**: restock products
- **N**: start next day
- **- / +**: decrease / increase selling price
- **U**: expand the shop
- **R**: restart the current scene

## How to play

1. Restock several low-cost products.
2. Adjust the price if you want a higher margin or more attractive prices.
3. Open the shop.
4. Watch customers arrive and buy products automatically.
5. Close the shop when shelves are running low.
6. Restock and expand when you have enough gold.
7. Start the next day and react to the new market conditions.

## Development direction

The game is intentionally small at this stage. The next layers will focus on making the management decisions more meaningful rather than immediately adding a large amount of content.

Planned systems:

- Customer types and individual preferences
- Product popularity and demand curves
- Supplier / purchasing decisions
- Shelf capacity and store layout
- Multiple shop areas
- Staff hiring and scheduling
- Daily goals and events
- Better progression and balancing
- Save/load for the shop-management mode
- Mobile / WeChat mini-game friendly controls
- Production art and sound

## Technical

- Engine: **Godot 4.x**
- Current viewport: **960 × 540**
- No third-party runtime dependencies
- Current shop scene: `scenes/shop.tscn`
- Current shop logic: `scripts/shop_game_v2.gd`

## Run

Open the project with Godot 4.x and run the configured main scene.

If you want to test the shop scene directly, open `scenes/shop.tscn` and run it.

## Project status

**Prototype / MVP in active development.**

The priority is to make the basic shop loop fun and understandable before investing heavily in art, monetization or platform-specific integration.
