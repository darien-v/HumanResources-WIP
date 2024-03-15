extends CharacterBody3D

@export var health = 30
@export var humanResources = 10
signal death(humanResources)

# player speed in m/s
@export var speed = 14
# downward acceleration in m/s
@export var fall_acceleration = 75
# jumping (vertical) impulse in m/s
@export var jump_impulse = 20

var target_velocity = Vector3.ZERO

# on object creation, get the starting position
func _ready():
	pass

func _physics_process(delta):
	move_and_slide()
	enemy_collisions()
	
# putting things into tiny functions
# so the main one is a little less cluttered

# player movement function
func move_player(delta):
	# input direction
	var direction = Vector3.ZERO
		
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
	enemy_collisions()
	
# player collision checker
func enemy_collisions():
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()

		# If the collision is with ground
		if collider == null:
			continue

		# If the collision is with a weapon
		if collider.is_in_group("Weapon_Hitboxes"):
			# if the weapon is actively attacking
			if collider.isActive():
				print("Hit by weapon")
				# prevent multiple damage instances in one hit
				collider.setInactive()
				var health = self.get_meta("health")
				health-=collider.get_meta("baseDamage")
				if health <= 0:
					death.emit(humanResources)
					queue_free()
				else:
					self.set_meta("health", health)
	
