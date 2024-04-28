extends RichTextLabel

# lets us get option from main textbox script
@export var option = ""
@export var emotion = ""
@export var target = ""
@export var consequence = ""

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

# player portrait will be controlled by signals

# lets text controller know if printing done
signal initialized
# lets text controller know which option selected
signal selectionMade(option)

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
			if optionSelected == self.get_meta("index"):
				onSelection()
			else:
				self.uppercase = false
		# check if a selection has been made
		active = textbox.get("showChoices")
	
# sets option text and emotion
func setOption(index, choice):
	if index == self.get_meta("index"):
		print("creating option")
		# only create option if index matches
		# make self visible
		self.visible = true
		# mark that this option is now active
		active = true
		# sets the object properties
		emotion = choice['emotion']
		option = choice['text']
		target = choice['target']
		consequence = choice['consequence']
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
		print(currentText)
		self.text = currentText
		$"../textbox/Timer".start(textSpeed)
		await $"../textbox/Timer".timeout
	currentlyPrinting = false
	print("done printing")
	initialized.emit()

# option behavior when being selected
func onSelection():
	# go all caps bitch
	self.uppercase = true
	# change textbox color and player portrait based on option emotion
	var emotionTemp = (self.emotion.split('//'))[0]

# going to try to include mouseover functionality
# but no guarantees tee hee
func checkMouseover():
	pass


func _on_option_indicator_option_selected(optionIndex):
	if optionIndex == self.get_meta("index"):
		selectionMade.emit(self)
	reset_self()
