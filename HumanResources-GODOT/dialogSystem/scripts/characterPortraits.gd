extends AnimatedSprite2D

var spriteFoldersLocation = "res://art/2D Sprites/character_portraits/"
var darkened = Color(.271,.271,.271,1)
var characterName = ""
# timing
@onready var timer = $"../../textbox/option_indicator/indicator_timer"
var timeInterval = .01

# allows us to change who the portrait shows
# the way it works is that each character will have their own 'spriteframes' file
# saved in their folder in "res://art/2D Sprites/character_portraits/[character_name]"
# and it will always be called "character_name.tres"
func setPortrait(tempName):
	# see if we even need to run this
	if characterName != tempName:
		characterName = tempName
	else:
		return
	# get our spriteframes
	tempName = tempName.to_lower()
	#var path = ''.join([spriteFoldersLocation,tempName,'/',tempName,'.tres'])
	#var frames = load(path)
	#print(frames)
	#self.set_sprite_frames(frames)
	#print(characterName + " " + path)

# make portrait visible
func initialize():
	self.visible = true
	
func hideSelf():
	self.visible = false
	self.stop()
	
# plays the appropriate emotion
func playEmotion(emotion):
	# make sure we're at default brightness
	self.set_modulate(Color(1,1,1,1))
	# play the appropriate animation
	var temp = emotion.to_lower()
	#self.play(temp)
	#print(self.get_animation())
	
# darkens the character and stops animation when not speaking
func pauseEmotion():
	self.stop()
	self.set_modulate(darkened)
	
# only for player portrait when making decision
# we can adjust these position values later, also only moving on x axis
func comeOntoScreen():
	# always start darkened and neutral
	#playEmotion("neutral")
	self.set_modulate(darkened)
	# get the original (goal) position and move offscreen
	var origX = self.position.x
	var offscreenOffset = 200
	var moveIncrement = offscreenOffset/10
	var offscreenPos = origX+offscreenOffset
	self.position.x = offscreenPos
	initialize()
	# slowly move self onscreen
	var moves = 0
	while moves < 10:
		print("moved")
		self.position.x -= moveIncrement
		moves += 1
		timer.start(timeInterval)
		await timer.timeout
	# once in position, pause
	pauseEmotion()

# Called when the node enters the scene tree for the first time.
func _ready():
	# invisible by default
	self.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
