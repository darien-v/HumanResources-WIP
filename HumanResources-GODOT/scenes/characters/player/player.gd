extends CharacterBody3D

# player speed in m/s
@export var speed = 5
var speedModifier = 0
var sprintBonus = 5
var currentSpeed = 5
@export var momentum = Vector3.ZERO
@export var direction = Vector3.ZERO
# turning speed
@export var turnRate = 1
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

# the other parts of da body. god. fuck. im so tired
@onready var combatCollisions = get_tree().get_nodes_in_group("protagbody")

# emits if player is attacking - needed to update stamina
signal staminaUse(type)
# tells the stamina bar that it can start regen
signal actionDone

# emits if player takes damage
signal playerDamaged(damageAmt)

# emits whenever the player is speaking
signal playerResponding
signal playerSpeaking

# lets us check if in dialogue, which restricts movement
@onready var textbox = $"../TextInterface/textbox"

# lets us know if the player has moved, important for dialog
var oldpos
var animationStartPos
var attacking = false
var walking = false
var sprinting = true
var walkingInput = false
var idling = false
var dodging = false
var invulnerable = false

# lets us know what interactable areas the player is in
var interactables

# lets us know if player is picking up an item
var pickup = false
var pickupItem = null

# simplifies actions and animations
var inputDict = {
					"movement":
						{
							"move_right":{"dir":"x", "val":-turnRate},
							"move_left":{"dir":"x", "val":turnRate},
							"move_forward":{"dir":"z", "val":turnRate},
							"move_back":{"dir":"z", "val":-turnRate}
						},
					"combat":
						[
							"light_attack",
							"heavy_attack"
						],
					"dodging":
						[
							"roll"
						]
				}
var inAnimation = false
var moveWithAnimation = false

# weapon
var hitbox
var weapon = null
var weaponType

@onready var staminaMeter = $"../UserInterface/Stamina";

# allows us to play animations
@onready var animationPlayer = $Pivot/protagImportable/AnimationPlayer;
@onready var skeleton = $Pivot/protagImportable/Armature/Skeleton3D

var target_velocity = Vector3.ZERO

# reset interaction vars to default
func resetInteraction():
	interactable = "None"
	interactionName = ""
	specificTree = ""
	interactionGroup = "environmental"
	specificInteraction = false
	pickup = false
	pickupItem = null

# mini-functions to connect necessary signals
func connect_anim_finish(animPlayer):
	animPlayer.animation_finished.connect(self._on_animation_player_animation_finished)
func connect_player_hurt(healthbar):
	self.playerDamaged.connect(healthbar._on_damage)

# on object creation, get the starting position
func _ready():
	oldpos = global_position
	staminaMeter.connect_player_signals(self)

func _physics_process(delta):
	# only need to process these if not in dialogue
	if not textbox.visible:
		# process player movement
		move_player(delta)
		if moveWithAnimation:
			update_with_animation()
	elif Input.is_action_just_pressed("interact"):
		textbox.player_interacted()
	
# putting things into tiny functions
# so the main one is a little less cluttered

# player movement function
func move_player(delta):
	# save oldpos
	oldpos = global_position
	
	# can only move if not attacking
	if not inAnimation:
		# check for each move input + update direction
		# XZ plane = ground
		
		# go through all the inputs
		# it works like this:
		# # movement inputs can be stacked
		# # combat inputs break the loop for sole focus, cannot be stacked
		# # if currently in an animation, no input can be read
		for action in inputDict["dodging"]:
			if Input.is_action_just_pressed(action):
				idling = false
				walking = false
				sprinting = false
				var type = "dodging"
				if action == "roll":
					staminaUse.emit("roll")
					if currentSpeed > speed:
						type = type + "/sprintRoll"
					else:
						type = type + "/fallRoll"
				process_action(type, false)
				break
		# only check for attacks if player has a weapon
		if weapon != null and not inAnimation:
			for action in inputDict["combat"]:
				# first check if a valid combat action was passed
				# cleaning this up later of course
				if Input.is_action_just_pressed(action):
					idling = false;
					walking = false;
					sprinting = false
					var type = weaponType
					var isAttack = false
					if action == "light_attack":
						staminaUse.emit("lightAttack")
						type = type + "/light"
						isAttack = true
					elif action == "heavy_attack":
						staminaUse.emit("heavyAttack")
						type = type + "/heavy"
						isAttack = true
					process_action(type, true)
					break
		
		# if no combat animation started, check other inputs
		if not inAnimation:
			walkingInput = false
			# if the user prompted interaction, we show corresponding text
			if Input.is_action_just_pressed("interact"):
				print("interacted")
				print(textbox.get("showingText"))
				# if there is an item to be picked up and it is active, process that
				if pickupItem != null:
					if pickupItem.return_active():
						textbox.startInteraction(pickup, pickupItem.return_name())
						pickupItem.pickedUp(self)
						resetInteraction()
				else:
					textbox.startInteraction()
			# last thing to check for is movement
			else:
				# our current speed is base + whatever modifiers there are
				currentSpeed = speed + speedModifier
				momentum = Vector3.ZERO
				for action in inputDict["movement"].keys():
					if Input.is_action_pressed(action):
						if not walkingInput:
							walkingInput = true
							if not walking:
								walking = true
								idling = false
								animationPlayer.play("walkCycles/walkingBasic")
						var temp = inputDict["movement"][action] 
						if temp["dir"] == "x":
							momentum.x=temp["val"]
						elif temp["dir"] == "z":
							momentum.z+=temp["val"]
						direction += momentum
				# and, check if we're running, but only if we're already walking
				var sprintStop = true
				if walkingInput:
					if Input.is_action_pressed("sprint"):
						staminaUse.emit("sprint")
						if staminaMeter.checkStamina():
							sprinting = true
							sprintStop = false
							currentSpeed += sprintBonus
				if sprintStop and sprinting:
					sprinting = false
					actionDone.emit()
			
			# if we didnt get any valid inputs, we are idling again
			if not walkingInput:
				# input direction
				direction = Vector3.ZERO
				walking = false
				if not idling:
					idling = true
					animationPlayer.play("walkCycles/walkingStop")
			# reset state variable
			walkingInput = false
		
	# normalize the direction vector
	# otherwise it'll go faster on diagonals (2 keys pressed)
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.look_at(position + direction, Vector3.UP)
	
	# ground velocity
	if (not inAnimation) or (moveWithAnimation):
		target_velocity.x = -direction.x * currentSpeed
		target_velocity.z = -direction.z * currentSpeed
	else:
		target_velocity = Vector3.ZERO

	# vertical velocity (fall after jump)
	if not is_on_floor(): # gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# JUMPING HAS BEEN CANCELLED BY THE WOKE MOB
	# vertical velocity (jumping up)
	#if is_on_floor() and Input.is_action_just_pressed("jump"):
		#target_velocity.y = jump_impulse
		
	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
	# process interactable collisions if we moved
	if oldpos != global_position:
		player_interactable_collisions()
		oldpos = global_position
	# else, if we're interacting w npc, continue
	elif interactionGroup == "NPC":
		npcInteraction()

func process_action(type, isAttack):
	# only perform action if we have enough stamina
	if staminaMeter.checkStamina():
		if "dodging" in type:
			print(type)
			moveWithAnimation = true
		else:
			velocity = Vector3.ZERO
		inAnimation = true
		animationPlayer.stop()
		animationPlayer.play(type)
		# when an attack is performed, only then does the hitbox turn on
		if hitbox != null and isAttack:
			attacking = true;
			print("hitbox on")
			hitbox.setActive();

# player collision checker
func player_interactable_collisions():
	# get collisions from every body part
	for hitbox in combatCollisions:
		check_collisions(hitbox)
	check_collisions()

func check_collisions(object=self):
	for index in range(object.get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()
		# If the collision is with ground
		if collider == null or collider.get_collision_layer() == 4:
			if not pickup and pickupItem == null:
				resetInteraction()
			continue
		# If the collision is with an interactable object
		if collider.is_in_group("interactables"):
					# if interacting with an npc, enter appropriate filetree
			if collider.is_in_group("NPCs"):
				interactionGroup = "NPC"
				npc = collider
				npcInteraction()
			interactable = collider.name
			# here is where youd do whatever to get the name of the script you want
			interactionName = interactable # placeholder
			continue
		# If the collision is with an enemy
		elif collider.is_in_group("weapons"):
			print(' '.join(["Player hit by: ", collider]))
			if collider.isActive():
				print("player damaged")
				playerDamaged.emit(collider.get_meta("damage"))

func entered_interactable_area(object):
	if object.is_in_group("interactables"):
		print("interactable")
		if object.is_in_group("collectibles"):
			print("collectible")
			pickup = true
			pickupItem = object
			print(pickupItem)
func exited_interactable_area():
	print("exited interactable range")
	resetInteraction()

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

# update position with moving animation
func update_with_animation():
	# ground velocity
	direction.x += momentum.x
	direction.z += momentum.z
	target_velocity.x = -direction.x * 1
	target_velocity.z = -direction.z * 1
	# Moving the Character
	velocity = target_velocity
	move_and_slide()

func _on_animation_player_animation_finished(anim_name):
	if attacking:
		print("hitbox off")
		hitbox.setInactive()
		attacking = false
	if inAnimation:
		actionDone.emit()
		inAnimation = false
	moveWithAnimation = false

func equipWeapon(weaponIn, typeIn):
	# setting our weapon variables
	weapon = weaponIn
	weaponType = typeIn
	# showing the weapon physically
	$Pivot/protagImportable/Armature/Skeleton3D/LeftHand.equip(weapon)
	
func setHitbox(hitboxIn):
	hitbox = hitboxIn
	print(hitbox.get_groups())
	
func setInAnimation():
	inAnimation = true
func setNoAnimation():
	inAnimation = false
