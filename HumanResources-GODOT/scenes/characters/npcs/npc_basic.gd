extends CharacterBody3D

# player speed in m/s
@export var speed = 5
var speedModifier = 0
var sprintBonus = 5
var currentSpeed = 5
@export var momentum = Vector3.ZERO
@export var direction = Vector3.ZERO
# turning speed
@export var turnRate = .2
# downward acceleration in m/s
@export var fall_acceleration = 75
# jumping (vertical) impulse in m/s
@export var jump_impulse = 20

# interaction tracker! woo
# attitude towards player
@export var attitude = 0
# number of meaningful interactions with player
# meaningful = player made choice of some kind
@export var interactions = 0
@onready var animationPlayer

func connect_anim_finish(player):
	animationPlayer = player

func _physics_process(delta):
	move_npc(delta)

func move_npc(delta):
	var target_velocity = Vector3.ZERO
	# vertical velocity (fall after jump)
	if not is_on_floor(): # gravity
		target_velocity.y = velocity.y
		target_velocity.y -= (fall_acceleration * delta)

	# JUMPING HAS BEEN CANCELLED BY THE WOKE MOB
	# vertical velocity (jumping up)
	#if is_on_floor() and Input.is_action_just_pressed("jump"):
		#target_velocity.y = jump_impulse
		
	# Moving the Character
	velocity = target_velocity
	move_and_slide()

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
