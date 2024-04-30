extends GPUParticles2D

@onready var overlay = $"../../ColorRect"

var stop = false
var fadeIn = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if stop:
		self.one_shot = true
		overlay.color.a -= .01
	elif fadeIn:
		overlay.color.a += delta
		
func load_complete():
	stop = true
	lifetime = 1

func fade_overlay():
	overlay.color.a = 0
	fadeIn = true
func make_invisible():
	emitting = false
	visible = false
	$"../../ColorRect".visible = false
func make_visible():
	emitting = true
	visible = true
	$"../../ColorRect".visible = true


func _on_finished():
	queue_free()
