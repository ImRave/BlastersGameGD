extends RigidBody2D

@export var velocidad: float = 400.0
@export var tiempo_vida: float = 15.0
@export var rebote: float = 0.9
@export var friccion: float = 0.1
@export var desviacion_maxima: float = 0.3  # Ángulo máximo de desviación en radianes

# --- NUEVAS VARIABLES PARA VELOCIDAD DE ROTACIÓN ALEATORIA ---
@export var rotacion_velocidad_min: float = -3.0  # Velocidad mínima de rotación (rad/s)
@export var rotacion_velocidad_max: float = 3.0   # Velocidad máxima de rotación (rad/s)
@export var usar_rotacion_aleatoria: bool = true  # Activar/desactivar rotación aleatoria

var direccion: Vector2 = Vector2.ZERO
var punto_destino: Vector2 = Vector2(413.5, 230.5)  # Punto fijo de destino
var desviacion_aplicada: float = 0.0
var punto_destino_original: Vector2 = Vector2(413.5, 230.5)
var velocidad_rotacion_actual: float = 0.0  # Velocidad de rotación actual
# Definir los pesos para cada valor de X (0,1,2,3)
@export var pesos_de_probabilidad_x = [33, 33, 33, 1]  # El índice 0 tiene peso 10, índice 1 peso 30, etc.
# El total es 10+30+40+20 = 100 (puedes usar cualquier número)
	
func _on_area_entered (area: Area2D) -> void:
	if area.name =="bulet":
		print("Destruir")
		queue_free()
		
func get_weighted_x() -> int:
	var total_pesos = 0
	for peso in pesos_de_probabilidad_x:
		total_pesos += peso

	var aleatorio = randi_range(0, total_pesos - 1)
	var acumulado = 0
	for i in range(pesos_de_probabilidad_x.size()):
		acumulado += pesos_de_probabilidad_x[i]
		if aleatorio < acumulado:
			return i
	return pesos_de_probabilidad_x.size() - 1
		
func _ready() -> void:
	$Sprite2D.frame_coords = Vector2(get_weighted_x(), randi_range(0,1))
	
	# Material físico
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.bounce = rebote
	material.friction = friccion
	physics_material_override = material

	# Configuración de colisiones
	collision_layer = 2
	collision_mask = 2

	# -----------------------------
	# GENERAR VELOCIDAD DE ROTACIÓN ALEATORIA
	# -----------------------------
	if usar_rotacion_aleatoria:
		velocidad_rotacion_actual = randf_range(rotacion_velocidad_min, rotacion_velocidad_max)
		angular_velocity = velocidad_rotacion_actual
		
		print("Velocidad de rotación asignada: ", velocidad_rotacion_actual, " rad/s")
		print("Rotación en grados/segundo: ", rad_to_deg(velocidad_rotacion_actual), "°/s")
	else:
		angular_velocity = 0.0

	# -----------------------------
	# USAR PUNTO DE DESTINO FIJO (413.5, 230.5)
	# -----------------------------

	var punto_origen: Vector2 = global_position
	
	# El punto de destino ahora es fijo
	punto_destino = Vector2(413.5, 230.5)
	punto_destino_original = punto_destino  # Guardar para debugging
	
	# 1. APLICAR DESVIACIÓN ALEATORIA AL PUNTO DE DESTINO
	var angulo_desviacion: float = randf_range(-desviacion_maxima, desviacion_maxima)
	desviacion_aplicada = angulo_desviacion
	
	# Calcular la desviación como un pequeño desplazamiento
	var distancia_al_destino: float = punto_origen.distance_to(punto_destino)
	var vector_desviacion: Vector2 = Vector2(1, 0).rotated(angulo_desviacion) * (distancia_al_destino * 0.03)
	punto_destino += vector_desviacion
	
	# 2. CALCULAR DIRECCIÓN FINAL
	var vector_direccion: Vector2 = punto_destino - punto_origen

	# Evitar normalizar un vector de longitud 0
	if vector_direccion.length() > 0.0:
		direccion = vector_direccion.normalized()
	else:
		direccion = Vector2.RIGHT

	# -----------------------------
	# DAR VELOCIDAD AL OBJETO
	# -----------------------------

	linear_velocity = direccion * velocidad
	
	# -----------------------------
	# DEBUG: MOSTRAR INFORMACIÓN
	# -----------------------------
	print("=== INFORMACIÓN DE LA BALA ===")
	print("Origen: ", punto_origen)
	print("Destino original: ", punto_destino_original)
	print("Destino con desviación: ", punto_destino)
	print("Desviación aplicada: ", rad_to_deg(desviacion_aplicada), "°")
	print("Dirección final: ", direccion)
	print("Velocidad: ", linear_velocity)
	print("Velocidad de rotación: ", velocidad_rotacion_actual, " rad/s (", rad_to_deg(velocidad_rotacion_actual), "°/s)")
	
	# Dibujar una línea de debug (opcional)
	draw_debug_line()

	# -----------------------------
	# TIEMPO DE VIDA
	# -----------------------------

	var timer: Timer = Timer.new()
	timer.wait_time = tiempo_vida
	timer.one_shot = true
	timer.timeout.connect(queue_free)

	add_child(timer)
	timer.start()

	# -----------------------------
	# COLISIONES
	# -----------------------------

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Opcional: Si quieres que la rotación cambie gradualmente durante el vuelo
	if usar_rotacion_aleatoria:
		# La velocidad angular ya está aplicada, pero puedes añadir efectos extra
		# Por ejemplo, cambiar la rotación si la bala se está frenando
		pass


func _on_body_entered(body: Node) -> void:

	if body is RigidBody2D and body != self:

		# Comprobar que el otro objeto está en la capa 2
		if body.collision_layer & 2:

			var vector_entre: Vector2 = global_position - body.global_position

			if vector_entre.length() > 0.0:

				var direccion_impacto: Vector2 = vector_entre.normalized()

				var velocidad_relativa: Vector2 = linear_velocity - body.linear_velocity

				# Solo reaccionar si se están acercando
				if velocidad_relativa.dot(direccion_impacto) < 0.0:

					var fuerza_impacto: float = 100.0

					apply_impulse(
						direccion_impacto * fuerza_impacto
					)

					body.apply_impulse(
						-direccion_impacto * fuerza_impacto
					)


# --- FUNCIÓN DE DEBUG PARA DIBUJAR LÍNEA (OPCIONAL) ---
func draw_debug_line() -> void:
	# Esta función dibuja una línea desde la bala hasta el destino
	# Útil para depuración visual
	
	if not Engine.is_editor_hint():
		# Crear un nodo Line2D temporal (requiere tener Line2D en la escena)
		var line := Line2D.new()
		line.width = 2
		line.default_color = Color(1, 0, 0, 0.5)  # Rojo semitransparente
		line.add_point(Vector2.ZERO)
		line.add_point((punto_destino - global_position) * 0.01)
		add_child(line)
		
		# Auto-eliminar la línea después de 0.1 segundos
		var timer := Timer.new()
		timer.wait_time = 0.1
		timer.one_shot = true
		timer.timeout.connect(line.queue_free)
		add_child(timer)
		timer.start()


# --- FUNCIÓN PARA CAMBIAR LA ROTACIÓN DURANTE EL JUEGO (OPCIONAL) ---
func cambiar_rotacion(nueva_velocidad: float) -> void:
	# Esta función permite cambiar la velocidad de rotación en tiempo real
	angular_velocity = nueva_velocidad
	velocidad_rotacion_actual = nueva_velocidad
	print("Rotación cambiada a: ", nueva_velocidad, " rad/s")


# --- FUNCIÓN PARA APLICAR UN GIRO REPENTINO (OPCIONAL) ---
func aplicar_giro_repentino(fuerza_rotacion: float) -> void:
	# Añade un impulso de rotación repentino (útil para efectos especiales)
	angular_velocity += fuerza_rotacion
	print("Giro repentino aplicado: ", fuerza_rotacion)


# --- FUNCIÓN PARA MOSTRAR ESTADO ACTUAL ---
func mostrar_estado() -> void:
	print("=== ESTADO ACTUAL DE LA BALA ===")
	print("Posición: ", global_position)
	print("Velocidad lineal: ", linear_velocity)
	print("Velocidad angular: ", angular_velocity, " rad/s (", rad_to_deg(angular_velocity), "°/s)")
	print("Dirección: ", direccion)
	print("Destino: ", punto_destino)
