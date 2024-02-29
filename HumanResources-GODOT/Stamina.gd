extends Label

var MAX_STAMINA = 100
var MIN_STAMINA = 0
var stamina = MAX_STAMINA
var elapsed = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	elapsed += delta
	if elapsed >= 2 and stamina < MAX_STAMINA:
		stamina += 1
		text = "STAMINA: %s" % stamina
		elapsed = 0

func _on_light_attack():
	if stamina > MIN_STAMINA:
		stamina -= 1
		text = "STAMINA: %s" % stamina
