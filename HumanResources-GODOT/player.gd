extends CharacterBody3D

# player speed in m/s
@export var speed = 14
# downward acceleration in m/s
@export var fall_acceleration = 75
# jumping (vertical) impulse in m/s
@export var jump_impulse = 20
# allows player to inspect/interact with objects
@export var interactable = "None"
# lets us call the interacting object if necessary
@export var interactionObjectPath = ""
# tells us what kind of object we are interacting with
@export var interactionGroup = "environmental"
# tells us if the object we're interacting with has its own file
@export var specificInteraction = false
# we'll need this for npc interactions
@export var attitude = 0
# in case of special interaction scenes
@export var interactionName = ""
# lets us save the npc we interacted with
var npc
# lets us categorize interactions
var positive = ["Happy", "Excited"]
var negative = ["Sad", "Angry"]
# other emotions are just neutral

# lets us check if in dialogue, which restricts movement
@onready var textbox = $CameraPivot/textbox_temp

var target_velocity = Vector3.ZERO

func _physics_process(delta):
	# only need to process these if not in dialogue
	if not textbox.visible:
		# process player movement
		move_player(delta)
	
# putting things into tiny functions
# so the main one is a little less cluttered

# player movement function
func move_player(delta):
	# input direction
	var direction = Vector3.ZERO

	# check for each move input + update direction
	# XZ plane = ground
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	
	# normalize the direction vector
	# otherwise it'll go faster on diagonals (2 keys pressed)
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.look_at(position + direction, Vector3.UP)
	
	# ground velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# vertical velocity (fall after jump)
	if not is_on_floor(): # gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# vertical velocity (jumping up)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
		
	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
	# process collisions
	player_collisions()

# player collision checker
func player_collisions():
	# always reset to default
	interactable = "None"
	interactionGroup = "environmental"
	specificInteraction = false
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()

		# If the collision is with ground
		if collider == null:
			interactable = "None"
			interactionName = ""
			interactionGroup = "environmental"
			specificInteraction = false
			continue

		# If the collider is with an interactable object
		if collider.is_in_group("interactable"):
			# if interacting with an npc, enter appropriate filetree
			if collider.is_in_group("NPC"):
				interactionGroup = "NPC"
				npc = collider
				specificInteraction = true
				interactionObjectPath = npc.get_path()
			interactable = npc.name
			# here is where youd do whatever to get the name of the script you want
			interactionName = interactable # placeholder
			attitude = npc.get_meta("attitude")
			break

# processes the result of an npc interaction
# eventually we'll have some variable to determine interaction strength. later
func processReaction(emotion):
	print(emotion)
	if emotion in positive:
		attitude += 1
	elif emotion in negative:
		attitude -= 1
	else:
		return
	npc.set_meta("attitude", attitude)
	print(npc.get_meta("attitude"))
	return
