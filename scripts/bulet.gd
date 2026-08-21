extends Sprite2D

@export var speed := 800.0
var direction := Vector2.ZERO

func _ready() -> void:
	
	$AnimationPlayer.play("appear") 
	await get_tree().create_timer(10).timeout
	queue_free()

func _process(delta: float) -> void:
	position += direction * speed * delta

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func _on_area_2d_area_entered(area: Area2D) -> void:
	queue_free()
	pass # Replace with function body.
