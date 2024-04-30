extends AnimationPlayer

@onready var parent = $"../../.."
@onready var skeleton = $"../Armature/Skeleton3D"

var defaultBlend = .5
var blendOverrides =  	[
							"running/runningTurnaround",
							"walkCycles/walkingTurnAround"
						]
var poseLoops = [
					"running/runningBasic",
					"walkCycles/walkingBasic"
				]
var anim = ""
var reset = true
var stopped = false

# Connect signal(s) here
func _ready():
	parent.connect_anim_finish(self)

func reset_rest(returnAnim = "none", currentPos = -1):
	print("reset")
	var numBones = skeleton.get_bone_count()
	var i = 0
	while i<numBones:
		skeleton.set_bone_rest(i, skeleton.get_bone_pose(i))
		i+=1
	if returnAnim != "none":
		reset = false
		if currentPos == -1:
			stop()
			play(returnAnim)
		else:
			print("playing from last pos")
			play()
			seek(currentPos, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_animation == "":
		stopped = true
	if reset and not stopped:
		var currentPos = get_current_animation_position()
		if anim in blendOverrides and currentPos >= get_current_animation_length() -.5:
			print("blendOverrides %s" % anim)
			#playback_default_blend_time = 0
			pause()
			seek(get_current_animation_length(), true)
			reset_rest(anim, currentPos)
			reset = false
		elif anim in poseLoops and currentPos > .5:
			reset_rest()
			reset = false

func _on_animation_started(anim_name):
	print("STARTED %s" % anim_name)
	print("PREV %s" % anim)
	if anim != anim_name:
		#playback_default_blend_time = defaultBlend
		reset = true
	anim = anim_name
	stopped = false
func _on_animation_finished(anim_name):
	if reset:
		reset_rest()
	stopped = true
