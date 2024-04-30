extends RigidBody3D

@onready var emitter = $GPUParticles3D
@onready var navAgent = $NavigationAgent3D
@onready var resources = $"../UserInterface/Resources"
@onready var timer = $Timer
var targetAcquired = false
var soulSet = false
var soulConnected = false
var active = false
var finished = false
var ending = false

var hr
var pos
var player

func goto_player(playerIN):
	player = playerIN

func update_target():
	navAgent.target_position = player.global_position

func _connect_soul(node):
	node.soul.connect(self._set_soul)
	soulConnected = true

# Called when the node enters the scene tree for the first time.
func _ready():
	print("created")
	timer.stop()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not soulConnected:
		queue_free()
	if active:
		if not soulSet:
			_set_soul_func(hr,pos,player)
		if ending:
			return
		if finished:
			explode()
			return
		update_target()
		var currPos = global_position
		var nextPos = navAgent.get_next_path_position()
		linear_velocity = (nextPos-currPos).normalized() * 10
		move_and_collide(linear_velocity * delta)

func _set_soul(humanResources, posIn, playerIn):
	hr = humanResources
	pos = posIn
	player = playerIn
	active = true
func _set_soul_func(humanResources, pos, player):
	soulSet = true
	if not targetAcquired:
		self.set_meta("value", humanResources)
		global_position = Vector3(pos.x, 4, pos.z)
		goto_player(player)

func _on_navigation_agent_3d_target_reached():
	if not targetAcquired:
		if not finished:
			linear_velocity = Vector3.ZERO
			freeze = true
			targetAcquired = true
			finished = true
	
func explode():
	if targetAcquired and finished:
		emitter.explosiveness = 1
		emitter.process_material.set_param_min(1,.75)
		emitter.process_material.set_param_max(1,29)
		emitter.process_material.set_param_min(15,2.45)
		emitter.process_material.set_param_max(15,12)
		emitter.one_shot = true
		emitter.lifetime = 1
		timer.start(1)
		ending = true

func _on_timer_timeout():
	resources.gain(self.get_meta("value"))
	print("deleting self goodbye")
	queue_free()
