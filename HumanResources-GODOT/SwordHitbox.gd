extends Node3D

# checks if the area parent is attacking
var active = false;


# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("weapons", true)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func setActive():
	active = true;
func setInactive():
	active = false;
func isActive():
	if active:
		return true;
	return false;
