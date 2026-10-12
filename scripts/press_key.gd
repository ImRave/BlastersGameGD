extends Sprite2D

# Esta variable aparece en el Inspector como un selector de teclas
@export var tecla_animacion: Key = KEY_SPACE


func _process(_delta: float) -> void:
	var presionada := Input.is_key_pressed(tecla_animacion)

	if presionada:
		frame = 1
	else:
		frame = 0
