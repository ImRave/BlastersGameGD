extends CanvasLayer
@export var paused = false;
func _ready() -> void:
	visible = false
	get_tree().paused = false
	process_mode=Node.PROCESS_MODE_ALWAYS
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Esc"):
		if get_tree().paused:
			visible = false
			paused = false
			get_tree().paused =false
		else:
			visible=true	
			get_tree().paused=true
			paused = true

func _on_resume_pressed() -> void:
	$sfx_PressButons.playing =true
	visible =false
	get_tree().paused =false


func _on_options_pressed() -> void:
	$sfx_PressButons.playing =true
	$PauseMenu.visible =false
	$OptionsMenu.visible=true


func _on_quit_pressed() -> void:
	$sfx_PressButons.playing =true
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
	
