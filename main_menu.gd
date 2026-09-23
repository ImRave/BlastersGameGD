extends Control

func leer_numero_de_txt(ruta: String) -> int:
	var points =0
	if ResourceLoader.exists(ruta):
		var data =load(ruta)
		points =data.max_point
	
	return points
	
func _ready() -> void:
	$sfx_MainMenu.playing =true
	$HBoxContainer/Kills/NK.text = str(leer_numero_de_txt("user://save.tres")).pad_zeros(3)
	pass
func _on_play_pressed() -> void:
	$sfx_PressStart.play()
	get_tree().change_scene_to_file("res://main.tscn")


func _on_options_pressed() -> void:
	$sfx_PressButons.play()
	$TextureRect2.visible = true
	await get_tree().create_timer(0.2).timeout
	$TextureRect2.visible = false


func _on_leave_pressed() -> void:
	$sfx_PressButons.playing =true
	$TextureRect2.visible = true
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()


func _on_leave_mouse_entered() -> void:
	
	pass # Replace with function body.
