extends Marker3D

var max_camera_distance_from_player = 4
@onready var parent = $".."
@onready var speed_factor = parent.speed / max_camera_distance_from_player

# check if parent has moved !
var parent_oldpos = Vector3.ZERO
var parent_olddir = Vector3.ZERO

# rngesus ?
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	parent_oldpos = parent.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
# TODO: Make it so that camera does not overshoot
func _process(delta):
	var modifier = speed_factor * delta
	var overshooter = the_jiggler(modifier)
	# calculate target distance
	global_position.x = lerp(global_position.x, overshooter.x, modifier)
	global_position.z = lerp(global_position.z, overshooter.z, modifier)
	
func the_jiggler(modifier):
	var parent_pos = parent.global_position
	var overshooter = parent_pos
	# if the player is standing still, normalize camera to match player (do nothing)
	# otherwise, add some jiggle for "realism," "dynamism," etc
	if parent_pos != parent_oldpos:
		parent_oldpos = parent_pos
		var momentum = parent.get("momentum")
		if momentum.x != 0:
			overshooter.x = overshooter.x + 1 if overshooter.x < 0 else overshooter.x - 1
		if momentum.z != 0:
			overshooter.z = overshooter.z + 1 if overshooter.z < 0 else overshooter.z - 1
	else:
		modifier /= 2
	return overshooter
	
