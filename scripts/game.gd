extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const JoystickScript = preload("res://scripts/joystick.gd")

var world: Node2D
var player
var arena := Rect2(36, 40, 648, 1110)
var kills := 0
var target_kills := 25
var ui_layer: CanvasLayer
var hp_label: Label
var score_label: Label
var overlay: Label
var joystick
var spawn_timer := 1.2
var spawn_interval := 2.4
var state := "playing"   # playing | win | lose

var enemy_textures := [
	"res://assets/hero_e1.png",
	"res://assets/hero_e2.png",
	"res://assets/hero_e3.png",
	"res://assets/hero_e4.png",
]

func _ready():
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	player = PlayerScript.new()
	player.name = "Player"
	player.bounds = arena
	player.position = arena.get_center()
	world.add_child(player)
	player.hp_changed.connect(_on_hp_changed)
	player.died.connect(_on_player_died)

	build_ui()
	queue_redraw()
	spawn_enemy()

func _draw():
	draw_rect(arena, Color(0.10, 0.12, 0.20))
	draw_rect(arena, Color(0.45, 0.55, 0.75), false, 5)
	for i in range(1, 9):
		var x := arena.position.x + arena.size.x * float(i) / 9.0
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color(1, 1, 1, 0.05))
	for j in range(1, 15):
		var y := arena.position.y + arena.size.y * float(j) / 15.0
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color(1, 1, 1, 0.05))

func build_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	hp_label = Label.new()
	hp_label.position = Vector2(20, 18)
	hp_label.text = "HP: 100"
	hp_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	hp_label.add_theme_font_size_override("font_size", 36)
	ui_layer.add_child(hp_label)

	score_label = Label.new()
	score_label.position = Vector2(20, 64)
	score_label.text = "击杀: 0 / %d" % target_kills
	score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	score_label.add_theme_font_size_override("font_size", 30)
	ui_layer.add_child(score_label)

	joystick = JoystickScript.new()
	joystick.name = "Joystick"
	ui_layer.add_child(joystick)
	joystick.joystick_moved.connect(player.set_move_dir)

	var labels := ["冲刺", "爆发", "治疗"]
	for i in range(3):
		var btn := Button.new()
		btn.text = labels[i]
		btn.custom_minimum_size = Vector2(112, 92)
		btn.position = Vector2(720 - 132 - i * 122, 1280 - 132)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(player.use_skill.bind(i))
		ui_layer.add_child(btn)

	overlay = Label.new()
	overlay.position = Vector2(40, 540)
	overlay.size = Vector2(640, 200)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.text = ""
	overlay.add_theme_font_size_override("font_size", 50)
	overlay.add_theme_color_override("font_color", Color(1, 1, 1))
	overlay.visible = false
	ui_layer.add_child(overlay)

func _process(delta):
	if state != "playing":
		return
	spawn_timer -= delta
	var alive := get_tree().get_nodes_in_group("enemy").size()
	if spawn_timer <= 0 and alive < 8:
		spawn_timer = spawn_interval
		spawn_enemy()
	if kills >= target_kills:
		_win()

func spawn_enemy():
	var e := EnemyScript.new()
	e.name = "Enemy_%d" % (kills + get_tree().get_nodes_in_group("enemy").size())
	e.bounds = arena
	e.tex_path = enemy_textures[randi() % enemy_textures.size()]
	var edge := randi() % 4
	var p := Vector2()
	match edge:
		0: p = Vector2(randf_range(arena.position.x, arena.end.x), arena.position.y + 30)
		1: p = Vector2(randf_range(arena.position.x, arena.end.x), arena.end.y - 30)
		2: p = Vector2(arena.position.x + 30, randf_range(arena.position.y, arena.end.y))
		3: p = Vector2(arena.end.x - 30, randf_range(arena.position.y, arena.end.y))
	e.position = p
	world.add_child(e)
	e.died.connect(_on_enemy_died)

func _on_enemy_died():
	kills += 1
	score_label.text = "击杀: %d / %d" % [kills, target_kills]

func _on_hp_changed(h, m):
	hp_label.text = "HP: %d" % int(h)

func _on_player_died():
	state = "lose"
	overlay.text = "失败！\n点击屏幕重新开始"
	overlay.visible = true

func _win():
	state = "win"
	overlay.text = "胜利！\n点击屏幕重新开始"
	overlay.visible = true

func _input(event):
	if state != "playing" and event is InputEventScreenTouch and event.pressed:
		get_tree().reload_current_scene()
