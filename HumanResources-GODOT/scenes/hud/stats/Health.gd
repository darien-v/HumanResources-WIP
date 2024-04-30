extends ProgressBar

var MAX_HEALTH = 100
var MIN_HEALTH = 0
var health = MAX_HEALTH
var elapsed = 0


@onready var player = $"../../Player"

# Called when the node enters the scene tree for the first time.
func _ready():
	value = MAX_HEALTH
	player.connect_player_hurt(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_damage(damageAmt):
	health -= damageAmt;
	# death condition
	if health < 0:
		$"../death".show()
	else:
		value = health
		
func returnHealth():
	return health;
