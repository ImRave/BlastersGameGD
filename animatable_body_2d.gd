extends AnimatableBody2D
class_name MovimientoEntrePuntos

@export var puntos: Array[Node2D] = []
@export var velocidad: float = 150.0
@export var suavizado_direccion: float = 8.0
@export var suavizado_rotacion: float = 10.0
@export var max_rotacion_grados: float = 60.0
@export var distancia_llegada: float = 10.0

var _indice_actual: int = 0
var _direccion_actual: Vector2 = Vector2.RIGHT

func _ready() -> void:
	if puntos.size() < 2:
		push_warning("Necesitas al menos 2 puntos.")
		set_physics_process(false)
		return
	global_position = puntos[0].global_position
	_direccion_actual = (puntos[1].global_position - global_position).normalized()

func _physics_process(delta: float) -> void:
	if puntos.size() < 2:
		return
	
	# 1) Avanza de índice si ya pasamos el waypoint (por proyección)
	_actualizar_objetivo()
	
	var objetivo: Node2D = puntos[_indice_actual]
	var hacia_objetivo: Vector2 = objetivo.global_position - global_position
	var direccion_deseada: Vector2 = hacia_objetivo.normalized()
	
	# 2) Suavizar dirección SIN que la magnitud caiga a cero
	var t: float = clamp(suavizado_direccion * delta, 0.0, 1.0)
	_direccion_actual = _direccion_actual.slerp(direccion_deseada, t)
	if _direccion_actual.length_squared() > 0.0001:
		_direccion_actual = _direccion_actual.normalized()
	else:
		_direccion_actual = direccion_deseada
	
	# 3) Mover SIEMPRE a velocidad constante (nunca se frena)
	global_position += _direccion_actual * velocidad * delta
	
	# 4) Rotación limitada (±max_rotacion_grados respecto al objetivo)
	var angulo_vel: float = _direccion_actual.angle()
	var angulo_dir: float = direccion_deseada.angle()
	var dif: float = wrapf(angulo_vel - angulo_dir, -PI, PI)
	var max_rad: float = deg_to_rad(max_rotacion_grados)
	dif = clamp(dif, -max_rad, max_rad)
	rotation = lerp_angle(rotation, angulo_dir + dif, clamp(suavizado_rotacion * delta, 0.0, 1.0))

func _actualizar_objetivo() -> void:
	# Repite el chequeo varias veces por si en un frame se superan 2+ waypoints
	for _i in range(puntos.size()):
		var objetivo: Node2D = puntos[_indice_actual]
		var hacia: Vector2 = objetivo.global_position - global_position
		var dist: float = hacia.length()
		# Si estamos cerca O ya lo pasamos (proyección negativa) → siguiente
		if dist < distancia_llegada:
			_indice_actual = (_indice_actual + 1) % puntos.size()
			continue
		if dist > 0.001 and hacia.normalized().dot(_direccion_actual) < 0.0:
			_indice_actual = (_indice_actual + 1) % puntos.size()
			continue
		break
