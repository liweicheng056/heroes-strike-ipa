class_name Player
extends Area2D

const Bullet = preload("res://scripts/bullet.gd")

var hp := 100.0
var max_hp := 100.0
var speed := 320.0
var move_dir := Vector2.ZERO
var aim_dir := Vector2.RIGHT
var fire_cd := 0.0
var fire_rate := 0.16
var dead := false
var bounds := Rect2()
var invuln := 0.0
var dash_cd := 0.0
var burst_cd := 0.0
var heal_cd := 0.0
var sprite: Sprite2D

signal died
signal hp_changed(hp, max_hp)

func _ready():
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/hero_player.png")
	var s := 120.0 / sprite.texture.get_size().x
	sprite.scale = Vector2(s, s)
	add_child(sprite)
	var shape := CircleShape2D.new()
	shape.radius = 48.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	add_to_group("player")
	queue_redraw()

func set_move_dir(d: Vector2):
	move_dir = d

func _process(delta):
	if dead:
		return
	position += move_dir * speed * delta
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.y = clampf(position.y, bounds.position.y, bounds.end.y)

	# pick nearest enemy for aim + auto fire
	var nearest = null
	var best := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.dead:
			continue
		var dd := position.distance_to(e.position)
		if dd < best:
			best = dd
			nearest = e
	if nearest:
		aim_dir = (nearest.position - position).normalized()
	elif move_dir.length() > 0.1:
		aim_dir = move_dir.normalized()

	fire_cd -= delta
	if nearest and fire_cd <= 0:
		fire_cd = fire_rate
		_spawn_bullet()

	dash_cd = maxf(0, dash_cd - delta)
	burst_cd = maxf(0, burst_cd - delta)
	heal_cd = maxf(0, heal_cd - delta)
	invuln = maxf(0, invuln - delta)
	queue_redraw()

func _spawn_bullet():
	var b := Bullet.new()
	b.position = position + aim_dir * 52.0
	b.vel = aim_dir * 640.0
	b.damage = 12.0
	b.friendly = true
	b.life = 1.6
	get_parent().add_child(b)

func use_skill(idx: int):
	if dead:
		return
	if idx == 0 and dash_cd <= 0:        # dash
		dash_cd = 3.0
		position += aim_dir * 230.0
		position.x = clampf(position.x, bounds.position.x, bounds.end.x)
		position.y = clampf(position.y, bounds.position.y, bounds.end.y)
		invuln = 0.45
	elif idx == 1 and burst_cd <= 0:     # aoe burst
		burst_cd = 6.0
		for e in get_tree().get_nodes_in_group("enemy"):
			if e.position.distance_to(position) < 280.0:
				e.take_damage(45.0)
	elif idx == 2 and heal_cd <= 0:       # heal
		heal_cd = 8.0
		hp = minf(max_hp, hp + 40.0)
		emit_signal("hp_changed", hp, max_hp)

func take_damage(amount):
	if dead or invuln > 0:
		return
	hp -= amount
	emit_signal("hp_changed", hp, max_hp)
	if hp <= 0:
		hp = 0.0
		dead = true
		emit_signal("died")
	queue_redraw()

func _draw():
	var w := 92.0
	var top := Vector2(-w / 2.0, -72.0)
	draw_rect(Rect2(top, Vector2(w, 9)), Color(0, 0, 0, 0.65))
	var ratio := clampf(hp / max_hp, 0, 1)
	draw_rect(Rect2(top, Vector2(w * ratio, 9)), Color(0.2, 0.9, 0.35))
