extends CharacterBody3D

# pathfinding creds: https://www.youtube.com/watch?v=-juhGgA076E

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
var checking = false
var circling = false
var comboAttacks = 2
var totalAttacks = 0
var playerInSight = false
var playerMissingDuration = 0
var playerDirection = Vector3.ZERO
var inAnimation = false
var attackDistance = 6
var actionDistance = 10
var speedUp = true
var baseY
var checkingRayCast = false
var canAttack = true

@onready var VisionArea = $Pivot/VisionArea
@onready var VisionRaycast = $Pivot/Eyes/VisionRaycast
@onready var timer = $Timer
@onready var target = $"../Player"

# mini-functions to connect necessary signals
func connect_anim_finish(animPlayer):
	animPlayer.animation_finished.connect(self._on_animation_player_animation_finished)
	
# when enemy spawns, connect necessary signals, add to necessary group(s)
func _ready():
	self.add_to_group("enemies", true)
	VisionRaycast.add_exception(self)
	VisionRaycast.add_exception($"../Player/interactionRadius")
	# signal emitted upon death
	resources.connect_enemy_death(self)
	velocity = Vector3.ZERO
	navAgent.target_desired_distance = actionDistance
	baseY = position.y
	# get all hitboxes connected
	for collider in combatCollisions:
		if collider.is_in_group("weapons"):
			hitboxes.append(collider)
		# connect area entered to the damage func
		collider.area_entered.connect(self._on_HurtboxArea_area_entered)

func _physics_process(delta):
	#move_enemy(delta)
	if aggro == true and not inAnimation:
		pathfinding()
		pivot.look_at(target.global_transform.origin, Vector3.UP, true)
		pivot.rotation.x = 0
		VisionRaycast.look_at(target.global_transform.origin, Vector3.UP, true)
		# if no other animation queued, start walking
		if not inAnimation:
			animationPlayer.play("walkCycles/walkingBasic")
		move_and_slide()
	# if nothing found but something still in range, keep checking
	if not checkingRayCast:
		check_vision(target)
	else:
		velocity = Vector3.ZERO
	check_collisions()
	
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
	var newVelocity = (((target.global_transform.origin - pos).normalized()) * (speed+speedMod))
	newVelocity.y = 0
	velocity = newVelocity
	#print(velocity)
	#print(playerDirection)
	
# tells the enemy where the player is
func update_target_location():
	navAgent.target_position = target.global_transform.origin
					
func check_collisions(object=self):
	# Iterate through all collisions that occurred this frame
	for index in range(object.get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = object.get_slide_collision(index)
		var collider = collision.get_collider()
		# If the collision is with ground
		if collider == null:
			continue
		# this function doesnt do much right now. might be removed

func _on_navigation_agent_3d_target_reached():
	if not inAnimation:
		navAgent.target_desired_distance = attackDistance
		decide_action()

func check_vision(overlap):
	if not checkingRayCast:
		if overlap == null:
			return
		var playerSeen = false
		checkingRayCast = true
		if not aggro:
			if overlap.is_in_group("protagbody"):
				VisionRaycast.force_raycast_update()
				if VisionRaycast.is_colliding():
					var collider = VisionRaycast.get_collider()
					print(collider)
					if collider.is_in_group("protagbody") or collider.is_in_group("protagdecor"):
						playerSeen = true
					else:
						playerSeen = false
						print("CANTSEE")
				else:
					playerSeen = true
				if playerSeen:
					aggro=true
					playerMissingDuration = 0
		else:
			VisionRaycast.force_raycast_update()
			if VisionRaycast.is_colliding():
				var collider = VisionRaycast.get_collider()
				print(collider.get_groups())
				if collider.is_in_group("protagbody") or collider.is_in_group("protagdecor") or collider.is_in_group("player"):
					playerSeen = true
				else:
					playerSeen = false
					print("CANTSEE")
			else:
				playerSeen = true
			if playerSeen:
				playerMissingDuration = 0
				if not inAnimation:
					decide_action()
			else:
				playerMissingDuration += 1
				print(playerMissingDuration)
				if playerMissingDuration >= 2000:
					animationPlayer.stop()
					aggro = false
	checkingRayCast = false

func _on_VisionArea_area_entered(area):
	if not aggro and not checkingRayCast:
		check_vision(area)
		checking = true
func _on_VisionArea_area_exited(area):
	checking = false
	
func _on_HurtboxArea_area_entered(area):
	if area.is_in_group("weapons"):
		# if the weapon is actively attacking
		if area.isActive():
			print(' '.join(["Enemy hit by: ", area]))
			# prevent multiple damage instances in one hit
			area.setInactive()
			var health = self.get_meta("health")
			health-=area.get_meta("baseDamage")
			print("enemy damaged, health is %d" % health)
			if health <= 0:
				death.emit(humanResources)
				queue_free()
			else:
				self.set_meta("health", health)

func _on_animation_player_animation_finished(animName):
	inAnimation = false
	for hitbox in hitboxes:
		hitbox.setInactive()

func decide_action():
	if not inAnimation:
		var distance = navAgent.distance_to_target()
		#print(distance)
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
	animationPlayer.stop()
	animationPlayer.play("meleeAttacks/swipe_left")

func _on_timer_timeout():
	totalAttacks = 0
	canAttack = true
