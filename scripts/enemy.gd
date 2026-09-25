class_name Enemy
extends Area2D

const Bullet = preload("res://scripts/bullet.gd")

var hp := 60.0
var max_hp := 60.0
var speed := 130.0
var dead := false
var fire_cd := 0.0
var fire_rate := 1.1
var bounds := Rect2()
var tex_path := "res://assets/hero_e1.png"
var sprite: Sprite2D

signal died

func _ready():
	sprite = Sprite2D.new()
	sprite.texture = load(tex_path)
	var s := 110.0 / sprite.texture.get_size().x
	sprite.scale = Vector2(s, s)
	add_child(sprite)
	var shape := CircleShape2D.new()
	shape.radius = 44.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	add_to_group("enemy")
	queue_redraw()

func _process(delta):
	if dead:
		return
	var plist := get_tree().get_nodes_in_group("player")
	var player = null
	if plist.size() > 0:
		player = plist[0]
	if player and not player.dead:
		var to := player.position - position
		var d := to.length()
		if d > 170.0:
			position += to.normalized() * speed * delta
		position.x = clampf(position.x, bounds.position.x, bounds.end.x)
		position.y = clampf(position.y, bounds.position.y, bounds.end.y)
		fire_cd -= delta
		if fire_cd <= 0 and d < 540.0:
			fire_cd = fire_rate
			var b := Bullet.new()
			b.position = position + to.normalized() * 50.0
			b.vel = to.normalized() * 360.0
			b.damage = 8.0
			b.friendly = false
			b.life = 2.4
			get_parent().add_child(b)
	queue_redraw()

func take_damage(amount):
	if dead:
		return
	hp -= amount
	if hp <= 0:
		hp = 0.0
		dead = true
		emit_signal("died")
		queue_free()
	queue_redraw()

func _draw():
	var w := 82.0
	var top := Vector2(-w / 2.0, -66.0)
	draw_rect(Rect2(top, Vector2(w, 8)), Color(0, 0, 0, 0.65))
	var ratio := clampf(hp / max_hp, 0, 1)
	draw_rect(Rect2(top, Vector2(w * ratio, 8)), Color(0.95, 0.3, 0.2))
