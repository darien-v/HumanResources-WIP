extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("watercoolers", true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func demo_func():
	$"../../../../UserInterface/completion".show()
