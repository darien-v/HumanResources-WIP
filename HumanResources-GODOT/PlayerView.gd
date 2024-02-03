extends Camera3D

var dragging = false
var stopTimer = false
var reset = false

@onready var camera = $"."

# we can adjust sensitivity
@export var velocityFactor = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	$cameraTimer.start()

func _input(event):
	if $"../textbox_temp".visible == false:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			# start moving camera
			if not dragging and event.pressed:
				dragging = true
				stopTimer = true
			# Stop dragging if the button is released.
			if dragging and not event.pressed:
				dragging = false
				stopTimer = false
				reset = false
				$cameraTimer.start(7)

		if event is InputEventMouseMotion and dragging:
			# While dragging, move the sprite with the mouse.
			camera.rotation.y += event.relative.x/velocityFactor
			print(camera.rotation.y)
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $"../textbox_temp".visible == false:
		if $cameraTimer.is_stopped() and !dragging and !reset:
			returnCamera()
		elif stopTimer:
			$cameraTimer.stop()
	else:
		camera.rotation.y = 0
		dragging = false
		stopTimer = false
		reset = false
		
func returnCamera():
	print("entered returnCamera")
	var difference = camera.rotation.y
	print(difference)
	var increment = camera.rotation.y / 100
	print(increment)
	while camera.rotation.y != 0:
		if stopTimer:
			break
		camera.rotation.y -= increment
		print(camera.rotation.y)
		$cameraTimer.start(.01)
		await $cameraTimer.timeout
		if camera.rotation.y < 0.01 and camera.rotation.y > -0.01:
			camera.rotation.y = 0
	reset = true
	print("reset complete")
