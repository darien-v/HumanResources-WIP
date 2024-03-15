extends Label

# the player can change these later by levelling up
@export var MAX_HEALTH = 100

var MIN_HEALTH = 0

var elapsed = 0

# allows player to know if they have enough stamina for action
var health = MAX_HEALTH;

# Called when the node enters the scene tree for the first time.
func _ready():
	text = "Health: %s" % health;
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_damage(damageAmt):
	health -= damageAmt;
	# death condition
	if health < 0:
		pass # havent programmed death yet
	else:
		text = "Health: %s" % health;
		
func returnHealth():
	return health;
