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

# emits to pause everything
signal pause

# scene root is always player parent
@onready var scene = $".."

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

# makes turning smoother
var actionsPressed = {}
var turnModifier = 0

# invulnerability functionality
var invulnerable = false
var dodgeTime = 1
var hitTime = 1
@onready var timer = $Timer

# lets us know what interactable areas the player is in
var interactables = {}
var interactionCategories = {
								"pickup": 0,
								"door": 0,
								"interactable": 0
							}
@onready var interactionPicker = $"../InteractionPicker"
var item = null
var interactionsAvailable = false

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
						{
							"roll":
							{
								"fallRoll":{"iframe":.35, "speedmod":5},
								"sprintRoll":{"iframe":.45, "speedmod":3}
							}
						}
				}
var inAnimation = false
var moveWithAnimation = false
var currentAction = ["N/A","N/A"]

# inventory
var inventory = {
					"keys":{"tutorialKey":1},
					"weapons":{},
					"consumables":{}
				}

# weapon
var hitbox
var weapon = null
var weaponType

@onready var staminaMeter = $"../UserInterface/Stamina";

# allows us to play animations
@onready var animationPlayer = $Pivot/protagImportable/AnimationPlayer;
@onready var skeleton = $Pivot/protagImportable/Armature/Skeleton3D
@onready var face = {
						"eyes":[$Pivot/protagImportable/Armature/Skeleton3D/LeftEye/eye, $Pivot/protagImportable/Armature/Skeleton3D/RightEye/eye],
						"brows":[$Pivot/protagImportable/Armature/Skeleton3D/LeftEye/brow, $Pivot/protagImportable/Armature/Skeleton3D/RightEye/brow],
						"mouth":$Pivot/protagImportable/Armature/Skeleton3D/Mouth/mouth
					}

var target_velocity = Vector3.ZERO

# reset interaction vars to default
func resetInteraction():
	interactable = "None"
	interactionName = ""
	specificTree = ""
	interactionGroup = "environmental"
	specificInteraction = false

# mini-functions to connect necessary signals
func connect_anim_finish(animPlayer):
	animPlayer.animation_finished.connect(self._on_animation_player_animation_finished)
func connect_player_hurt(healthbar):
	self.playerDamaged.connect(healthbar._on_damage)
func connect_player_pause():
	self.pause.connect(scene._on_pause)

# allows easy query to player inventory
func checkInventory(type, item, consume=false):
	if type in inventory.keys():
		if item in inventory[type].keys():
			if consume:
				inventory[type][item] -= 1
				if inventory[type][item] <= 0:
					inventory[type].erase(item)
			return true
	return false

# on object creation, get the starting position
func _ready():
	timer.stop()
	oldpos = global_position
	staminaMeter.connect_player_signals(self)
	connect_player_pause()
	# connect area entered to the damage func
	for collider in combatCollisions:
		collider.area_entered.connect(self._on_HurtboxArea_area_entered)
	# play the eyes and eyebrows
	for eye in face["eyes"]:
		eye.play("front")
	for brow in face["brows"]:
		brow.play("default")
	face["mouth"].play("default")
	animationPlayer.play("idling/idling")
	
func emit_pause():
	pause.emit()

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
		currentAction = ["N/A", "N/A"]
		# check for each move input + update direction
		# XZ plane = ground
		
		# go through all the inputs
		# it works like this:
		# # movement inputs can be stacked
		# # combat inputs break the loop for sole focus, cannot be stacked
		# # if currently in an animation, no input can be read
		for action in inputDict["dodging"].keys():
			if Input.is_action_just_pressed(action):
				idling = false
				walking = false
				sprinting = false
				var type = "dodging"
				currentAction[0] = "dodging"
				if action == "roll":
					staminaUse.emit("roll")
					if currentSpeed > speed:
						type = type + "/sprintRoll"
						currentAction[1] = "sprintRoll"
					else:
						type = type + "/fallRoll"
						currentAction[1] = "fallRoll"
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
			if Input.is_action_just_pressed("prev"):
				interactionPicker.change_index(-1)
			elif Input.is_action_just_pressed("next"):
				interactionPicker.change_index(1)
			# if the user prompted interaction, we show corresponding text
			if Input.is_action_just_pressed("interact"):
				item = interactionPicker.get_current()
				interactionPicker.hide_self(true)
				# if there is an item to be picked up and it is active, process that
				if item != null:
					var itemName = item.return_name()
					var type = interactables[itemName]["type"]
					interactables.erase(itemName)
					interactionPicker.update_objects(interactables)
					if type == "pickup":
						item.pickedUp(self)
					elif type == "door":
						var door = item.get_parent()
						if not door.get("open"):
							door.check_openable(self)
						else:
							door.close()
							return
					textbox.startInteraction(true, item.get_parent())
					emit_pause()
				else:
					textbox.startInteraction()
					emit_pause()
			# last thing to check for is movement
			else:
				# our current speed is base + whatever modifiers there are
				currentSpeed = speed + speedModifier
				momentum = Vector3.ZERO
				var turnaround = false
				for action in inputDict["movement"].keys():
					if Input.is_action_pressed(action):
						if not walkingInput:
							walkingInput = true
							if not walking:
								walking = true
								idling = false
								animationPlayer.play("walkCycles/walkingBasic")
						var temp = inputDict["movement"][action] 
						var tempVal = temp["val"]
						# here we gather momentum, but also check if opposites were pressed
						# for silly turnaround anim
						turnaround = false
						if temp["dir"] == "x":
							momentum.x=tempVal
							if (direction.x > 0 and tempVal < 0) or (direction.x < 0 and tempVal > 0):
								if snappedf(direction.y, .0001) == 0 and snappedf(direction.z, .0001) == 0:
									turnaround = true
									direction = Vector3.ZERO
									momentum = Vector3(tempVal, 0, 0)
									break
						elif temp["dir"] == "z":
							momentum.z=tempVal
							if (direction.z > 0 and tempVal < 0) or (direction.z < 0 and tempVal > 0):
								if snappedf(direction.y, .0001) == 0 and snappedf(direction.x, .0001) == 0:
									turnaround = true
									direction = Vector3.ZERO
									momentum = Vector3(0, 0, tempVal)
									break
				if turnaround:
					inAnimation = true
					walking = false
					idling = false
					walkingInput = false
					if not sprinting:
						animationPlayer.play("walkCycles/walkingTurnAround")
					else:
						animationPlayer.play("running/runningTurnaround")
					animationPlayer.speed_scale = currentSpeed/2
				else:
					direction += momentum
				# and, check if we're running, but only if we're already walking
				var sprintStop = true
				if walkingInput:
					if Input.is_action_pressed("sprint"):
						staminaUse.emit("sprint")
						if staminaMeter.checkStamina():
							if not sprinting:
								sprinting = true
								animationPlayer.play("running/runningBasic")
							sprintStop = false
							currentSpeed += sprintBonus
						elif sprinting:
							print("no stamina")
							sprintStop = true
							animationPlayer.stop()
							animationPlayer.play("walkCycles/walkingBasic")
					elif sprinting:
						animationPlayer.stop()
						animationPlayer.play("walkCycles/walkingBasic")
				if sprintStop and sprinting:
					sprinting = false
					actionDone.emit()
			
			# if we didnt get any valid inputs, we are idling again
			if not walkingInput and not inAnimation:
				# input direction
				direction = Vector3.ZERO
				if not idling:
					idling = true
					if walking:
						animationPlayer.play("walkCycles/walkingStop")
						walking = false
					else:
						animationPlayer.play("idling/idling")
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
		check_collisions()
		oldpos = global_position
	# else, if we're interacting w npc, continue
	elif interactionGroup == "NPC":
		npcInteraction()

func process_action(type, isAttack):
	# only perform action if we have enough stamina
	if staminaMeter.checkStamina():
		if "dodging" in type:
			var tempKey = currentAction[1]
			if "Roll" in tempKey:
				speedModifier += inputDict["dodging"]["roll"][tempKey]["speedmod"]
			print(type)
			moveWithAnimation = true
		elif "light" in type:
			animationPlayer.speed_scale = 1.5
		else:
			velocity = Vector3.ZERO
		inAnimation = true
		animationPlayer.play(type)
		# when an attack is performed, only then does the hitbox turn on
		if hitbox != null and isAttack:
			attacking = true;
			print("hitbox on")
			hitbox.setActive();

func check_collisions(object=self):
	for index in range(object.get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()
		# If the collision is with ground
		if collider == null or collider.get_collision_layer() == 4:
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

func _on_HurtboxArea_area_entered(area):
	if area.is_in_group("weapons"):
		if area.isActive() and not invulnerable:
			print(' '.join(["Player hit by: ", area]))
			print("player damaged")
			playerDamaged.emit(area.get_meta("damage"))
			invulnerable = true
			timer.start(hitTime)

func entered_interactable_area(object):
	if object.is_in_group("interactables"):
		print("interactable")
		var objName = object.return_name()
		var type
		var text
		interactables[objName] = {}
		if object.is_in_group("collectibles"):
			text = "Pick up %s" % objName
			type = "pickup"
		elif object.is_in_group("doors"):
			text = "Use door"
			type = "door"
		else:
			text = "Interact with %s" % objName
			type = "interactable"
		interactables[objName]["text"] = text
		interactables[objName]["type"] = type
		interactables[objName]["object"] = object
		interactionCategories[type] += 1
		interactionPicker.update_objects(interactables)
		interactionsAvailable = true
		print(interactables)
			
func exited_interactable_area(object):
	print("exited interactable range")
	# failsafe
	if object in interactables.keys():
		interactables.erase(object)
	interactionPicker.update_objects(interactables)

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
func processReaction(consequence, increment=false):
	if increment:
		npc.incrementInteraction()
	npc.changeAttitude(consequence)
		
func checkNPCApproval()->String:
	return npc.approval()

# update position with moving animation
func update_with_animation():
	if currentAction[0] == "dodging":
		var currentSecond = animationPlayer.current_animation_position
		# special case for some animations
		if currentAction[1] == "fallRoll":
			if currentSecond >= 1.1:
				velocity = Vector3.ZERO
		# check if we reached iframe
		if not invulnerable:
			if "Roll" in currentAction[1]:
				var iframe = inputDict["dodging"]["roll"][currentAction[1]]["iframe"]
				if currentSecond >= iframe and not invulnerable:
					invulnerable = true
					timer.start(dodgeTime)
	else:
		# ground velocity
		direction.x += momentum.x
		direction.z += momentum.z
		target_velocity.x = -direction.x * (speedModifier + speed)
		target_velocity.z = -direction.z * (speedModifier + speed)
		# Moving the Character
		velocity = target_velocity
	move_and_slide()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "walkCycles/walkingTurnAround":
		direction = momentum
	elif anim_name == "walkCycles/walkingStop":
		animationPlayer.play("idling/idling")
	elif attacking:
		print("hitbox off")
		hitbox.setInactive()
		attacking = false
	if inAnimation:
		actionDone.emit()
		inAnimation = false
	speedModifier = 0
	animationPlayer.speed_scale = 1
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
	
func _on_timer_timeout():
	timer.stop()
	invulnerable = false
	print("invulnerability timeout")
