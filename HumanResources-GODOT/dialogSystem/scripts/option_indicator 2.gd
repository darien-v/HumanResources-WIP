extends AnimatedSprite2D

# original positions
var origY
var origX
# target movement amounts
var yMovement = 40
# mini intervals to give animation illusion
var yInterval = yMovement/10
# lets us know what is currently selected and how many possible selections
@export var selection = 1
@export var options = 4
# timing
@onready var timer = $indicator_timer
var timeInterval = .0001
# lets scroller know we're moving
@export var moving = false
# activates the scroller
var active = false
# lets the text controller know an option has been selected
signal optionSelected(optionIndex)

# Called when the node enters the scene tree for the first time.
func _ready():
	origY = self.position.y
	origX = self.position.x


# use this to actually do the shit
func initialize():
	self.visible = true
	self.play("default")
	selection = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# only need to listen for input if active
	if active:
		if Input.is_action_just_pressed("move_forward"):
			checkOutOfBounds(true)
		elif Input.is_action_just_pressed("move_back"):
			checkOutOfBounds(false)
		elif Input.is_action_just_pressed("interact"):
			active = false
			optionSelected.emit(selection)
			reset()

# check if movement is possible
func checkOutOfBounds(up):
	if up:
		selection-=1
		if selection <= 0:
			moveDown(options-1)
			selection = options
		else:
			moveUp()
	else:
		selection+=1
		if selection > options:
			moveUp(selection-options)
			selection = 1
		else:
			moveDown()

# moves the indicator up one option
func moveUp(iters=1):
	moving = true
	var moves = 0
	while moves < (10*iters):
		self.position.y -= yInterval
		moves+=1
		timer.start(timeInterval)
		await timer.timeout
	moving = false
	iters-=1
	
# moves the indicator down one option
func moveDown(iters=1):
	moving = true
	var moves = 0
	while moves < (10*iters):
		self.position.y += yInterval
		moves+=1
		timer.start(timeInterval)
		await timer.timeout
	moving = false
	iters-=1
		
# listens to the textbox to know if we're active
func becomeActive(numOptions):
	print("optionIndicator active")
	initialize()
	active = true
	options = numOptions

# resets the indicator position
func reset():
	self.visible = false
	self.position.y = origY
	self.position.x = origX
	self.stop()
	active = false
