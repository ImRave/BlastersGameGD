extends Node2D

@export var tiempo_vida: float = 7.0
@export var escena_al_impactar: PackedScene

var impactado := false


func _ready() -> void:
	$Siprite/AnimationPlayer.play("idel")
	
	await get_tree().create_timer(tiempo_vida).timeout
	
	if not impactado:
		queue_free()


func _on_point_area_entered(area: Area2D) -> void:
	if area.name == "player":
		queue_free()
		return
	
	if area.name == "bulet" and not impactado:
		impactado = true
		
		$Siprite/AnimationPlayer.play("shake")
		
		await get_tree().create_timer(2.0).timeout
		
		crear_bala()
		queue_free()


func crear_bala() -> void:
	if escena_al_impactar == null:
		print("ERROR: No hay escena seleccionada")
		return
	
	var posicion = global_position
	
	# Crear la bala
	var bala = escena_al_impactar.instantiate()
	
	# IMPORTANTE:
	# La ponemos directamente en el ROOT del juego.
	# Así NO puede ser hija del punto.
	get_parent().add_child(bala)
	
	# Colocarla en la posición donde estaba el punto
	bala.global_position = posicion
	
	print("BALA CREADA")
	print("PADRE DE LA BALA: ", bala.get_parent().name)
	print("POSICION: ", bala.global_position)
