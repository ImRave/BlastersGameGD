extends CharacterBody2D

@export var acceleration := 1000.0
@export var max_speed := 120000.0
@export var rotation_speed := 7.0
@export var base_friction := 0.94
@export var drift_factor := 0.25

const BULLET_SCENE := preload("res://Escenas/bulet.tscn")

@export var fire_rate := 0.25
@export var bullet_speed := 400.0
@export var muzzle_offset := 15.0

@export var tiempo_stun := 2.0

# Nuevas variables para el impacto físico
@export var impacto_force := 500.0  # Fuerza del empujón
@export var impacto_rotation_force := 10.0  # Fuerza de rotación al impactar

var stun_restante := 0.0
var stunned := false

var forward_direction := Vector2.UP
var drift_velocity := Vector2.ZERO
var can_shoot := true
var shoot_timer := 0.0

# Sistema mejorado de daño por contacto
var is_touching_enemy := false
var enemy_contact_timer := 0.0
var damage_interval := 0.5
var first_contact_processed := false  # Para controlar el primer contacto

# Valores iniciales para restaurar si es necesario
var initial_acceleration: float
var initial_max_speed: float
var initial_scale: Vector2

func _ready():
	# Guardar valores iniciales
	initial_acceleration = acceleration
	initial_max_speed = max_speed
	initial_scale = scale
	print("Valores iniciales guardados:")
	print("Aceleración: ", acceleration)
	print("Velocidad máxima: ", max_speed)
	print("Escala: ", scale)

func _physics_process(delta: float) -> void:
	if stunned:
		stun_restante -= delta

		# Aplicar fricción durante el aturdimiento para simular pérdida de control
		velocity *= 0.95
		
		# Pequeña rotación aleatoria durante el aturdimiento (efecto de tambaleo)
		rotation += randf_range(-0.5, 0.5) * delta * 2
		
		if stun_restante <= 0.0:
			stunned = false
			stun_restante = 0.0
			print("Fin del aturdimiento - nave recuperada")
		else:
			move_and_slide()
			return  # Salir temprano si está aturdido

	# --- Entrada de movimiento ---
	var turn_dir := Input.get_axis("left", "right")
	var move_dir := Input.get_axis("down", "up")

	# --- Rotación ---
	if turn_dir != 0.0:
		rotation += turn_dir * rotation_speed * delta

	var forward := forward_direction.rotated(rotation)

	# --- Movimiento ---
	if move_dir != 0.0:
		var accel_vec := forward * move_dir * acceleration * delta
		velocity += accel_vec
		velocity *= base_friction
	else:
		velocity *= 0.88

	# Limitar velocidad máxima (usando el valor actual que puede cambiar)
	if velocity.length_squared() > max_speed * max_speed:
		velocity = velocity.normalized() * max_speed

	drift_velocity = drift_velocity.lerp(velocity, 1.0 - drift_factor)
	velocity = drift_velocity

	move_and_slide()

	# --- Control de disparo ---
	if Input.is_action_pressed("shoot"):
		if can_shoot:
			shoot_bullet()
			#can_shoot = false
			shoot_timer = 0.0
	else:
		shoot_timer += delta
		if shoot_timer >= fire_rate:
			can_shoot = true

	# --- Auto destrucción ---
	if scale.x <= 0.4:
		print("Auto-destrucción: escala mínima alcanzada")
		queue_free()

	# --- Sistema de daño por contacto con enemigos ---
	if is_touching_enemy:
		enemy_contact_timer += delta
		
		# Daño continuo cada 0.5 segundos
		if enemy_contact_timer >= damage_interval:
			control_scale_velocity_minus()
			enemy_contact_timer = 0.0  # Resetear timer para el próximo intervalo
			print("Daño continuo por contacto prolongado")
	else:
		# Resetear variables cuando no hay contacto
		enemy_contact_timer = 0.0
		first_contact_processed = false

# --- 🔹 Control de tamaño y velocidad (MERMA) ---
func control_scale_velocity_minus() -> void:
	# Reducir escala
	scale -= Vector2(0.0175, 0.0175)
	
	# Aumentar velocidad y aceleración (para compensar la reducción de tamaño)
	acceleration += 15
	max_speed += 15
	
	# Limites mínimos de escala
	if scale.x < 0.3:
		scale = Vector2(0.3, 0.3)
	
	print("Merma aplicada - Escala: ", scale, " | Aceleración: ", acceleration, " | Vel. Máx: ", max_speed)

# --- 🔹 Control de tamaño y velocidad (AUMENTO) ---
func control_scale_velocity_plus() -> void:
	# Aumentar escala
	scale += Vector2(0.3, 0.3)
	
	# Reducir velocidad y aceleración (para balancear el aumento de tamaño)
	acceleration -= 35
	max_speed -= 35
	
	# Limites para evitar valores negativos
	if acceleration < 100:
		acceleration = 100
	if max_speed < 50000:
		max_speed = 50000
	
	print("Aumento aplicado - Escala: ", scale, " | Aceleración: ", acceleration, " | Vel. Máx: ", max_speed)

# --- 🔹 FUNCIÓN DE IMPACTO MEJORADA ---
func apply_impact(obstacle_position: Vector2) -> void:
	# Calcular dirección desde el obstáculo hacia la nave
	var impact_direction := (global_position - obstacle_position).normalized()
	
	# Si la nave está demasiado cerca del obstáculo, usar dirección aleatoria
	if impact_direction.length() < 0.1:
		impact_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# Aplicar fuerza de empujón
	var push_force := impact_direction * impacto_force
	velocity += push_force
	
	# Añadir rotación aleatoria para simular el impacto
	var rotation_force := randf_range(-1, 1) * impacto_rotation_force
	rotation += rotation_force
	
	# Efecto de vibración visual
	var tween := create_tween()
	tween.tween_property(self, "position", position + impact_direction * 5, 0.05)
	tween.tween_property(self, "position", position, 0.05)
	tween.tween_property(self, "position", position + impact_direction * 3, 0.05)
	tween.tween_property(self, "position", position, 0.05)
	
	# Reducir ligeramente el tamaño para simular daño estructural
	scale -= Vector2(0.03, 0.03)
	if scale.x < 0.3:
		scale = Vector2(0.3, 0.3)
	
	print("💥 IMPACTO! - Empujado en dirección: ", impact_direction, " | Fuerza: ", push_force)

# --- 🔹 Detección de áreas MEJORADA ---
func _on_player_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
		
	if area.name =="Obstacle_Area":
		# Activar aturdimiento
		stunned = true
		stun_restante = tiempo_stun
		
		# APLICAR IMPACTO FÍSICO
		var obstacle_position := area.global_position
		apply_impact(obstacle_position)
		
		print("💥 CHOQUE CON OBSTÁCULO - Nave aturdida y empujada!")
		
	if area.name == "enemy":
		is_touching_enemy = true
		print("Contacto con enemigo detectado")
		
		# 🔥 PRIMER CONTACTO: Daño inmediato
		if not first_contact_processed:
			control_scale_velocity_minus()
			first_contact_processed = true
			enemy_contact_timer = 0.0  # Empezar timer para daño continuo
			print("PRIMER DAÑO INMEDIATO aplicado")
		else:
			print("Daño continuo activado (cada 0.5s)")
			
	elif area.name == "point":
		control_scale_velocity_plus()
		if is_instance_valid(area):
			area.queue_free()
		print("Punto recolectado - Escala aumentada")

func _on_player_area_exited(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	
	if area.name == "enemy":
		is_touching_enemy = false
		print("Sin contacto con enemigo - Daño desactivado")

# --- 🔹 Sistema de disparo ---

func shoot_bullet() -> void:
	if BULLET_SCENE == null:
		push_warning("No se asignó una escena de bala (BULLET_SCENE).")
		return

	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)

	if has_node("Sprite2D/AnimationPlayer"):
		$Sprite2D/AnimationPlayer.play("shoot")

	# Distancia base desde el centro de la nave
	var base_offset := 7.5

	# Aumentar la distancia según el tamaño actual de la nave
	var dynamic_offset := base_offset * scale.x

	# Posición de salida de la bala
	var muzzle_pos := global_position + Vector2(0, -dynamic_offset).rotated(rotation)

	bullet.global_position = muzzle_pos
	bullet.rotation = rotation

	if bullet.has_method("set_direction"):
		bullet.set_direction(Vector2.UP.rotated(rotation))


# --- 🔹 Función de reset (opcional, para debugging) ---
func reset_to_initial_values():
	acceleration = initial_acceleration
	max_speed = initial_max_speed
	scale = initial_scale
	is_touching_enemy = false
	enemy_contact_timer = 0.0
	first_contact_processed = false
	stunned = false
	stun_restante = 0.0
	print("Valores reseteados a iniciales")

# --- 🔹 Debugging con teclas (opcional) ---
func _input(event):
	# Tecla Espacio para ver estado actual
	if event.is_action_pressed("ui_accept"):
		print("=== ESTADO ACTUAL ===")
		print("Escala: ", scale)
		print("Aceleración: ", acceleration)
		print("Velocidad Máxima: ", max_speed)
		print("Tocando enemigo: ", is_touching_enemy)
		print("Primer contacto procesado: ", first_contact_processed)
		print("Timer de daño: ", enemy_contact_timer)
		print("Aturdido: ", stunned)
		print("Tiempo restante aturdimiento: ", stun_restante)
	
	# Tecla Escape para resetear valores
	if event.is_action_pressed("ui_cancel"):
		reset_to_initial_values()
