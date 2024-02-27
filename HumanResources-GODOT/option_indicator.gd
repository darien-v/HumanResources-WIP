extends AnimatedSprite3D

# original positions
var origY
var origZ
# target movement amounts
var yMovement = .12
var zMovement = .007
# mini intervals to give animation illusion
var zInterval = zMovement/10
var yInterval = yMovement/10
# timing
@onready var timer = $indicator_timer
var timeInterval = .0001
# lets scroller know we're moving
@export var moving = false

# Called when the node enters the scene tree for the first time.
func _ready():
	origY = self.position.y
	origZ = self.position.z


# use this to actually do the shit
func initialize():
	self.visible = true
	self.play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# moves the indicator up one option
func moveUp():
	moving = true
	var moves = 0
	while moves < 10:
		self.position.y += yInterval
		self.position.z += zInterval
		moves+=1
		timer.start(timeInterval)
		await timer.timeout
	moving = false
	
# moves the indicator down one option
func moveDown():
	moving = true
	var moves = 0
	while moves < 10:
		self.position.y -= yInterval
		self.position.z -= zInterval
		moves+=1
		timer.start(timeInterval)
		await timer.timeout
	moving = false

# resets the indicator position
func reset():
	self.visible = false
	self.position.y = origY
	self.position.z = origZ
	self.stop()
