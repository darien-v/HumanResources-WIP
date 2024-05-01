extends Node3D

var onInteract
var active = true

# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("watercoolers", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_active(state=true):
	active = state
func return_active():
	return active

func set_on_interact(obj):
	onInteract = obj

func demo_func():
	if active:
		onInteract.show()
