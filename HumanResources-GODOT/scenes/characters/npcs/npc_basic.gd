extends CharacterBody3D

# interaction tracker! woo
# attitude towards player
@export var attitude = 0
# number of meaningful interactions with player
# meaningful = player made choice of some kind
@export var interactions = 0

func _physics_process(delta):
	pass

func incrementInteraction():
	interactions += 1

func changeAttitude(amount):
	attitude += amount
	
func approval() ->String:
	if attitude > 0:
		return "Approving"
	elif attitude < 0:
		return "Disapproving"
	return "Neutral"
