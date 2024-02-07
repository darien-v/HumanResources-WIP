extends Label3D

# lets us get option from main textbox script
@export var option = ""
@export var emotion = ""

# allows textbox to know which option we are
@export var optionNumber = 0
# so we can use this to know if we're selected
var optionSelected = 0

# will let textbox script know when we're done
@export var currentlyPrinting = false

# lets us know if options are currently active
@export var active = false

# the textbox itself
@onready var textbox = $".."

func reset_self():
	option = ""
	emotion = ""
	currentlyPrinting = false
	active = false
	self.visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# sets the option number assuming naming convention "optionx"
	optionNumber = ((self.name).replace("option", "")).to_int()


# Called every frame. 'delta' is the elapsed time since the previous frame.
# we use this to print instead of while loop, so that we can run concurrently
# although, delta is in seconds, so it may be too slow...
func _process(delta):
	# only have to run if options are active
	if active:
		# once done printing, check if option being selected
		if not currentlyPrinting:
			optionSelected = textbox.get("optionSelected")
			if optionSelected == optionNumber:
				onSelection()
			else:
				self.uppercase = false
		# check if a selection has been made
		active = textbox.get("showChoices")
		if not active:
			reset_self()
	
# sets option text and emotion
func setOption(optionText, optionEmotion):
	print("creating option")
	# make self visible
	self.visible = true
	# mark that this option is now active
	active = true
	# sets the object properties
	option = optionText
	emotion = optionEmotion
	currentlyPrinting = true
	printLetter()
	print("option created")
	
# the scuffed print functionality
func printLetter():
	# init
	var currentText = ""
	var textSpeed = .001
	# get the letters in reverse order so i can pop
	var letters = option.split('')
	for letter in letters:
		currentText = ''.join([currentText,letter])
		self.text = currentText
		$"../Timer".start(textSpeed)
		await $"../Timer".timeout
	currentlyPrinting = false
	print("done printing")

# option behavior when being selected
func onSelection():
	self.uppercase = true

# going to try to include mouseover functionality
# but no guarantees tee hee
func checkMouseover():
	pass
