extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(func(body):
		if body is CharacterBody2D:
			GameManager.go_to_next_level()
	)
