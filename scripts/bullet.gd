class_name Bullet
extends Area2D

# Projectile fired by player and enemies.
var vel := Vector2.ZERO
var damage := 10.0
var life := 2.0
var friendly := true      # true = fired by player, hits enemies
var radius := 9.0

func _ready():
	var shape := CircleShape2D.new()
	shape.radius = radius
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _process(delta):
	position += vel * delta
	life -= delta
	if life <= 0:
		queue_free()

func _on_area_entered(other):
	if friendly:
		if other.is_in_group("enemy") and other.has_method("take_damage"):
			other.take_damage(damage)
			queue_free()
	else:
		if other.is_in_group("player") and other.has_method("take_damage"):
			other.take_damage(damage)
			queue_free()

func _draw():
	var c := Color(1.0, 0.92, 0.25) if friendly else Color(1.0, 0.35, 0.25)
	draw_circle(Vector2.ZERO, radius, c)
	draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 1, 1, 0.8))
