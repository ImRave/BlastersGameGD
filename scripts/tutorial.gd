extends Node

# ==================== REFERENCIAS ====================
@onready var label_mensaje: Label = $Control/ColorRect/text
# Sin tipo estático a propósito: funciona sea AudioStreamPlayer o AudioStreamPlayer2D
@onready var sfx_letter = $sfx_letter
@onready var sfx_steps = $sfx_steps
@onready var sfx_butom = $sfx_butom

# ==================== EXPORTS ====================
# (se mantienen los nombres originales para no perder las asignaciones del editor)
@export var opstacles: PackedScene
@export var enemies: PackedScene
@export var dodged_opstacles := 0
@export var enemies_killed := 0
## Segundos entre letra y letra
@export var velocidad_escritura: float = 0.04
## Puntos de aparición de obstáculos y enemigos
@export var spanw_poins: Array[Node2D] = []

@export_group("Escenas")
@export_file("*.tscn") var escena_principal: String = "res://main.tscn"
## IMPORTANTE: ajusta esta ruta a tu escena de menú principal
@export_file("*.tscn") var escena_menu: String = "res://menu_principal.tscn"

@export_group("Jugador (ship)")
## Opcional: si lo dejas vacío se busca el nodo "ship" (o el grupo "ship") automáticamente
@export var ship: Node2D
## Opcional: escena del ship para reaparecer. Si lo dejas vacío se usa la escena del ship original
@export var ship_scene: PackedScene
## Escala con la que reaparece el ship tras morir en la fase de enemigos
@export var escala_reaparicion := Vector2(1.5, 1.5)
## Segundos de pausa entre la muerte y la reaparición
@export var retraso_reaparicion: float = 0.8

@export_group("Salir con ESC")
## Acción de Input que sirve para salir (ui_cancel = ESC por defecto en Godot)
@export var accion_salir: StringName = &"ui_cancel"
## Segundos que hay que mantener la tecla para volver al menú
@export var tiempo_salida: float = 5.0
## Opcional: ProgressBar que muestra cuánto falta para salir
@export var barra_salida: ProgressBar
## ColorRect que se va poniendo rojo (más alpha) mientras mantienes la tecla
@export var rect_salida: ColorRect
## Alpha que alcanza el rojo al llegar al tiempo de salida (0.0 a 1.0)
@export_range(0.0, 1.0, 0.05) var alpha_maximo: float = 0.8

@export_group("Debug")
@export var debug_logs := false

# ==================== CONSTANTES ====================
enum Fase { CONTROLES, OBSTACULOS, ENEMIGOS, COMPLETADO }

const OBSTACULOS_TOTALES := 5
const ENEMIGOS_TOTALES := 5
const TIEMPO_VIDA_TUTORIAL := 5.0
const PAUSA_ENTRE_OBSTACULOS := 0.5

# Pasos del tutorial: mensaje del Label + acción de Input requerida
const PASOS := [
	{"mensaje": "Presiona la tecla W para avanzar.", "accion": "move_up"},
	{"mensaje": "¡Bien! Ahora presiona la tecla S para Retroceder.", "accion": "move_down"},
	{"mensaje": "Perfecto. Ahora presiona la tecla A para rotar a la izquierda.", "accion": "move_left"},
	{"mensaje": "Muy bien. Ahora presiona la tecla D para rotar a la derecha.", "accion": "move_right"},
	{"mensaje": "¡Excelente! Presiona la tecla de DISPARO (Espacio / Click).", "accion": "shoot"},
	{"mensaje": "Acóplate a los controles y cuando estés listo presiona ENTER para continuar.", "accion": "enter"},
]

# ==================== ESTADO ====================
var fase_actual: Fase = Fase.CONTROLES
var paso_actual := 0
var escribiendo := false          # Hay texto escribiéndose
var transicionando := false       # Bloquea el input durante transiciones
var tutorial_terminado := false   # true solo al completar todo
var obstaculos_invocados := 0

var obstaculo_actual: Node2D = null
var _obstaculo_token := 0         # Invalida timers de obstáculos antiguos
var _escritura_token := 0         # Cancela escrituras antiguas
var _esperando_enter := false     # Fin de fase de obstáculos: falta ENTER
var _saliendo := false            # Ya se está cambiando de escena
var _tiempo_escape := 0.0

# Enemigos y reinicio por muerte del ship
var _enemigos: Array[Node2D] = []
var _reinicio_token := 0          # Invalida reinicios antiguos si el ship muere dos veces
var _ship_scene_path := ""        # Escena original del ship (para reaparecerlo)
var _ship_nombre := ""
var _ship_padre: Node = null
var _posicion_muerte := Vector2.ZERO


# ==================== CICLO DE VIDA ====================
func _ready() -> void:
	add_to_group("tutorial")
	_validar_configuracion()
	if barra_salida:
		barra_salida.max_value = tiempo_salida
		barra_salida.value = 0.0
		barra_salida.visible = false
	if rect_salida:
		rect_salida.mouse_filter = Control.MOUSE_FILTER_IGNORE  # No bloquea clics
		rect_salida.color = Color(1, 0, 0, 0)  # Rojo puro, invisible al inicio
	_buscar_ship()
	_log("=== INICIANDO TUTORIAL DE MOVIMIENTO Y DISPARO ===")
	_mostrar_paso_actual()


func _process(delta: float) -> void:
	_procesar_salida_con_escape(delta)


func _validar_configuracion() -> void:
	for paso in PASOS:
		if not InputMap.has_action(paso["accion"]):
			push_warning("Tutorial: la acción '%s' no existe en el Input Map." % paso["accion"])
	if not InputMap.has_action(accion_salir):
		push_warning("Tutorial: la acción de salida '%s' no existe en el Input Map." % accion_salir)
	if opstacles == null:
		push_warning("Tutorial: 'opstacles' no está asignado.")
	if enemies == null:
		push_warning("Tutorial: 'enemies' no está asignado.")
	if spanw_poins.is_empty():
		push_warning("Tutorial: no hay puntos de aparición (spanw_poins).")


# ==================== SALIR CON ESC (mantener 5 s) ====================
func _procesar_salida_con_escape(delta: float) -> void:
	if _saliendo:
		return

	if Input.is_action_pressed(accion_salir):
		if _tiempo_escape == 0.0:
			_iniciar_sonido_salida()
		_tiempo_escape += delta
		_actualizar_barra_salida()
		if _tiempo_escape >= tiempo_salida:
			_tiempo_escape = 0.0
			_actualizar_barra_salida()
			_detener_sonido_salida()
			_log("-> Saliendo al menú principal...")
			_ir_a_escena(escena_menu)

	elif _tiempo_escape > 0.0:
		_tiempo_escape = 0.0
		_actualizar_barra_salida()
		_detener_sonido_salida()


func _actualizar_barra_salida() -> void:
	if barra_salida:
		barra_salida.value = _tiempo_escape
		barra_salida.visible = _tiempo_escape > 0.0
	if rect_salida:
		# Siempre rojo puro; solo cambia la opacidad según el tiempo mantenido
		var progreso := clampf(_tiempo_escape / tiempo_salida, 0.0, 1.0)
		rect_salida.color = Color(1, 0, 0, progreso * alpha_maximo)


func _ir_a_escena(ruta: String) -> void:
	if _saliendo:
		return
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		push_error("Tutorial: la escena '%s' no existe." % ruta)
		return
	_saliendo = true

	var err := get_tree().change_scene_to_file(ruta)
	if err != OK:
		push_error("Tutorial: no se pudo cambiar a '%s' (error %d)." % [ruta, err])
		_saliendo = false


func _iniciar_sonido_salida() -> void:
	if sfx_butom == null:
		return
	# Pitch para que 0.37 s de audio duren exactamente tiempo_salida segundos.
	# pitch = duracion_original / duracion_deseada
	var pitch := 0.37 / maxf(tiempo_salida, 0.01)
	sfx_butom.pitch_scale = pitch
	sfx_butom.play()


func _detener_sonido_salida() -> void:
	if sfx_butom == null:
		return
	sfx_butom.stop()
	sfx_butom.pitch_scale = 1.0  # Restaura el pitch por defecto


# ==================== ESCRITURA ====================
## Escribe el texto letra a letra. Una escritura nueva cancela la anterior,
## así nunca se mezclan ni se encolan mensajes viejos.
func escribir_texto(texto: String, instantaneo := false) -> void:
	_escritura_token += 1
	var token := _escritura_token

	label_mensaje.text = texto

	if instantaneo:
		label_mensaje.visible_characters = -1
		escribiendo = false
		return

	escribiendo = true
	label_mensaje.visible_characters = 0

	for i in texto.length():
		await get_tree().create_timer(velocidad_escritura).timeout
		if token != _escritura_token or not is_inside_tree():
			return  # Otra escritura tomó el control (o salimos de la escena)
		label_mensaje.visible_characters = i + 1
		if texto[i] != " ":
			sfx_letter.play()

	label_mensaje.visible_characters = -1
	escribiendo = false


# ==================== FASE 1: CONTROLES ====================
func _mostrar_paso_actual() -> void:
	if paso_actual < PASOS.size():
		var datos = PASOS[paso_actual]
		_log("[TUTORIAL]: %s (acción: %s)" % [datos["mensaje"], datos["accion"]])
		escribir_texto(datos["mensaje"])
	else:
		iniciar_fase_obstaculos()


func _procesar_controles(event: InputEvent) -> void:
	if paso_actual >= PASOS.size():
		return
	if not event.is_action_pressed(PASOS[paso_actual]["accion"]):
		return

	_log("-> ¡Acción correcta detectada!")
	# Bloqueamos ANTES del await para que un doble toque no salte dos pasos
	transicionando = true
	await get_tree().create_timer(0.25).timeout
	if not _activo():
		return
	sfx_steps.play()
	paso_actual += 1
	transicionando = false
	_mostrar_paso_actual()


# ==================== FASE 2: OBSTÁCULOS ====================
func iniciar_fase_obstaculos() -> void:
	transicionando = true
	fase_actual = Fase.OBSTACULOS
	dodged_opstacles = 0
	obstaculos_invocados = 0
	_obstaculo_token += 1
	_esperando_enter = false
	await escribir_texto(_texto_obstaculos())
	if not _activo():
		return
	transicionando = false
	await get_tree().create_timer(1.0).timeout
	if _activo():
		_invocar_obstaculo()


func _texto_obstaculos() -> String:
	return "Esquiva los obstáculos: %d/%d" % [dodged_opstacles, OBSTACULOS_TOTALES]


func _actualizar_label_obstaculos() -> void:
	# Instantáneo: el contador no debe reescribirse letra a letra en cada cambio
	escribir_texto(_texto_obstaculos(), true)


func _invocar_obstaculo() -> void:
	if fase_actual != Fase.OBSTACULOS or dodged_opstacles >= OBSTACULOS_TOTALES:
		return
	if obstaculo_actual != null:
		return  # Ya hay uno activo
	if opstacles == null:
		push_error("Tutorial: no se puede invocar obstáculos, 'opstacles' es null.")
		return

	_obstaculo_token += 1
	var token := _obstaculo_token

	var nuevo := opstacles.instantiate() as Node2D
	if nuevo == null:
		push_error("Tutorial: la escena de obstáculo debe tener un Node2D como raíz.")
		return
	if "tiempo_vida" in nuevo:
		nuevo.tiempo_vida = TIEMPO_VIDA_TUTORIAL

	get_tree().current_scene.add_child(nuevo)
	_colocar_en_spawn(nuevo, obstaculos_invocados)

	obstaculo_actual = nuevo
	obstaculos_invocados += 1
	_log("[TUTORIAL] Obstáculo invocado #%d — esquivados %d/%d" % [obstaculos_invocados, dodged_opstacles, OBSTACULOS_TOTALES])

	await get_tree().create_timer(TIEMPO_VIDA_TUTORIAL).timeout

	# Si el token cambió (choque o esquive manual) o cambió la fase, no contamos
	if not _activo() or token != _obstaculo_token or fase_actual != Fase.OBSTACULOS:
		return
	_resolver_obstaculo(true)


## Punto único de resolución: evita contar doble o invocar dos obstáculos a la vez.
func _resolver_obstaculo(esquivado: bool) -> void:
	if fase_actual != Fase.OBSTACULOS or obstaculo_actual == null:
		return

	_obstaculo_token += 1  # Invalida el timer pendiente

	if esquivado:
		dodged_opstacles += 1
		_log("[TUTORIAL] Obstáculo esquivado: %d/%d" % [dodged_opstacles, OBSTACULOS_TOTALES])
	else:
		dodged_opstacles = 0
		_log("[TUTORIAL] ¡Choque! Contador reiniciado.")

	_actualizar_label_obstaculos()

	if is_instance_valid(obstaculo_actual):
		obstaculo_actual.queue_free()
	obstaculo_actual = null

	if dodged_opstacles >= OBSTACULOS_TOTALES:
		_finalizar_fase_obstaculos()
		return

	await get_tree().create_timer(PAUSA_ENTRE_OBSTACULOS).timeout
	if _activo():
		_invocar_obstaculo()


## Llamar desde el obstáculo si detecta que fue esquivado antes de los 5 s.
func obstaculo_esquivado() -> void:
	_resolver_obstaculo(true)


## Llamar desde el jugador cuando choque con un obstáculo durante el tutorial.
func obstaculo_chocado() -> void:
	_resolver_obstaculo(false)


func _finalizar_fase_obstaculos() -> void:
	transicionando = true
	await get_tree().create_timer(0.6).timeout  # Deja ver el 5/5
	if not _activo():
		return
	await escribir_texto("¡Excelente! Has esquivado todos los obstáculos.")
	if not _activo():
		return
	await get_tree().create_timer(0.5).timeout
	if not _activo():
		return
	await escribir_texto("Presiona ENTER para continuar con la siguiente parte.")
	if not _activo():
		return
	_esperando_enter = true
	transicionando = false


# ==================== FASE 3: ENEMIGOS ====================
func iniciar_fase_enemigos() -> void:
	transicionando = true
	_esperando_enter = false
	fase_actual = Fase.ENEMIGOS
	enemies_killed = 0
	await escribir_texto(_texto_enemigos())
	if not _activo():
		return
	transicionando = false
	await get_tree().create_timer(1.0).timeout
	if _activo():
		_invocar_enemigos()


func _texto_enemigos() -> String:
	return "Destruye a los enemigos: %d/%d" % [enemies_killed, ENEMIGOS_TOTALES]


func _actualizar_label_enemigos() -> void:
	escribir_texto(_texto_enemigos(), true)


func _invocar_enemigos() -> void:
	if enemies == null:
		push_error("Tutorial: no se pueden invocar enemigos, 'enemies' es null.")
		return

	_enemigos.clear()
	for i in ENEMIGOS_TOTALES:
		var nuevo := enemies.instantiate() as Node2D
		if nuevo == null:
			push_error("Tutorial: la escena de enemigo debe tener un Node2D como raíz.")
			return

		get_tree().current_scene.add_child(nuevo)
		_colocar_en_spawn(nuevo, i)
		_enemigos.append(nuevo)

		# CONNECT_ONE_SHOT evita contar dos veces al mismo enemigo.
		# Los parámetros opcionales de _on_enemigo_died aceptan señales con argumentos.
		if nuevo.has_signal("died"):
			nuevo.connect("died", _on_enemigo_died, CONNECT_ONE_SHOT)
		elif nuevo.has_signal("destroyed"):
			nuevo.connect("destroyed", _on_enemigo_died, CONNECT_ONE_SHOT)
		else:
			nuevo.tree_exited.connect(_on_enemigo_died, CONNECT_ONE_SHOT)
		_log("[TUTORIAL] Enemigo invocado: %d/%d" % [i + 1, ENEMIGOS_TOTALES])


func _on_enemigo_died(_a = null, _b = null) -> void:
	if _saliendo or not is_inside_tree() or fase_actual != Fase.ENEMIGOS:
		return

	enemies_killed += 1
	_log("[TUTORIAL] Enemigo destruido: %d/%d" % [enemies_killed, ENEMIGOS_TOTALES])
	_actualizar_label_enemigos()

	if enemies_killed >= ENEMIGOS_TOTALES:
		_finalizar_tutorial()


## Elimina los enemigos que queden SIN que cuenten como derrotados.
func _limpiar_enemigos() -> void:
	for e in _enemigos:
		if not is_instance_valid(e):
			continue
		for senal in [&"died", &"destroyed", &"tree_exited"]:
			if e.has_signal(senal) and e.is_connected(senal, _on_enemigo_died):
				e.disconnect(senal, _on_enemigo_died)
		e.queue_free()
	_enemigos.clear()


func _finalizar_tutorial() -> void:
	transicionando = true
	fase_actual = Fase.COMPLETADO
	tutorial_terminado = true
	await get_tree().create_timer(0.6).timeout  # Deja ver el 5/5
	if not _activo():
		return
	await escribir_texto("¡Felicidades! Has completado el tutorial. Presiona ENTER para comenzar.")
	if _activo():
		transicionando = false


# ==================== MUERTE DEL SHIP Y REINICIO DE ENEMIGOS ====================
func _buscar_ship() -> void:
	if ship == null or not is_instance_valid(ship):
		var escena := get_tree().current_scene
		ship = get_tree().get_first_node_in_group("ship") as Node2D
		if ship == null and escena:
			ship = escena.find_child("ship", true, false) as Node2D
	if ship == null:
		push_warning("Tutorial: no se encontró el nodo 'ship'; no se podrá reaparecer al morir.")
		return
	_conectar_ship(ship)


func _conectar_ship(nave: Node2D) -> void:
	ship = nave
	if _ship_scene_path.is_empty():
		_ship_scene_path = nave.scene_file_path
	_ship_nombre = nave.name
	# tree_exiting se emite justo antes de salir del árbol: la posición aún es válida
	nave.tree_exiting.connect(_on_ship_saliendo.bind(nave), CONNECT_ONE_SHOT)


func _on_ship_saliendo(nave: Node2D) -> void:
	# Solo cuenta si muere durante la fase de enemigos (no al cambiar de escena)
	if not _activo() or fase_actual != Fase.ENEMIGOS:
		return

	_posicion_muerte = nave.global_position
	_ship_padre = nave.get_parent()
	_log("[TUTORIAL] Ship destruido en %s. Reiniciando fase de enemigos." % str(_posicion_muerte))

	_reinicio_token += 1
	_reiniciar_fase_enemigos.call_deferred(_reinicio_token)


func _reiniciar_fase_enemigos(token: int) -> void:
	if not _activo() or fase_actual != Fase.ENEMIGOS:
		return

	transicionando = true
	_limpiar_enemigos()
	enemies_killed = 0

	await escribir_texto("¡Has sido destruido! Reiniciando la prueba...")
	if not _activo() or token != _reinicio_token:
		return
	await get_tree().create_timer(retraso_reaparicion).timeout
	if not _activo() or token != _reinicio_token:
		return

	_reaparecer_ship()

	await escribir_texto(_texto_enemigos())
	if not _activo() or token != _reinicio_token:
		return
	transicionando = false
	await get_tree().create_timer(1.0).timeout
	if not _activo() or token != _reinicio_token or fase_actual != Fase.ENEMIGOS:
		return
	_invocar_enemigos()


func _reaparecer_ship() -> void:
	var escena: PackedScene = ship_scene
	if escena == null and not _ship_scene_path.is_empty():
		escena = load(_ship_scene_path) as PackedScene
	if escena == null:
		push_error("Tutorial: no hay escena del ship para reaparecer. Asigna 'ship_scene' o guarda el ship como escena.")
		return

	var nuevo := escena.instantiate() as Node2D
	if nuevo == null:
		push_error("Tutorial: la escena del ship debe tener un Node2D como raíz.")
		return

	if not _ship_nombre.is_empty():
		nuevo.name = _ship_nombre
	var padre: Node = _ship_padre if is_instance_valid(_ship_padre) else get_tree().current_scene
	padre.add_child(nuevo)
	nuevo.global_position = _posicion_muerte
	nuevo.scale = escala_reaparicion

	_conectar_ship(nuevo)  # Vuelve a vigilar al nuevo ship
	_log("[TUTORIAL] Ship reaparecido en %s con escala %s" % [str(_posicion_muerte), str(escala_reaparicion)])


# ==================== INPUT ====================
func _input(event: InputEvent) -> void:
	if _saliendo or escribiendo or transicionando or event.is_echo():
		return

	match fase_actual:
		Fase.CONTROLES:
			_procesar_controles(event)
		Fase.OBSTACULOS:
			if _esperando_enter and event.is_action_pressed("enter"):
				_log("-> Continuando a la fase de enemigos...")
				sfx_steps.play()
				iniciar_fase_enemigos()
		Fase.COMPLETADO:
			if event.is_action_pressed("enter"):
				_log("-> Cambiando a la escena principal...")
				_ir_a_escena(escena_principal)


# ==================== UTILIDADES ====================
func _colocar_en_spawn(nodo: Node2D, indice: int) -> void:
	if spanw_poins.is_empty():
		return
	var punto := spanw_poins[indice % spanw_poins.size()]
	if is_instance_valid(punto):
		nodo.global_position = punto.global_position


## false si el nodo ya salió del árbol o se está cambiando de escena.
func _activo() -> bool:
	return is_inside_tree() and not _saliendo


func _log(mensaje: String) -> void:
	if debug_logs:
		print(mensaje)
