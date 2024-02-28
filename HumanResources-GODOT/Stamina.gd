extends Label

var stamina = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_light_attack():
	stamina -= 1
	text = "STAMINA: %s" % stamina
