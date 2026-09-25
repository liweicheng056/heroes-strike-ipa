class_name Joystick
extends Control

# Left-half virtual joystick. Emits a normalized direction vector (length 0..1).
var _touch_id := -1
var _origin := Vector2.ZERO
var _dir := Vector2.ZERO
var base_radius := 95.0
var stick_radius := 48.0

signal joystick_moved(dir)

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_id == -1 and event.position.x < get_viewport_rect().size.x * 0.5:
				_touch_id = event.index
				_origin = event.position
				_dir = Vector2.ZERO
				queue_redraw()
				emit_signal("joystick_moved", _dir)
		else:
			if event.index == _touch_id:
				_touch_id = -1
				_dir = Vector2.ZERO
				queue_redraw()
				emit_signal("joystick_moved", _dir)
	elif event is InputEventScreenDrag:
		if event.index == _touch_id:
			var d := event.position - _origin
			var dist := minf(d.length(), base_radius)
			if d.length() > 0.001:
				_dir = d.normalized() * (dist / base_radius)
			else:
				_dir = Vector2.ZERO
			queue_redraw()
			emit_signal("joystick_moved", _dir)

func _draw():
	if _touch_id == -1:
		return
	draw_circle(_origin, base_radius, Color(1, 1, 1, 0.10))
	draw_arc(_origin, base_radius, 0, TAU, 48, Color(1, 1, 1, 0.35), 3)
	var knob_pos := _origin + _dir * base_radius
	draw_circle(knob_pos, stick_radius, Color(1, 1, 1, 0.55))
