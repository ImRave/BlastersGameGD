extends Control

func leer_numero_de_txt(ruta: String) -> int:
	var points =0
	if ResourceLoader.exists(ruta):
		var data =load(ruta)
		points =data.max_point
	
	return points
	
func _ready() -> void:
	$HBoxContainer/Kills/NK.text = str(leer_numero_de_txt("user://save.tres")).pad_zeros(3)
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
