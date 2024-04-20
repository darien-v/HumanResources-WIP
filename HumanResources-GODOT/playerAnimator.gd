extends AnimationPlayer

@onready var parent = $"../../.."

# Connect signal(s) here
func _ready():
	parent.connect_anim_finish(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
