extends AnimationPlayer

@onready var player = $"../../.."

# Connect signal(s) here
func _ready():
	player.connect_anim_finish(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
