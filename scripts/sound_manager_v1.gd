extends Node

# My Little Shop v1.2 — procedural UI/game-feel sounds.
# No external audio assets are required.

var player: AudioStreamPlayer
var last_gold := 0
var last_level := 1
var last_day := 1
var last_served := 0
var last_open := false
var cooldown := 0.0

func _ready() -> void:
    player = AudioStreamPlayer.new()
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 22050.0
    stream.buffer_length = 0.35
    player.stream = stream
    add_child(player)
    var shop = get_node_or_null("/root/ShopGame")
    if shop:
        last_gold = shop.gold
        last_level = shop.level
        last_day = shop.day
        last_served = shop.lifetime_served
        last_open = shop.open

func _process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var shop = get_node_or_null("/root/ShopGame")
    if shop == null:
        return

    if shop.level > last_level:
        tone(660.0, 0.10, 0.08)
        await get_tree().create_timer(0.08).timeout
        tone(880.0, 0.16, 0.08)
    elif shop.day > last_day:
        tone(420.0, 0.08, 0.06)

    if shop.lifetime_served > last_served and cooldown <= 0.0:
        tone(520.0, 0.045, 0.045)
        cooldown = 0.08

    if shop.gold > last_gold + 0:
        # Tiny cash-register chime; avoid repeating too aggressively.
        if cooldown <= 0.0:
            tone(760.0, 0.055, 0.045)
            cooldown = 0.07
    elif shop.gold < last_gold:
        if cooldown <= 0.0:
            tone(190.0, 0.07, 0.045)
            cooldown = 0.10

    if shop.open != last_open:
        tone(340.0 if shop.open else 260.0, 0.08, 0.05)

    last_gold = shop.gold
    last_level = shop.level
    last_day = shop.day
    last_served = shop.lifetime_served
    last_open = shop.open

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            tone(620.0, 0.035, 0.035)
    elif event is InputEventKey and event.pressed and not event.echo:
        tone(560.0, 0.025, 0.025)

func tone(freq: float, duration: float, volume: float) -> void:
    if player == null:
        return
    if not player.playing:
        player.play()
    var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
    if playback == null:
        return
    var frames := int(22050.0 * duration)
    for i in range(frames):
        var phase := float(i) / 22050.0
        var envelope := min(1.0, float(i) / 180.0) * min(1.0, float(frames - i) / 500.0)
        var sample := sin(TAU * freq * phase) * volume * envelope
        playback.push_frame(Vector2(sample, sample))
