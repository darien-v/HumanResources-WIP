# actual textbox functionality
# absolute *base* functionality taken from here https://www.youtube.com/watch?v=GzPvN5wsp7Y
# had to rewrite and add a shit ton
# also i need to clean this up for efficiency eventually
extends AnimatedSprite3D

# things we can adjust later
@export var dialogPath = ""
@export var textSpeed = 0.05
@export var showDialog = true

# we can have at max 305 chars per page
@export var maxChars = 305

# get the object the player is interacting with
@onready var player = $"../.."
@onready var interactable = player.get("interactable")

# all of the other vars we need
var showingText = false
var printingText = true
var changePages = true
var phraseEnd = false
var showNextPage = true
var dialog
var currentDialog = ""
var dialogSplitPages = []
var letters = []
var numLetters
var currentLetter
var phraseNum = 0
var pageNum = 0
var finished = false

# also, we need to actually set up the textbox!
@onready var textboxAnim  = $"."
@onready var textbox_speaker = $textbox_speaker
@onready var textbox_dialogue = $textbox_dialogue

func initVars():
	phraseNum = 0
	pageNum = 0
	currentDialog = ""
	letters.clear()
	dialogSplitPages.clear()
	finished = false
	showingText = true
	printingText = true
	changePages = true
	phraseEnd = false

func makeVisible():
	textboxAnim.visible = true
	textboxAnim.play("textbox_test")
	textbox_speaker.visible = true
	textbox_dialogue.visible = true
	$Indicator.visible = false
	
func makeInvisible():
	textboxAnim.visible = false
	textboxAnim.stop()
	textbox_speaker.visible = false
	textbox_dialogue.visible = false
	$Indicator.visible = false
	textbox_speaker.text = ""
	textbox_dialogue.text = ""

func _ready():
	pass # we do nothing unless prompted
 
func _process(_delta):
	# if we are showing text, normal processing
	if showingText:
		checkCompletion()
	# if the user prompted interaction, we show text
	elif Input.is_action_just_pressed("interact") and showingText == false and showDialog:
		# initialize vars
		initVars()
		# textbox becomes visible
		makeVisible()
		# set the bounds of our textbox text
		var textbox_aabb = textboxAnim.get_aabb()
		textbox_speaker.custom_aabb = textbox_aabb
		textbox_dialogue.custom_aabb = textbox_aabb
		# now for animation stuff
		$Timer.wait_time = textSpeed
		dialog = getDialog()
		assert(dialog, "Dialog not found")
		nextPhrase()

func checkCompletion():
	$Indicator.visible = finished
	if Input.is_action_just_pressed("interact"):
		if finished or showNextPage:
			nextPhrase()
		else:
			$textbox_dialogue.text = dialogSplitPages[pageNum]
			printingText = false
			showNextPage = true

func getDialog() -> Array:
	assert(FileAccess.file_exists(dialogPath), "File path does not exist")
	
	var json_string = FileAccess.get_file_as_string(dialogPath)
	var output = JSON.parse_string(json_string)
	if typeof(output) == TYPE_ARRAY:
		return output[0][interactable]
	else:
		return []
		
# splits stuff up to fit into the box 
func dialogSplit():
	dialogSplitPages.clear()
	var text = dialog[phraseNum]["Text"]
	if len(text) > maxChars:
		text = text.split()
		var breakVar = false
		# conditional is a failsafe
		while breakVar == false:
			# check if we have reached the last page
			var textLen = len(text)
			if textLen < maxChars:
				breakVar = true
			var tempLetters = []
			for i in maxChars:
				# make sure we're not going past array bounds
				if i >= textLen:
					break
				tempLetters.append(text[i])
			# add the 
			dialogSplitPages.append(''.join(tempLetters))
			# reduce if necessary, if not just break
			if breakVar:
				break
			else:
				text = text.slice((maxChars-1), -1)
	else:
		dialogSplitPages.append(text)
	return dialogSplitPages
			
 
func nextPhrase() -> void:
	# check if we've reached end of dialog
	if phraseNum >= len(dialog):
		print("dialog end")
		makeInvisible()
		showingText = false
		return
	# check if we need to get new pages
	elif changePages:
		changePages = false
		dialogSplitPages = dialogSplit()
		print(dialogSplitPages)
	
	# only print page if necessary
	if showNextPage:
		# initializing
		finished = false
		showNextPage = false
		printingText = true
		currentDialog = ""
		$textbox_dialogue.text = currentDialog
		
		$textbox_speaker.text = dialog[phraseNum]["Name"]
		
		# get array of characters to iterate over
		var text = dialogSplitPages[pageNum]
		letters = text.split()
		numLetters = len(text)
		
		# havent got any portraits yet so we have placeholder lines lol
		var img = dialog[phraseNum]["Name"] + dialog[phraseNum]["Emotion"] + ".png"
		if FileAccess.file_exists(img):
			currentLetter = 0
		else: currentLetter = 0
		
		currentLetter = 0
		$textbox_dialogue.text = ""
		
		while currentLetter < numLetters:
			if printingText == false:
				break
			currentDialog = ''.join([currentDialog,letters[currentLetter]])
			$textbox_dialogue.text = currentDialog
			currentLetter += 1
			$Timer.start()
			await $Timer.timeout
		
		finished = true
		pageNum+=1
		letters.clear()
		
		# check if we've reached the end
		if pageNum >= len(dialogSplitPages):
			print("phraseNum incremented")
			phraseNum+=1
			changePages = true
			phraseEnd = true
			return
	
	return
