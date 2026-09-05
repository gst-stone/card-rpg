extends Node2D

# My Little Shop v1.2 — ambient visual effects layer.

var t := 0.0
var last_level := 1
var last_day := 1
var confetti := 0.0

func _ready() -> void:
    var shop = get_parent()
    if shop:
        last_level = shop.level
        last_day = shop.day
    queue_redraw()

func _process(delta: float) -> void:
    t += delta
    var shop = get_parent()
    if shop:
        if shop.level != last_level:
            last_level = shop.level
            confetti = 1.2
        if shop.day != last_day:
            last_day = shop.day
            confetti = 0.7
    confetti = max(0.0, confetti - delta)
    queue_redraw()

func _draw() -> void:
    var shop = get_parent()
    if shop == null:
        return
    draw_store_decor()
    draw_event_fx(shop)
    draw_open_fx(shop)
    if confetti > 0.0:
        draw_confetti(confetti)

func draw_store_decor() -> void:
    for x in [95.0, 265.0, 435.0, 605.0]:
        var glow := 0.5 + sin(t * 2.0 + x) * 0.08
        draw_circle(Vector2(x, 72), 13.0, Color(1.0, 0.84, 0.38, 0.10 * glow))
        draw_line(Vector2(x, 42), Vector2(x, 61), Color(0.25, 0.28, 0.34, 0.8), 3.0)
        draw_circle(Vector2(x, 66), 6.0, Color(1.0, 0.82, 0.34, 0.8))

    draw_rect(Rect2(42, 276, 20, 25), Color(0.38, 0.25, 0.18, 1.0), true)
    draw_circle(Vector2(52, 270), 17, Color(0.24, 0.48, 0.30, 1.0))
    draw_circle(Vector2(41, 264), 10, Color(0.30, 0.56, 0.34, 1.0))
    draw_circle(Vector2(63, 262), 10, Color(0.27, 0.52, 0.31, 1.0))

    for i in range(2):
        var r := Rect2(600 + i * 30, 270 - i * 5, 25, 20)
        draw_rect(r, Color(0.58, 0.39, 0.20, 1.0), true)
        draw_line(r.position + Vector2(5, 3), r.end - Vector2(5, 3), Color(0.34, 0.22, 0.13, 1.0), 2.0)
        draw_line(Vector2(r.end.x - 5, r.position.y + 3), Vector2(r.position.x + 5, r.end.y - 3), Color(0.34, 0.22, 0.13, 1.0), 2.0)

    draw_rect(Rect2(36, 326, 74, 10), Color(0.18, 0.22, 0.28, 0.8), true)
    draw_line(Vector2(42, 331), Vector2(104, 331), Color(0.65, 0.58, 0.36, 0.65), 2.0)

func draw_event_fx(shop) -> void:
    var event_text: String = str(shop.event_text)
    if event_text == "Rainy day":
        for i in range(18):
            var x := float(22 + i * 37)
            var y := 95.0 + fmod(i * 31.0 + t * 180.0, 220.0)
            draw_line(Vector2(x, y), Vector2(x - 6, y + 12), Color(0.45, 0.65, 0.90, 0.24), 2.0)
    elif event_text == "Weekend rush" or event_text == "Local festival":
        draw_bunting()
        if event_text == "Local festival":
            for i in range(4):
                var x := 125.0 + i * 125.0
                var y := 92.0 + sin(t * 2.0 + i) * 4.0
                draw_circle(Vector2(x, y), 4.0, Color(0.95, 0.65, 0.25, 0.7))
    elif event_text == "Supplier sale":
        draw_circle(Vector2(640, 245), 18.0 + sin(t * 3.0) * 2.0, Color(0.3, 0.8, 0.55, 0.08))
        draw_string(ThemeDB.fallback_font, Vector2(620, 250), "SALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.9, 0.62, 0.8))
    elif event_text == "Heat wave":
        for i in range(5):
            var x := 150.0 + i * 105.0
            var y := 300.0 - sin(t * 2.0 + i) * 3.0
            draw_line(Vector2(x, y), Vector2(x + 10, y - 8), Color(1.0, 0.55, 0.25, 0.12), 2.0)

func draw_bunting() -> void:
    var left := Vector2(90, 95)
    var right := Vector2(620, 95)
    draw_line(left, right, Color(0.7, 0.68, 0.55, 0.55), 2.0)
    for i in range(11):
        var x := lerp(left.x, right.x, float(i) / 10.0)
        var y := 95.0 + sin(float(i) * 0.9) * 3.0
        var p := PackedVector2Array([Vector2(x - 8, y), Vector2(x + 8, y), Vector2(x, y + 12)])
        draw_colored_polygon(p, Color(0.85, 0.45, 0.35, 0.65))

func draw_open_fx(shop) -> void:
    if not shop.open:
        return
    var pulse := 0.5 + 0.5 * sin(t * 4.0)
    draw_circle(Vector2(76, 321), 24.0 + pulse * 4.0, Color(0.3, 0.85, 0.55, 0.035))
    draw_string(ThemeDB.fallback_font, Vector2(42, 315), "OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.95, 0.68, 0.65))

func draw_confetti(amount: float) -> void:
    for i in range(18):
        var seed := float(i) * 17.31
        var x := 50.0 + fmod(seed * 37.0 + t * 25.0, 610.0)
        var y := 70.0 + fmod(seed * 19.0 + (1.2 - amount) * 180.0, 285.0)
        var s := 2.0 + fmod(seed, 3.0)
        draw_rect(Rect2(x, y, s, s * 1.8), Color(0.9, 0.72, 0.3, min(0.85, amount)), true)
