extends ProgressBar

var MAX_HEALTH = 100
var MIN_HEALTH = 0
var health = MAX_HEALTH
var elapsed = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	value = MAX_HEALTH


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
