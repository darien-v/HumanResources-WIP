extends "res://scenes/characters/enemies/enemy.gd"


const SPEED = 4

# instance of enemy class
var enemy
var dead

# attack names
var melee
var range
var ranged = false

var rangeDistance = 10
var meleeDistance = 5

# special to this enemy
var rubberBands = []
var mainBand

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func connect_death(scene):
	enemy._connect_death(scene)

func _ready():
	# decide right or left handed
	var rng = RandomNumberGenerator.new()
	var hand
	if rng.randi_range(0,1) == 1:
		print("lefty")
		hand = "left"
		melee = "contortionist/swipe_left"
		range = "contortionist/fling_left"
	else:
		print("righty")
		hand = "right"
		melee = "contortionist/swipe_right"
		range = "contortionist/fling_right"
	# init enemy
	enemy = Enemy.new()
	enemy.pos = global_position
	self.add_to_group("enemies", true)
	enemy.set_navs($Pivot, $NavigationAgent3D, $Pivot/VisionArea, $Pivot/Eyes/VisionRaycast, $Timer, $Pivot/contortionist/Armature/AnimationPlayer)
	enemy.set_defaults(self.get_meta("damage"))
	enemy.humanResources = self.get_meta("HR")
	enemy.health = self.get_meta("health")
	enemy.attackDistance = rangeDistance
	enemy.actionDistance = 15
	# custom contortionist animations
	enemy.idleAnim = "contortionist/idle"
	enemy.walkAnim = "contortionist/walk"
	enemy.dyingAnim = "contortionist/dying"
	enemy.animationPlayer.animation_finished.connect(self._on_animation_player_animation_finished)
	# find the fucing. ruber bans
	for band in enemy.pivot.find_children("band_hb", "Area3D", true):
		rubberBands.append(band)
		if hand in band.get_parent().get_parent():
			mainBand = band
	enemy.hitboxes.append(mainBand)

func _physics_process(delta):
	self.rotation.x = 0
	enemy.pivot.rotation.x = 0
	if enemy.initialized:
		enemy.pos = global_position
		if not dead:
			if enemy.doAttack and not enemy.inAnimation:
				decide_attack()
		# default physics run for enemies
		enemy.default_physics_process(delta)
		if not dead:
			if not enemy.inAnimation:
				velocity = enemy.velocity
				# Add the gravity.
				if not is_on_floor():
					velocity.y -= gravity * delta
				else:
					velocity.y = 0
				move_and_slide()
			dead = true if enemy.dying else false

func decide_attack():
	var targetDistance = enemy.return_target_distance()
	if targetDistance <= meleeDistance:
		enemy.animationPlayer.speed_scale = 2.5
		if enemy.target.velocity == Vector3.ZERO:
			enemy.basic_attack(melee)
		else:
			ranged_attack()
	elif targetDistance <= rangeDistance:
		ranged_attack()
			
func ranged_attack():
	enemy.totalAttacks += 1
	if enemy.check_if_attack():
		enemy.timer.start(enemy.attackWait)
		enemy.inAnimation = true
		for hitbox in enemy.hitboxes:
			hitbox.setActive()
		print("attacking")
		enemy.animationPlayer.stop()
		enemy.animationPlayer.play(range)
		stretch_band()
		enemy.totalAttacks += 1
		
func stretch_band(rot=Vector3(-71.8,93.8,-94),pos=Vector3(0,.2,0)):
	var band = mainBand.get_parent()
	band.find_child("AnimationPlayer").play("stretch_z")

func _on_animation_player_animation_finished(animName):
	print("ANIM %s DONE" % animName)
	if "dying" in animName:
		death.emit(enemy.humanResources, enemy.pos)
		queue_free()
	elif not enemy.dying:
		enemy.inAnimation = false
		if enemy.attacking:
			enemy.attacking = false
			enemy.animationPlayer.speed_scale = 1.5
		for hitbox in enemy.hitboxes:
			hitbox.setInactive()
