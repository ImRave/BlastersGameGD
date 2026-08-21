extends CharacterBody2D

@export var move_speed := 120.0
@export var rotation_speed := 5.0
@export var facing_up := true
@export var separation_radius := 25.0
@export var separation_strength := 150.0
@export var flank_distance := 50.0
@export var flank_duration := 5.0
@export var touch_time_limit := 3.0
@export var no_target_lifetime := 2.0
@export var point_scene: PackedScene

var target: CharacterBody2D
var touching_player := false
var touch_timer := 0.0
var flanking := false
var flank_direction := 1
var flank_timer := 0.0
var smooth_direction := Vector2.ZERO
var no_target_timer := 0.0

func _ready():
	add_to_group("enemies")

	# 🔹 Buscar el nodo "ship" dentro de la escena principal
	var main_scene = get_tree().get_current_scene()
	target = main_scene.get_node_or_null("ship")

	if target == null:
		push_warning("⚠️ No se encontró el nodo 'ship' en la escena principal.")

func _physics_process(delta):
	if target == null or not is_instance_valid(target):
		no_target_timer += delta
		if no_target_timer >= no_target_lifetime:
			queue_free()
		return
	else:
		no_target_timer = 0.0

	var direction := Vector2.ZERO

	# --- Detectar si ha estado tocando al jugador por mucho tiempo ---
	if touching_player:
		touch_timer += delta
	else:
		touch_timer = 0.0

	# Si toca demasiado tiempo, activar modo de rodeo
	if touching_player and touch_timer >= touch_time_limit and not flanking:
		flanking = true
		flank_timer = 0.0
		flank_direction = 1 if randf() > 0.5 else -1

	# --- Flanqueo activo ---
	if flanking:
		flank_timer += delta
		if flank_timer > flank_duration:
			flanking = false
		else:
			var offset_angle = flank_direction * PI / 2
			var flank_target = target.global_position + Vector2(flank_distance, 0).rotated(target.rotation + offset_angle)
			var to_flank = flank_target - global_position
			if to_flank.length() > 5.0:
				direction += to_flank.normalized()
	else:
		if not touching_player:
			direction += (target.global_position - global_position).normalized()

	# --- Separación de otros enemigos ---
	var neighbors = get_tree().get_nodes_in_group("enemies")
	for other in neighbors:
		if other == self:
			continue
		var dist = global_position.distance_to(other.global_position)
		if dist < separation_radius and dist > 0:
			var push = (global_position - other.global_position).normalized() * (1.0 - dist / separation_radius)
			direction += push * separation_strength * delta

	smooth_direction = smooth_direction.lerp(direction.normalized(), 0.15)

	# --- Rotación ---
	if smooth_direction.length() > 0.1:
		var desired_angle = smooth_direction.angle()
		if facing_up:
			rotation = lerp_angle(rotation, desired_angle + PI / 2, rotation_speed * delta)
		else:
			rotation = lerp_angle(rotation, desired_angle, rotation_speed * delta)

	# --- Movimiento ---
	var forward = (Vector2.UP if facing_up else Vector2.RIGHT).rotated(rotation)
	velocity = forward * move_speed if not touching_player or flanking else Vector2.ZERO
	move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "player":
		touching_player = true

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "player":
		touching_player = false
		flanking = false
		touch_timer = 0.0
	elif area.name == "bulet":
		disaper()

func disaper():
	if point_scene:
		var points = point_scene.instantiate()
		get_tree().get_current_scene().add_child.call_deferred(points)
		points.global_position = global_position
	else:
		push_warning("No se asignó la escena 'point_scene'.")
	queue_free()
