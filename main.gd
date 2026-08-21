extends Node2D

@export_category("Meteoritos")

@export var meteorito_scene: PackedScene
@export var meteorito_tiempo_minimo: float = 0.5
@export var meteorito_tiempo_maximo: float = 2.0

@export_category("Enemigos")

@export var enemigo_scene: PackedScene
@export var enemigo_tiempo_minimo: float = 2.0
@export var enemigo_tiempo_maximo: float = 5.0
@export var max_enemigos: int = 5

@export_category("Zona de aparición")

@export var posicion_minima: Vector2 = Vector2(-1000, -600)
@export var posicion_maxima: Vector2 = Vector2(1000, 600)

@export var zona_prohibida: Area2D
@export var max_intentos: int = 100

var enemigos_activos: int = 0


func _ready() -> void:

	# Comenzar generadores
	generar_meteoritos()
	generar_enemigos()


# =========================================================
# METEORITOS
# =========================================================

func generar_meteoritos() -> void:

	if meteorito_scene == null:
		push_error("No se ha asignado meteorito_scene.")
		return

	while true:

		var tiempo_espera: float = randf_range(
			meteorito_tiempo_minimo,
			meteorito_tiempo_maximo
		)

		await get_tree().create_timer(tiempo_espera).timeout

		crear_meteorito()


func crear_meteorito() -> void:

	var posicion: Vector2 = obtener_posicion_aleatoria()

	var meteorito: Node2D = meteorito_scene.instantiate()

	meteorito.global_position = posicion

	add_child(meteorito)


# =========================================================
# ENEMIGOS
# =========================================================

func generar_enemigos() -> void:

	if enemigo_scene == null:
		push_error("No se ha asignado enemigo_scene.")
		return

	while true:

		var tiempo_espera: float = randf_range(
			enemigo_tiempo_minimo,
			enemigo_tiempo_maximo
		)

		await get_tree().create_timer(tiempo_espera).timeout

		if enemigos_activos < max_enemigos:
			crear_enemigo()


func crear_enemigo() -> void:

	var posicion: Vector2 = obtener_posicion_aleatoria()

	var enemigo: Node2D = enemigo_scene.instantiate()

	enemigo.global_position = posicion

	add_child(enemigo)

	enemigos_activos += 1

	# Cuando el enemigo sea eliminado,
	# liberar su espacio del contador.
	enemigo.tree_exited.connect(_enemigo_eliminado)


func _enemigo_eliminado() -> void:

	enemigos_activos -= 1

	if enemigos_activos < 0:
		enemigos_activos = 0


# =========================================================
# POSICIÓN ALEATORIA
# =========================================================

func obtener_posicion_aleatoria() -> Vector2:

	for intento in range(max_intentos):

		var posicion: Vector2 = Vector2(
			randf_range(posicion_minima.x, posicion_maxima.x),
			randf_range(posicion_minima.y, posicion_maxima.y)
		)

		if not posicion_en_zona_prohibida(posicion):
			return posicion

	# Posición de emergencia
	return Vector2(
		randf_range(posicion_minima.x, posicion_maxima.x),
		randf_range(posicion_minima.y, posicion_maxima.y)
	)


# =========================================================
# ZONA PROHIBIDA
# =========================================================

func posicion_en_zona_prohibida(posicion: Vector2) -> bool:

	if zona_prohibida == null:
		return false
	
	# Obtener el CollisionShape2D del área
	var shape: CollisionShape2D = zona_prohibida.get_node("CollisionShape2D")
	if shape == null:
		return false
	
	# Convertir la posición a coordenadas locales del área
	var local_pos: Vector2 = zona_prohibida.to_local(posicion)
	
	# Verificar según el tipo de shape
	if shape.shape is RectangleShape2D:
		var rect: RectangleShape2D = shape.shape as RectangleShape2D
		var half_extents: Vector2 = rect.extents
		return abs(local_pos.x) <= half_extents.x and abs(local_pos.y) <= half_extents.y
	
	elif shape.shape is CircleShape2D:
		var circle: CircleShape2D = shape.shape as CircleShape2D
		return local_pos.length() <= circle.radius
	
	elif shape.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape.shape as CapsuleShape2D
		# Verificación simplificada para cápsula
		var radius: float = capsule.radius
		var height: float = capsule.height
		var half_height: float = height / 2.0
		
		# Si está en la parte circular superior o inferior
		if abs(local_pos.y) > half_height:
			var dist_y: float = abs(local_pos.y) - half_height
			var dist: float = Vector2(local_pos.x, dist_y).length()
			return dist <= radius
		else:
			# Está en la parte rectangular del medio
			return abs(local_pos.x) <= radius
	
	else:
		# Para otros tipos de shape, usar método de respaldo
		var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		consulta.shape = shape.shape
		consulta.transform = Transform2D(0, posicion)
		consulta.collide_with_areas = true
		consulta.collide_with_bodies = false
		
		var resultados: Array = espacio.intersect_shape(consulta)
		for resultado in resultados:
			if resultado["collider"] == zona_prohibida:
				return true
		return false
