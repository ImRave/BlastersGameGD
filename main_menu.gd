extends Control
var select = load("res://accets/selection.png")
var unselect = load("res://accets/unselect.png")
@onready var musica: AudioStreamPlayer2D = $ms_MainMenu
var points = 0
func leer_numero_de_txt(ruta: String) -> int:
	if ResourceLoader.exists(ruta):
		var data =load(ruta)
		points =data.max_point
	
	return points
	
func _ready() -> void:
	$MainMenu/VBoxContainer2/HBoxContainer/Kills/NK.text = str(leer_numero_de_txt("user://save.tres")).pad_zeros(3)
	musica.finished.connect(_on_musica_finished)
	musica.play()
func _on_musica_finished() -> void:
	musica.play()
func _on_play_pressed() -> void:
	$sfx_PressStart.play()
	if points > 0:
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		get_tree().change_scene_to_file("res://Escenas/Tutorial.tscn")


func _on_options_pressed() -> void:
	$sfx_PressButons.playing =true
	$MainMenu.visible =false
	$OptionsMenu.visible=true


func _on_leave_pressed() -> void:
	$sfx_PressButons.playing =true
	await get_tree().create_timer(0.2).timeout
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("window.location.href='https://blasters.imrave.site/'")
	else:
		get_tree().quit()


func _on_leave_mouse_entered() -> void:
	$MainMenu/VBoxContainer/leave.icon = select
func _on_leave_mouse_exited() -> void:
	$MainMenu/VBoxContainer/leave.icon = unselect
func _on_options_mouse_entered() -> void:
	$MainMenu/VBoxContainer/Options.icon = select
func _on_options_mouse_exited() -> void:
	$MainMenu/VBoxContainer/Options.icon = unselect


func _on_play_mouse_entered() -> void:
	$MainMenu/VBoxContainer/Play.icon =select
func _on_play_mouse_exited() -> void:
	$MainMenu/VBoxContainer/Play.icon =unselect


func _on_tutorial_pressed() -> void:
	$sfx_PressStart.play()
	get_tree().change_scene_to_file("res://Escenas/Tutorial.tscn")


func _on_tutorial_mouse_entered() -> void:
	$MainMenu/VBoxContainer/Tutorial.icon = select


func _on_tutorial_mouse_exited() -> void:
	$MainMenu/VBoxContainer/Tutorial.icon = unselect
