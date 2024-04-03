extends Marker3D

var camera_distance = 13
var max_camera_distance_from_player = 4
var z_offset = 12
@onready var speed_factor = get_parent().speed / max_camera_distance_from_player

# Called when the node enters the scene tree for the first time.
func _ready():
	look_at_from_position((Vector3.UP + Vector3.BACK) * camera_distance,        
					   get_parent().position, Vector3.UP)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x = lerp(position.x, get_parent().position.x, speed_factor * delta)
	position.z = lerp(position.z, z_offset + get_parent().position.z, speed_factor * delta)
