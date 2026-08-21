extends StaticBody2D

# Escena que se va a generar (asignar desde el inspector)
@export var scene_to_spawn: PackedScene

# Tiempos de spawn (cada 10-20 segundos)
@export var min_spawn_time: float = 10.0
@export var max_spawn_time: float = 20.0

# Referencia al CollisionShape2D para definir el área de spawn
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0

func _ready():
	# Configurar el primer tiempo de spawn
	randomize()
	set_next_spawn_time()
	
	# Verificar que se asignó una escena
	if scene_to_spawn == null:
		push_warning("No se asignó una escena para generar en scene_to_spawn")

func _process(delta: float) -> void:
	spawn_timer += delta
	
	# Verificar si es tiempo de generar una nueva instancia
	if spawn_timer >= next_spawn_time:
		spawn_random_instance()
		spawn_timer = 0.0
		set_next_spawn_time()

# Generar una instancia en posición aleatoria dentro del área
func spawn_random_instance() -> void:
	if scene_to_spawn == null:
		return
	
	# Crear la instancia y agregarla como HERMANA (mismo padre)
	var new_instance = scene_to_spawn.instantiate()
	get_parent().add_child(new_instance)  # Agregar al padre de este StaticBody2D
	
	# Posicionar aleatoriamente dentro del área
	var random_position = get_random_position_in_area()
	new_instance.global_position = random_position
	
	print("Instancia generada como hermana en posición: ", random_position)

# Obtener una posición aleatoria dentro del área del CollisionShape2D
func get_random_position_in_area() -> Vector2:
	if collision_shape == null:
		return global_position
	
	var shape = collision_shape.shape
	
	if shape is RectangleShape2D:
		return get_random_position_in_rectangle(shape)
	elif shape is CircleShape2D:
		return get_random_position_in_circle(shape)
	elif shape is CapsuleShape2D:
		return get_random_position_in_capsule(shape)
	else:
		# Para otras formas, devolver posición central
		push_warning("Forma de colisión no soportada, usando posición central")
		return global_position

# Posición aleatoria en rectángulo
func get_random_position_in_rectangle(rect_shape: RectangleShape2D) -> Vector2:
	var rect_size = rect_shape.size
	var half_width = rect_size.x / 2.0
	var half_height = rect_size.y / 2.0
	
	var random_x = randf_range(-half_width, half_width)
	var random_y = randf_range(-half_height, half_height)
	
	return global_position + Vector2(random_x, random_y)

# Posición aleatoria en círculo
func get_random_position_in_circle(circle_shape: CircleShape2D) -> Vector2:
	var radius = circle_shape.radius
	var random_angle = randf_range(0, TAU)
	var random_distance = randf_range(0, radius)
	
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	return global_position + offset

# Posición aleatoria en cápsula
func get_random_position_in_capsule(capsule_shape: CapsuleShape2D) -> Vector2:
	var radius = capsule_shape.radius
	var height = capsule_shape.height
	
	# Decidir si spawnear en los semicírculos o en el rectángulo central
	var area_choice = randf()
	
	if area_choice < 0.5:
		# Spawn en semicírculo superior
		var random_angle = randf_range(0, PI)
		var random_distance = randf_range(0, radius)
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
		return global_position + offset - Vector2(0, height / 2)
	else:
		# Spawn en semicírculo inferior
		var random_angle = randf_range(PI, TAU)
		var random_distance = randf_range(0, radius)
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
		return global_position + offset + Vector2(0, height / 2)

# Configurar el próximo tiempo de spawn
func set_next_spawn_time() -> void:
	next_spawn_time = randf_range(min_spawn_time, max_spawn_time)
	print("Próximo spawn en: ", next_spawn_time, " segundos")

# Función para cambiar la escena a generar dinámicamente
func set_spawn_scene(new_scene: PackedScene) -> void:
	scene_to_spawn = new_scene
	print("Escena de spawn cambiada")

# Función para forzar un spawn manualmente
func force_spawn() -> void:
	spawn_random_instance()
	spawn_timer = 0.0
	set_next_spawn_time()

# Función para cambiar los tiempos de spawn
func set_spawn_times(new_min_time: float, new_max_time: float) -> void:
	min_spawn_time = new_min_time
	max_spawn_time = new_max_time
	set_next_spawn_time()
