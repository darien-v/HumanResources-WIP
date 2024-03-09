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
# in case we desire a specific branch
@export var specificTree = ""
# lets us save the npc we interacted with
var npc
# lets us categorize interactions
@export var positive = ["Happy", "Excited"]
@export var negative = ["Sad", "Nervous"]
@export var strong = ["Angry", "Surprised"]
# other emotions are just neutral
# emits if player is attacking - needed to update stamina
signal lightAttackActive

# lets us check if in dialogue, which restricts movement
@onready var textbox = $CameraPivot/textbox_temp

# lets us know if the player has moved, important for dialog
var oldpos
var attacking = false;
var walking = false;
var idling = false;

@onready var hitbox = $"Pivot/ProtagTestLoopMaybe/metarig/Skeleton3D/BoneAttachment3D/Amoray-Note1/gold_stuff/polySurface2/Area3D"

# allows us to play animations
@onready var animationPlayer = $Pivot/ProtagTestLoopMaybe/AnimationPlayer;

var target_velocity = Vector3.ZERO

# reset interaction vars to default
func resetInteraction():
	interactable = "None"
	interactionName = ""
	specificTree = ""
	interactionGroup = "environmental"
	specificInteraction = false

# on object creation, get the starting position
func _ready():
	oldpos = global_position
	$CameraPivot/textbox_temp/player_portrait.setPortrait("you")
	# bind function for stamina updating
	lightAttackActive.connect($/root/Main/UserInterface/Stamina._on_light_attack.bind())

func _physics_process(delta):
	if not walking and not attacking:
		if not idling:
			animationPlayer.stop();
			animationPlayer.play("Idle")
			idling = true
	# only need to process these if not in dialogue
	if not textbox.visible:
		# process player movement
		move_player(delta)
	
# putting things into tiny functions
# so the main one is a little less cluttered

# player movement function
func move_player(delta):
	# save oldpos
	oldpos = global_position
	
	# input direction
	var direction = Vector3.ZERO

	# check for each move input + update direction
	# XZ plane = ground
	idling = true;
	if Input.is_action_pressed("move_right"):
		direction.x += 1
		if not walking:
			animationPlayer.stop();
			animationPlayer.play("Walk")
			walking = true;
		idling = false;
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
		if not walking:
			animationPlayer.stop();
			animationPlayer.play("Walk")
			walking = true;
		idling = false;
	if Input.is_action_pressed("move_back"):
		direction.z += 1
		if not walking:
			animationPlayer.stop();
			animationPlayer.play("Walk")
			walking = true;
		idling = false;
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
		if not walking:
			animationPlayer.stop();
			animationPlayer.play("Walk")
			walking = true;
		idling = false;
	
	# if we didnt do anything, go back to idling
	if idling:
		walking = false;
		# we set it to false to ensure animation resets
		idling = false;
	
	# left click triggers light attack
	if Input.is_action_pressed("light_attack"):
		lightAttackActive.emit()
		idling = false;
		animationPlayer.stop();
		animationPlayer.play("Slash")
		attacking = true;
		# when an attack is performed, only then does the hitbox turn on
		if hitbox != null:
			print("hitbox on")
			hitbox.setActive();
			hitbox.monitoring = true
		
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
	
	# process interactable collisions if we moved
	if oldpos != global_position:
		player_interactable_collisions()
	# else, if we're interacting w npc, continue
	elif interactionGroup == "NPC":
		npcInteraction()

# player collision checker
func player_interactable_collisions():
	# always reset to default
	resetInteraction()
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()

		# If the collision is with ground
		if collider == null:
			resetInteraction()
			continue

		# If the collider is with an interactable object
		if collider.is_in_group("interactable"):
			# if interacting with an npc, enter appropriate filetree
			if collider.is_in_group("NPC"):
				interactionGroup = "NPC"
				npc = collider
				npcInteraction()
			interactable = collider.name
			# here is where youd do whatever to get the name of the script you want
			interactionName = interactable # placeholder
			break

# the actual interaction processing for npcs
func npcInteraction():
	specificInteraction = true
	interactionObjectPath = npc.get_path()
	attitude = npc.get("attitude")
	# check if this is your first interaction with npc
	if npc.get("interactions") == 0:
		specificTree = "FirstMeet"
	else:
		specificTree = ""

# processes the result of an npc interaction
# eventually we'll have some variable to determine interaction strength. later
func processReaction(emotion):
	npc.incrementInteraction()
	if emotion in positive:
		npc.changeAttitude(1)
	elif emotion in negative or emotion == "Angry":
		npc.changeAttitude(-1)
	else:
		return
		
func checkNPCApproval()->String:
	return npc.approval()

func _on_animation_player_animation_finished(anim_name):
	if attacking:
		print("hitbox off")
		hitbox.setInactive();
		hitbox.monitoring = false
		attacking = false;
