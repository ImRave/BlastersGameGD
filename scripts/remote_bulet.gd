extends Node2D

@export var velocidad: float = 150.0
@export var rango_busqueda: float = 500.0
@export var tiempo_vida: float = 7.0
@export var radio_impacto: float = 30.0

@onready var sprite: Sprite2D = $Sprite2D

var objetivo: Node2D = null
var direccion: Vector2 = Vector2.RIGHT
var enemigos_cercanos: Array = []

func _ready() -> void:
	print("================================")
	print("BALA INICIADA")
	print("================================")
	
	# Buscar enemigos inmediatamente
	buscar_enemigo()
	
	# Timer para auto-destrucción
	await get_tree().create_timer(tiempo_vida).timeout
	
	if is_inside_tree():
		print("BALA ELIMINADA POR TIEMPO")
		queue_free()

func _physics_process(delta: float) -> void:
	# Si no tenemos objetivo, buscar uno
	if not is_instance_valid(objetivo):
		buscar_enemigo()
		
		# Si no hay enemigos, destruir la bala
		if not is_instance_valid(objetivo):
			print("No hay enemigos, destruyendo bala")
			queue_free()
			return
	
	# Si tenemos un enemigo válido, perseguirlo
	if is_instance_valid(objetivo):
		# Calcular dirección hacia el enemigo
		direccion = global_position.direction_to(objetivo.global_position)
		
		# Verificar si hemos alcanzado al enemigo
		var distancia = global_position.distance_to(objetivo.global_position)
		if distancia < radio_impacto:
			impactar_enemigo()
			return
	
	# Mover la bala
	global_position += direccion * velocidad * delta
	
	# Hacer que el Sprite2D apunte hacia donde se mueve
	if direccion != Vector2.ZERO:
		sprite.rotation = direccion.angle()

func buscar_enemigo() -> void:
	# Buscar todos los nodos en el grupo "enemies" (el grupo que usa tu enemigo)
	var enemigos = get_tree().get_nodes_in_group("enemies")
	
	print("Buscando enemigos... Encontrados: ", enemigos.size())
	
	if enemigos.size() == 0:
		print("⚠️ No hay enemigos en el grupo 'enemies'")
		objetivo = null
		return
	
	# Buscar el enemigo más cercano
	var enemigo_mas_cercano: Node2D = null
	var distancia_menor := INF
	
	for enemigo in enemigos:
		if not is_instance_valid(enemigo):
			continue
		
		var distancia := global_position.distance_to(enemigo.global_position)
		
		# Si el enemigo está dentro del rango de búsqueda
		if distancia < rango_busqueda:
			if distancia < distancia_menor:
				distancia_menor = distancia
				enemigo_mas_cercano = enemigo
	
	if enemigo_mas_cercano != null:
		objetivo = enemigo_mas_cercano
		print("🎯 Enemigo encontrado: ", objetivo.name, " a distancia: ", distancia_menor)
	else:
		objetivo = null
		print("⚠️ No se encontraron enemigos en el rango de búsqueda")

func impactar_enemigo() -> void:
	print("💥 IMPACTO! Destruyendo enemigo y bala")
	
	# Destruir el enemigo
	if is_instance_valid(objetivo):
		# Si el enemigo tiene un método para spawnear puntos, llamarlo
		if objetivo.has_method("disaper"):
			objetivo.disaper()
		else:
			objetivo.queue_free()
	
	# Destruir la bala
	queue_free()

# Método para detectar colisiones por área
func _on_area_2d_area_entered(area: Area2D) -> void:
	print("Área detectada: ", area.name)
	
	# Verificar si el área pertenece a un enemigo
	if area.name == "player" or area.get_parent().name == "enemy":
		# Si el área detectada es el enemigo
		var posible_enemigo = area.get_parent()
		if posible_enemigo.is_in_group("enemies"):
			objetivo = posible_enemigo
			impactar_enemigo()
