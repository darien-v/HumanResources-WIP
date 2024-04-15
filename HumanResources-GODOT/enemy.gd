extends CharacterBody3D

# pathfinding creds: https://www.youtube.com/watch?v=-juhGgA076E

@export var health = 30
@export var humanResources = 10
signal death(humanResources)

# player speed in m/s
@export var speed = 3
var speedMod = 0
var attackCooldown = 3
# downward acceleration in m/s
@export var fall_acceleration = 75
# jumping (vertical) impulse in m/s
@export var jump_impulse = 20

var target_velocity = Vector3.ZERO

@onready var navAgent = $NavigationAgent3D
@onready var resources = $"../UserInterface/Resources"

@onready var pivot = $Pivot

# the other parts of da body. god. fuck. im so tired
@onready var combatCollisions = get_tree().get_nodes_in_group("enemybody")
var hitboxes = []

@onready var animationPlayer = $Pivot/Enemy/AnimationPlayer

var aggro = false
var circling = false
var comboAttacks = 2
var totalAttacks = 0
var playerInSight = false
var playerMissingDuration = 0
var playerDirection = Vector3.ZERO
var inAnimation = false
var attackDistance = 3.5
var actionDistance = 8
var speedUp = true
var baseY
var checkingRayCast = false
var canAttack = true

@onready var VisionArea = $VisionArea
@onready var VisionRaycast = $VisionRaycast
@onready var timer = $Timer
@onready var target

# mini-functions to connect necessary signals
func connect_anim_finish(animPlayer):
	animPlayer.animation_finished.connect(self._on_animation_player_animation_finished)
	
# when enemy spawns, connect necessary signals, add to necessary group(s)
func _ready():
	self.add_to_group("enemies", true)
	VisionRaycast.add_exception(self)
	# signal emitted upon death
	resources.connect_enemy_death(self)
	velocity = Vector3.ZERO
	navAgent.target_desired_distance = actionDistance
	baseY = position.y
	# get all hitboxes connected
	for collider in combatCollisions:
		if collider.is_in_group("weapons"):
			hitboxes.append(collider)

func _physics_process(delta):
	#move_enemy(delta)
	if aggro == true and not inAnimation:
		checkingRayCast = false
		checkForPlayer()
		pathfinding()
		if playerDirection != Vector3.ZERO:
			playerDirection.y = baseY
			pivot.look_at(playerDirection, Vector3.UP, true)
			pivot.rotation.x = 0
		animationPlayer.play("walkCycles/walkingBasic")
		global_transform.origin.y = 2
		move_and_slide()
	else:
		velocity = Vector3.ZERO
	enemy_collisions()
	
# putting things into tiny functions
# so the main one is a little less cluttered

# base function for pathfinding in combat
func pathfinding():
	update_target_location()
	var pos = global_transform.origin
	#print(pos)
	var newPos = navAgent.get_next_path_position()
	#print(newPos)
	# have to exaggerate distance for this to work
	var newVelocity = (((playerDirection - pos).normalized()) * (speed+speedMod))
	newVelocity.y = 0
	velocity = newVelocity
	#print(velocity)
	#print(playerDirection)
	
# tells the enemy where the player is
func update_target_location():
	navAgent.target_position = target.global_transform.origin

# player collision checker
func enemy_collisions():
	# get collisions from every body part
	for hitbox in combatCollisions:
		check_collisions(hitbox)
	check_collisions()
					
func check_collisions(object=self):
	# Iterate through all collisions that occurred this frame
	for index in range(object.get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = object.get_slide_collision(index)
		var collider = collision.get_collider()

		# If the collision is with ground
		if collider == null:
			continue
		
		# If the collision is with a weapon
		if collider.is_in_group("weapons"):
			print("weapon")
			# if the weapon is actively attacking
			if collider.isActive():
				print("Hit by weapon")
				# prevent multiple damage instances in one hit
				collider.setInactive()
				var health = self.get_meta("health")
				health-=collider.get_meta("baseDamage")
				print(health)
				if health <= 0:
					death.emit(humanResources)
					queue_free()
				else:
					self.set_meta("health", health)

func _on_navigation_agent_3d_target_reached():
	if not inAnimation:
		navAgent.target_desired_distance = attackDistance
		decide_action()

func check_vision(overlap):
	print(overlap.get_groups())
	var playerSeen = false
	if not aggro:
		if overlap.is_in_group("protagbody"):
			checkingRayCast = true
			print("Checking RayCast")
			VisionRaycast.force_raycast_update()
			
			if VisionRaycast.is_colliding():
				print("CANSEE")
				var collider = VisionRaycast.get_collider()
				
				if collider.is_in_group("playerInteraction"):
					target = collider.get_parent()
					aggro = true
				elif collider.is_in_group("protagbody"):
					target = collider.get_parent()
					target = target.get_parent()
					aggro = true

func checkForPlayer():
	var playerSeen = false
	VisionRaycast.look_at(playerDirection, Vector3.UP)
		
	VisionRaycast.force_raycast_update()
	if VisionRaycast.is_colliding():
		var collider = VisionRaycast.get_collider()
		#print(collider)
		if collider.is_in_group("protagbody"):
			playerSeen = true
			playerMissingDuration = 0
			playerDirection = target.global_transform.origin
			playerDirection.y = 0
	if aggro:
		playerDirection = target.global_transform.origin
		if playerSeen == false:
			playerMissingDuration += 1
		elif playerSeen and not inAnimation:
			decide_action()
		if playerMissingDuration >= 10000:
			animationPlayer.stop()
			aggro = false
	

func _on_VisionArea_area_entered(area):
	if not aggro and not checkingRayCast:
		check_vision(area)

func _on_animation_player_animation_finished(animName):
	inAnimation = false
	for hitbox in hitboxes:
		hitbox.setInactive()

func decide_action():
	if not inAnimation:
		var distance = navAgent.distance_to_target()
		if distance <= attackDistance:
			speedMod = 3
			if canAttack:
				basic_attack()
			else:
				circle_player()
		else:
			circle_player()

func circle_player():
	pass
	
func basic_attack():
	global_transform.origin.y = 0
	if totalAttacks == comboAttacks:
		inAnimation = false
		canAttack = false
		navAgent.target_desired_distance = actionDistance
		speedMod = 0
		timer.start(attackCooldown)
		return
	inAnimation = true
	for hitbox in hitboxes:
		hitbox.setActive()
	print("attacking")
	totalAttacks += 1
	animationPlayer.play("enemyMelee/swipe")

func _on_timer_timeout():
	totalAttacks = 0
	canAttack = true
