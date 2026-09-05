extends Control

func leer_numero_de_txt(ruta: String) -> int:
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		print("Error: No se pudo abrir el archivo")
		return 0
	
	var contenido = archivo.get_as_text()
	archivo.close()
	
	# Limpiar espacios y convertir a entero
	var numero = int(contenido.strip_edges())
	return numero
	
func _ready() -> void:
	$HBoxContainer/Kills/NK.text = str(leer_numero_de_txt("res://saves/Kills.txt")).pad_zeros(3)
	pass
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_options_pressed() -> void:
	$TextureRect2.visible = true
	await get_tree().create_timer(0.2).timeout
	$TextureRect2.visible = false


func _on_leave_pressed() -> void:
	$TextureRect2.visible = true
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
