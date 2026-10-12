extends RigidBody2D
## Meteoro: en el instante de aparecer toma la posición de la nave y apunta su
## velocidad hacia ese punto. Después viaja recto; NO persigue.

signal impacto_nave(nave: Node)

# --- Movimiento ---
@export var velocidad: float = 400.0
@export_range(0.0, 1.0, 0.01) var desviacion_max: float = 0.05  ## Error de puntería en radianes (0.05 ≈ 3°). 0 = exacto.
@export var tiempo_vida: float = 15.0

# --- Física ---
@export var rebote: float = 0.9
@export var friccion: float = 0.1

# --- Rotación visual aleatoria ---
@export var usar_rotacion_aleatoria: bool = true
@export var rotacion_velocidad_min: float = -3.0  # rad/s
@export var rotacion_velocidad_max: float = 3.0   # rad/s

# --- Búsqueda de la nave (solo se usa al nacer) ---
@export var grupo_nave: StringName = &"ship"
@export var nombre_nave: StringName = &"ship"
@export var punto_respaldo: Vector2 = Vector2(413.5, 230.5)  ## Si no hay nave, apunta aquí
@export var debug: bool = false  ## Imprime origen, destino y velocidad al lanzarse

# --- Colisiones ---
@export_flags_2d_physics var capa_colision: int = 2
@export_flags_2d_physics var mascara_colision: int = 2

# --- Sprite aleatorio (pesos para la columna 0..3) ---
@export var pesos_de_probabilidad_x: Array[int] = [33, 33, 33, 1]

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")

var punto_destino: Vector2 = Vector2.ZERO  # Posición de la nave en el momento de nacer
var _nave: Node2D = null
var _ya_impacto: bool = false


func _ready() -> void:
	# Sin gravedad ni frenado: el meteoro mantiene su velocidad
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	collision_layer = capa_colision
	collision_mask = mascara_colision

	var material := PhysicsMaterial.new()
	material.bounce = rebote
	material.friction = friccion
	physics_material_override = material

	# Necesario para que body_entered se emita en un RigidBody2D
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

	if _sprite:
		_sprite.frame_coords = Vector2i(_get_weighted_x(), randi_range(0, 1))

	angular_velocity = randf_range(rotacion_velocidad_min, rotacion_velocidad_max) if usar_rotacion_aleatoria else 0.0

	get_tree().create_timer(tiempo_vida).timeout.connect(queue_free)

	# Se lanza al final del frame: así el spawner ya pudo asignar la posición
	# de aparición (si no, el origen sería (0,0) y la dirección saldría mal).
	_lanzar.call_deferred()


## Calcula la dirección con la posición ACTUAL del meteoro y de la nave, una sola vez.
func _lanzar() -> void:
	_nave = _buscar_nave()
	punto_destino = _nave.global_position if _nave else punto_respaldo
	lanzar_hacia(punto_destino)


## También puedes llamarla desde el spawner: meteoro.lanzar_hacia(nave.global_position)
func lanzar_hacia(destino: Vector2) -> void:
	punto_destino = destino
	var direccion := destino - global_position
	direccion = direccion.normalized() if direccion.length_squared() > 0.0001 else Vector2.RIGHT
	direccion = direccion.rotated(randf_range(-desviacion_max, desviacion_max))
	linear_velocity = direccion * velocidad

	if debug:
		print("Meteoro | origen: ", global_position, " destino: ", punto_destino, " velocidad: ", linear_velocity)


func _buscar_nave() -> Node2D:
	# 1) Por grupo
	var nave := get_tree().get_first_node_in_group(grupo_nave) as Node2D
	if nave:
		return nave
	# 2) Por nombre en cualquier parte de la escena
	var escena := get_tree().current_scene
	if escena:
		nave = escena.find_child(nombre_nave, true, false) as Node2D
	if nave == null:
		push_warning("No se encontró la nave ('%s'). Usando punto de respaldo." % nombre_nave)
	return nave


func _on_body_entered(body: Node) -> void:
	# Al tocar la nave NO se destruye: sigue en escena hasta que acabe su tiempo de vida.
	# La señal se emite solo la primera vez (por si quieres aplicar daño).
	if not _ya_impacto and is_instance_valid(_nave) and body == _nave:
		_ya_impacto = true
		impacto_nave.emit(body)


func _get_weighted_x() -> int:
	var total := 0
	for peso in pesos_de_probabilidad_x:
		total += peso
	if total <= 0:
		return 0

	var aleatorio := randi_range(0, total - 1)
	var acumulado := 0
	for i in pesos_de_probabilidad_x.size():
		acumulado += pesos_de_probabilidad_x[i]
		if aleatorio < acumulado:
			return i
	return pesos_de_probabilidad_x.size() - 1


## Llámala desde tu bala del jugador (o Area2D) para destruir este meteoro.
func destruir() -> void:
	queue_free()
