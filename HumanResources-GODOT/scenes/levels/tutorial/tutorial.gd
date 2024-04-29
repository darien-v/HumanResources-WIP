extends Node

@onready var player = $Player
var paused = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	get_tree().call_group("enemies", "update_target_location", player.global_position)

func _on_pause():
	if not paused:
		get_tree().paused = true
		paused = true
	else:
		get_tree().paused = false
		paused = false
