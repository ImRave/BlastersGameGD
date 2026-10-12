extends Node2D

@export_category("Meteoritos")
@export var meteorito_scene: PackedScene
@export var meteorito_tiempo_minimo: float = 0.5
@export var meteorito_tiempo_maximo: float = 2.0

@export_category("Enemigos")
@export var enemigo_scene: PackedScene
@export var enemigo_tiempo_minimo: float = 1.0
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

@onready var fps_label: Label = $CanvasLayer/Label

var enemigos_activos: int = 0
var kills: int = 0
var total_time_in_secs: int = 0
var player: bool = true

func _ready() -> void:
	randomize()
	$CanvasLayer/HBoxContainer/Timer.start()
	$ms_back.playing = true
	generar_meteoritos()
	generar_enemigos()
	if fps_label:
		fps_label.visible = Globals.show_fps

func _process(_delta: float) -> void:
	if fps_label == null:
		return
	if Globals.show_fps:
		if not fps_label.visible:
			fps_label.visible = true
			fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	else:
		if fps_label.visible:
			fps_label.visible = false

# =========================================================
# Helpers de pausa/tiempos
# =========================================================

func _await_unpaused() -> void:
# Si el árbol está en pausa, espera a que se reanude para evitar saltos.
	while get_tree().paused:
		await get_tree().process_frame

func _await_timer_safe(sec: float) -> void:
# Usa un temporizador que sigue procesando incluso durante pausa prolongada.
# Para Godot 4.x: create_timer(t, process_always=true) hace que el timer corra en pausa.
# Si tu versión no soporta process_always, descomenta el bloque alternativo.
	var t := get_tree().create_timer(max(sec, 0.0), true)
	await t.timeout
# Alternativa (si no puedes usar process_always=true):
# var start := Time.get_ticks_msec()
# while Time.get_ticks_msec() - start < int(sec * 1000.0):
# await get_tree().process_frame

# =========================================================
# METEORITOS
# =========================================================

func generar_meteoritos() -> void:
	if meteorito_scene == null:
		push_error("No se ha asignado meteorito_scene.")
		return
	while true:
		var tmin: float = clamp(meteorito_tiempo_minimo, 0.05, 60.0)
		var tmax: float = clamp(meteorito_tiempo_maximo, tmin, 120.0)
		var tiempo_espera: float = randf_range(tmin, tmax)
		await _await_timer_safe(tiempo_espera)
		await _await_unpaused()
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
		var emin: float = clamp(enemigo_tiempo_minimo, 0.05, 60.0)
		var emax: float = clamp(enemigo_tiempo_maximo, emin, 120.0)
		var tiempo_espera: float = randf_range(emin, emax)
		await _await_timer_safe(tiempo_espera)
		await _await_unpaused()
		if enemigos_activos < max_enemigos:
			var r := randf()
			if r < 0.05:
				var cantidad: int = int(max_enemigos / 2.0)
				_crear_varios_enemigos(cantidad)
			elif r < 0.15:
				var cantidad2: int = max(1, int(round(max_enemigos * 0.2)))
				_crear_varios_enemigos(cantidad2)
			else:
				crear_enemigo()

func _crear_varios_enemigos(cantidad: int) -> void:
	var espacio_disponible: int = max(0, max_enemigos - enemigos_activos)
	var a_crear: int = clamp(cantidad, 0, espacio_disponible)
	for i in range(a_crear):
		crear_enemigo()

func crear_enemigo() -> void:
	var posicion: Vector2 = obtener_posicion_aleatoria()
	var enemigo: Node2D = enemigo_scene.instantiate()
	enemigo.global_position = posicion
	add_child(enemigo)
	enemigos_activos += 1
	enemigo.tree_exited.connect(_enemigo_eliminado)

func _enemigo_eliminado() -> void:
	enemigos_activos = max(0, enemigos_activos - 1)
	if player == true:
		kills += 1
		$CanvasLayer/HBoxContainer/Kills/NK.text = str(kills).pad_zeros(3)
		$sfx_kill.play()
	if kills % 10 == 0:
		$CanvasLayer/sfx_points.play()

# =========================================================
# POSICIÓN ALEATORIA
# =========================================================

func obtener_posicion_aleatoria() -> Vector2:
	for intento in range(max_intentos):
		var posicion: Vector2 = Vector2(
		randf_range(posicion_minima.x, posicion_maxima.x),
		randf_range(posicion_minima.y, posicion_maxima.y))
		if not posicion_en_zona_prohibida(posicion):
			return posicion
	return Vector2(
		randf_range(posicion_minima.x, posicion_maxima.x),
		randf_range(posicion_minima.y, posicion_maxima.y))

# =========================================================
# ZONA PROHIBIDA
# =========================================================

func posicion_en_zona_prohibida(posicion: Vector2) -> bool:
	if zona_prohibida == null:
		return false
	var shape: CollisionShape2D = zona_prohibida.get_node_or_null("CollisionShape2D")
	if shape == null or shape.shape == null:
		return false
	var local_pos: Vector2 = zona_prohibida.to_local(posicion)
	if shape.shape is RectangleShape2D:
		var rect: RectangleShape2D = shape.shape as RectangleShape2D
		var half_extents: Vector2 = rect.extents
		return abs(local_pos.x) <= half_extents.x and abs(local_pos.y) <= half_extents.y
	elif shape.shape is CircleShape2D:
		var circle: CircleShape2D = shape.shape as CircleShape2D
		return local_pos.length() <= circle.radius
	elif shape.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape.shape as CapsuleShape2D
		var radius: float = capsule.radius
		var height: float = capsule.height
		var half_height: float = height / 2.0
		if abs(local_pos.y) > half_height:
			var dist_y: float = abs(local_pos.y) - half_height
			var dist: float = Vector2(local_pos.x, dist_y).length()
			return dist <= radius
		else:
			return abs(local_pos.x) <= radius
	else:
		var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		consulta.shape = shape.shape
		consulta.transform = Transform2D(0, posicion)
		consulta.collide_with_areas = true
		consulta.collide_with_bodies = false
		var resultados: Array = espacio.intersect_shape(consulta)
		for resultado in resultados:
			if resultado.has("collider") and resultado["collider"] == zona_prohibida:
				return true
		return false

# =========================================================
# Tiempo / Dificultad / Guardado
# =========================================================

func _on_timer_timeout() -> void:
	total_time_in_secs += 1
	var m = int(total_time_in_secs / 60.0)
	var s = total_time_in_secs - m * 60
	$CanvasLayer/HBoxContainer/time.text = "%02d:%02d" % [m, s]
	actualizar_dificultad()

func leer_numero_de_txt(ruta: String) -> int:
	var points =0
	if ResourceLoader.exists(ruta):
		var data =load(ruta)
		points =data.max_point
	
	return points

func escribir_numero_en_txt(ruta: String, numero: int) -> void:
	var data := Save.new()
	data.max_point = numero
	ResourceSaver.save(data, ruta)

func save() -> void:
	if leer_numero_de_txt("user://save.tres") < kills:
		escribir_numero_en_txt("user://save.tres", kills)

func _on_child_exiting_tree(child: Node) -> void:
	if child and child.name == "ship":
		player = false
		$sfx_die.play()
		await _await_timer_safe(2.5)
		save()
		get_tree().change_scene_to_file("res://MainMenu.tscn")
		queue_free()

func actualizar_dificultad() -> void:
	var minuto_actual: int = int(total_time_in_secs / 60.0)
	var aumentos_enemigos: int = int(minuto_actual / max(1, minutos_aumento_enemigos))
	max_enemigos = max(1, enemigos_iniciales + (aumentos_enemigos * aumento_max_enemigos))
	var nivel_velocidad_enemigos: int = int(minuto_actual / max(1, minutos_aumento_velocidad))
	var multiplicador_enemigos: float = pow(max(1.0, multiplicador_velocidad_enemigos), nivel_velocidad_enemigos)
	enemigo_tiempo_minimo = max(0.05, 2.0 / multiplicador_enemigos)
	enemigo_tiempo_maximo = max(enemigo_tiempo_minimo, 5.0 / multiplicador_enemigos)
	var multiplicador_meteoritos: float = pow(max(1.0, multiplicador_velocidad_meteoritos), nivel_velocidad_enemigos)
	meteorito_tiempo_minimo = max(0.05, 0.5 / multiplicador_meteoritos)
	meteorito_tiempo_maximo = max(meteorito_tiempo_minimo, 2.0 / multiplicador_meteoritos)
