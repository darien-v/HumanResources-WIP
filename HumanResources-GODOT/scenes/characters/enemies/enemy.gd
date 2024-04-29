extends CharacterBody3D

# pathfinding creds: https://www.youtube.com/watch?v=-juhGgA076E
# enemy ai partially referenced from here: https://gist.github.com/AJ08Coder/d464dc6a6e99b028b51c1663ad1a904d

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

var spawnLocation = Vector3.ZERO

# AI state variables
var aggro = false
var returningToSpawn = false
var stopReturning = false
var checking = false
var attacking = false
var circling = false
var following = false
var playerInSight = false
var inAnimation = false
var canAttack = true
var idling = true

# function for trying to find player when out of sight
var followingNavPath = false
var navIndex = 0
var navSteps = 0
var currentNavPath # makes more sense than enemy "magically" knowing player's new position

# how long the enemy waits before charging at player
var attackWait = 7

# controls how many attacks the enemy can use in quick succession
# meant to prevent stunlocking the player/attack spam
# because that's not fun
var comboAttacks = 2 # should be max attacks + 1 because im dumb -ramen
var totalAttacks = 0

# tells us if we're still chasing the player
var playerMissingDuration = 0
var willpower = 2000 # how long enemy will chase player
var playerDirection = Vector3.ZERO
var attackDistance = 6
var actionDistance = 8
var circleDistance = 20
var checkingRayCast = false

# for the circling the player function
var circlePos = 0

@onready var VisionArea = $Pivot/VisionArea
@onready var VisionRaycast = $Pivot/Eyes/VisionRaycast
@onready var timer = $Timer
@onready var target = $"../Player"

# mini-functions to connect necessary signals
func connect_anim_finish(animPlayer):
	animPlayer.animation_finished.connect(self._on_animation_player_animation_finished)
	
# when enemy spawns, connect necessary signals, add to necessary group(s)
func _ready():
	# groups and exceptions
	self.add_to_group("enemies", true)
	VisionRaycast.add_exception(self)
	VisionRaycast.add_exception($"../Player/interactionRadius")
	# marking spawn location
	spawnLocation = global_position
	# signal emitted upon death
	resources.connect_enemy_death(self)
	velocity = Vector3.ZERO
	navAgent.target_desired_distance = actionDistance
	# get all hitboxes connected
	for collider in combatCollisions:
		VisionRaycast.add_exception(collider) # making sure vision doesnt collide with self
		if collider.is_in_group("weapons"):
			hitboxes.append(collider)
		# connect area entered to the damage func
		collider.area_entered.connect(self._on_HurtboxArea_area_entered)

# runs every frame
func _physics_process(delta):
	# only have to do all this if the enemy has been aggro'd
	if aggro == true and not inAnimation:
		# check where player is and what next position should be
		pathfinding()
		# look at the player, ensures we dont get any funky rotations
		pivot.look_at(target.global_transform.origin, Vector3.UP, true)
		pivot.rotation.x = 0
		VisionRaycast.look_at(target.global_transform.origin, Vector3.UP, true)
		# if no other animation queued, start walking
		if not inAnimation:
			animationPlayer.play("walkCycles/walkingBasic")
	# if we lost aggro, enemy should return to spawn location
	elif returningToSpawn:
		return_to_spawn()
	# periodically check vision
	# state variable prevents multithread conflicts
	if not checkingRayCast:
		check_vision(target)
	
	check_collisions()
	if not inAnimation:
		move_and_slide()
	
# putting things into tiny functions
# so the main one is a little less cluttered

# base function for pathfinding in combat
func pathfinding():
	var pos = global_transform.origin
	#print(pos)
	# if the player is in sight, follow player exactly
	# if not, follow AI path
	update_target_location()
	var newPos = navAgent.get_next_path_position()
	if playerInSight:
		newPos = target.global_transform.origin - pos
		followingNavPath = false
	else:
		playerMissingDuration += 1
		if not followingNavPath:
			followingNavPath = true
			currentNavPath = Array(navAgent.get_current_navigation_path())
			navSteps = len(currentNavPath)
			navIndex = 0
		else:
			update_navpath_index()
		newPos = currentNavPath[navIndex] - pos
	# have to exaggerate distance for this to work
	if not circling:
		var newVelocity = (((newPos).normalized()) * (speed+speedMod))
		newVelocity.y = 0
		velocity = newVelocity
		# if we can attack, check if we're in distance to do so
		var distance = navAgent.distance_to_target()
		if canAttack and aggro:
			if distance <= attackDistance:
				basic_attack()
	else:
		circle_player()
		#print(velocity)
		#print(playerDirection)

# function for pathfinding back to spawn location
func return_to_spawn():
	# check if we reached target
	if snappedf(navAgent.distance_to_target(), 1) == 0 or stopReturning:
		returningToSpawn = false
		stopReturning = false
		velocity = Vector3.ZERO
		animationPlayer.stop() # we'll have a nice animation eventually
		return
	# else, we update the navpath
	var newPos = navAgent.get_next_path_position()
	if not followingNavPath:
		followingNavPath = true
		currentNavPath = Array(navAgent.get_current_navigation_path())
		print(currentNavPath)
		navSteps = len(currentNavPath)
		navIndex = 0
	else:
		update_navpath_index()
	# do all the stuff whatever i dont care thog dont caare
	var pos = global_transform.origin
	newPos = currentNavPath[navIndex]
	print("NEWPOS %s" % newPos)
	#print("LOOKAT %s" % lookAt)
	# look at the player, ensures we dont get any funky rotations
	pivot.look_at(spawnLocation, Vector3.UP, true)
	pivot.rotation.x = 0
	var newVelocity = (((newPos - pos).normalized()) * (speed+speedMod) * 10)
	newVelocity.y = 0
	velocity = newVelocity
	print("VELOCITY %s" % velocity)

# functionality for following AI path when player out of sight
func update_navpath_index():
	# check if player reached the current path point
	# the rounding is scuffed and ugly, but necessary
	#print(Vector3(snappedf(global_position.x, 1), 0, snappedf(global_position.z, 1)))
	#print(Vector3(snappedf(currentNavPath[navIndex].x, 1), 0, snappedf(currentNavPath[navIndex].z, 1)))
	if Vector3(snappedf(global_position.x, 1), 0, snappedf(global_position.z, 1)) == Vector3(snappedf(currentNavPath[navIndex].x, 1), 0, snappedf(currentNavPath[navIndex].z, 1)):
		print("reached path point")
		navIndex += 1
		if navIndex >= navSteps:
			velocity = Vector3.ZERO
			followingNavPath = false
			if returningToSpawn:
				stopReturning = true
			navIndex -= 1

# tells the enemy where the player is
func update_target_location():
	if returningToSpawn:
		navAgent.target_position = spawnLocation
	else:
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
		if aggro:
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
				VisionRaycast.look_at(overlap.global_position, Vector3.UP, true)
				VisionRaycast.force_raycast_update()
				if VisionRaycast.is_colliding():
					var collider = VisionRaycast.get_collider()
					if collider.is_in_group("protagbody") or collider.is_in_group("protagdecor"):
						playerSeen = true
					else:
						playerSeen = false
				else:
					playerSeen = true
				if playerSeen:
					aggro=true
					speedMod = 0
					returningToSpawn = false
					playerMissingDuration = 0
		else:
			VisionRaycast.force_raycast_update()
			if VisionRaycast.is_colliding():
				var collider = VisionRaycast.get_collider()
				if collider.is_in_group("protagbody") or collider.is_in_group("protagdecor") or collider.is_in_group("player"):	
					playerSeen = true
				else:
					playerSeen = false
					#print("CANTSEE")
			else:
				playerSeen = true
			if playerSeen:
				playerMissingDuration = 0
			else:
				if playerMissingDuration >= willpower:
					playerMissingDuration = 0
					speedMod = 0
					aggro = false
					followingNavPath = false
					returningToSpawn = true
					navAgent.target_desired_distance = 1
					update_target_location()
		playerInSight = playerSeen
		decide_action()
	checkingRayCast = false

func _on_VisionArea_area_entered(area):
	if not aggro and not checkingRayCast:
		print("checking interactionbox")
		check_vision(area)
		checking = true
func _on_VisionArea_area_exited(area):
	checking = false
	
func _on_HurtboxArea_area_entered(area):
	if area.is_in_group("weapons"):
		# if the weapon is actively attacking
		if area.isActive():
			print(' '.join(["Enemy hit by: ", area]))
			aggro = true
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
	if attacking:
		attacking = false
	for hitbox in hitboxes:
		hitbox.setInactive()
	# if the next attack would exceed attack limit, we gotta reset some vars
	check_if_attack(true)

func decide_action():
	if not inAnimation and aggro:
		# if player isn't in sight, just follow the nav path
		if not playerInSight:
			circling = false
			following = true
		# if the player can be seen, we can decide things meaningfully
		else:
			var distance = navAgent.distance_to_target()
			# if we're in action distance, start thinkin
			if distance <= actionDistance:
				# if we can attack, speed towards the player and attack
				if canAttack:
					following = true
					circling = false
					speedMod = 10
				else:
					following = false
				# otherwise, we just circle the player
				if not following:
					circling = true
			# if in circling distance, circle before attacking
			elif distance <= circleDistance and not following:
				if not attacking and canAttack:
					attacking = true
					timer.start(attackWait)
				following = false
				circling = true
			# if too far, wait to charge
			elif not attacking and canAttack:
				attacking = true
				timer.start(attackWait)

func circle_player():
	var targetPos = target.global_transform.origin
	var radius = 5
	 #Distance from center to circumference of circle
	var angle = PI * 2;
	var newPos = Vector3(targetPos.x + cos(angle) * radius, 0, targetPos.z + cos(angle) * radius)
	var direction = (newPos - global_transform.origin).normalized() 
	velocity =  direction * speed
	
func basic_attack():
	totalAttacks += 1
	if check_if_attack():
		inAnimation = true
		for hitbox in hitboxes:
			hitbox.setActive()
		print("attacking")
		animationPlayer.stop()
		animationPlayer.play("meleeAttacks/swipe_left")

func check_if_attack(increment=false):
	var tempAttacks = totalAttacks
	if increment:
		tempAttacks += 1
	if tempAttacks > comboAttacks:
		inAnimation = false
		canAttack = false
		following = false
		navAgent.target_desired_distance = actionDistance
		speedMod = 0
		timer.start(attackCooldown)
		return false
	else:
		return true

func _on_timer_timeout():
	timer.stop()
	# first checking if we were waiting to attack
	if attacking:
		circling = false
		following = true
		speedMod = 10
	totalAttacks = 0
	canAttack = true
