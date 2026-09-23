extends Node2D

@export_category("Meteoritos")

@export var meteorito_scene: PackedScene
@export var meteorito_tiempo_minimo: float = 0.5
@export var meteorito_tiempo_maximo: float = 2.0

@export_category("Enemigos")

@export var enemigo_scene: PackedScene
@export var enemigo_tiempo_minimo: float = 1
@export var enemigo_tiempo_maximo: float = 5.0
@export var max_enemigos: int = 5

@export_category("Zona de aparición")

@export var posicion_minima: Vector2 = Vector2(-1000, -600)
@export var posicion_maxima: Vector2 = Vector2(1000, 600)

@export var zona_prohibida: Area2D
@export var max_intentos: int = 100

@export_category("Dificultad")

@export var enemigos_iniciales: int = 20
@export var minutos_aumento_enemigos: int = 1
@export var aumento_max_enemigos: int = 20

@export var minutos_aumento_velocidad: int = 1
@export var multiplicador_velocidad_enemigos: float = 1.25
@export var multiplicador_velocidad_meteoritos: float = 1.05

var enemigos_activos: int = 0
var kills: int = 0
var total_time_in_secs: int = 0
var player: bool = true

var nivel_dificultad: int = 0
func _ready() -> void:

	# Comenzar generadores
	$CanvasLayer/HBoxContainer/Timer.start()
	$sfx_back.playing = true
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
			# Probabilidad del 5%: aparece la mitad del máximo de una sola vez
			if randf() < 0.05:
				var cantidad: int = int(max_enemigos / 2.0)
				_crear_varios_enemigos(cantidad)

			# Probabilidad del 10%: aparece el 20% del máximo de una sola vez
			elif randf() < 0.10:
				var cantidad: int = int(max_enemigos * 0.2)
				_crear_varios_enemigos(cantidad)

			# Caso normal: aparece un solo enemigo
			else:
				crear_enemigo()


func _crear_varios_enemigos(cantidad: int) -> void:
	# Nos aseguramos de no superar el máximo de enemigos activos
	var espacio_disponible: int = max_enemigos - enemigos_activos
	var a_crear: int = min(cantidad, espacio_disponible)
	
	for i in a_crear:
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
	if player == true:
		kills +=1
		$CanvasLayer/HBoxContainer/Kills/NK.text = str(kills).pad_zeros(3)
		$sfx_kill.play()
		if kills%10==0:
			$CanvasLayer/sfx_points.play()
	print(kills)
	
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


func _on_timer_timeout() -> void:

	total_time_in_secs += 1

	var m = int(total_time_in_secs / 60.0)
	var s = total_time_in_secs - m * 60

	$CanvasLayer/HBoxContainer/time.text = '%02d:%02d' % [m, s]

	actualizar_dificultad()
	

func leer_numero_de_txt(ruta: String) -> int:
	var points =0
	if ResourceLoader.exists(ruta):
		var data =load(ruta)
		points =data.max_point
	
	return points


func escribir_numero_en_txt(ruta: String, numero: int) -> void:
	var data  =Save.new()
	data.max_point =numero
	ResourceSaver.save(data,ruta)

func save()->void:
	if leer_numero_de_txt("user://save.tres") < kills:
		escribir_numero_en_txt("user://save.tres",kills)
	


func _on_child_exiting_tree(child: CharacterBody2D) -> void:
	print(child.name)
	if child.name == "ship":
		player = false
		$sfx_die.play()
		await get_tree().create_timer(2.5).timeout
		save()
		get_tree().change_scene_to_file("res://MainMenu.tscn")
		queue_free()

func actualizar_dificultad() -> void:

	var minuto_actual: int = int(total_time_in_secs / 60.0)

	# =========================================
	# CANTIDAD DE ENEMIGOS
	# =========================================

	var aumentos_enemigos: int = int(
		minuto_actual / minutos_aumento_enemigos
	)

	max_enemigos = enemigos_iniciales + (
		aumentos_enemigos * aumento_max_enemigos
	)


	# =========================================
	# VELOCIDAD DE APARICIÓN DE ENEMIGOS
	# =========================================

	var nivel_velocidad_enemigos: int = int(
		minuto_actual / minutos_aumento_velocidad
	)

	var multiplicador_enemigos: float = pow(
		multiplicador_velocidad_enemigos,
		nivel_velocidad_enemigos
	)

	enemigo_tiempo_minimo = 2.0 / multiplicador_enemigos
	enemigo_tiempo_maximo = 5.0 / multiplicador_enemigos


	# =========================================
	# VELOCIDAD DE APARICIÓN DE METEORITOS
	# =========================================

	var multiplicador_meteoritos: float = pow(
		multiplicador_velocidad_meteoritos,
		nivel_velocidad_enemigos
	)

	meteorito_tiempo_minimo = 0.5 / multiplicador_meteoritos
	meteorito_tiempo_maximo = 2.0 / multiplicador_meteoritos
