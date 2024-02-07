# actual textbox functionality
# absolute *base* functionality taken from here https://www.youtube.com/watch?v=GzPvN5wsp7Y
# had to rewrite and add a shit ton
# also i need to clean this up for efficiency eventually
extends AnimatedSprite3D

# things we can adjust later
@export var dialogPath = []
@export var textSpeed = 0.005
@export var showDialog = true

# we can have at max 305 chars per page
@export var maxChars = 305

# get the object the player is interacting with
@onready var player = $"../.."
var interactable = ""
var interactionGroup = ""
# and whether that object has its own file or not
var specificInteraction = false
var interactionName = ""
# if it has its own file, does it want us to activate a specific tree?
var specificTree = "N/A"
# if the object is an npc, we will need to know the npc's attitude
var attitude = "Neutral"
# and if this is the first interaction
var firstInteraction = false
# everything will have a default dialog tree we can use unless otherwise specified
var dialogTree = "Default"

# all of the other vars we need
var dialogNode = "Start"
var showingText = false
var printingText = true
var changePages = false
var showNextPage = true
var dialog
var currentDialog
var dialogSplitPages = []
var currentText = ""
var letters = []
var numLetters
var currentLetter
var phraseNum = 0
var numPhrases = 0
var pageNum = 0
var interactions = 0
var showChoices = false
var choicesInitialized = false
var finished = false

# also, we need to actually set up the textbox!
@onready var textboxAnim  = $"."
@onready var textbox_speaker = $textbox_speaker
@onready var textbox_dialogue = $textbox_dialogue
# and the ever infamous options
@onready var options = [$option1, $option2, $option3, $option4]
@export var optionSelected = 1
var numOptions = 0
# this allows us to adjust sprite based on option emotion
@export var optionEmotion = "Neutral"

# initializes our common vars. easier than copy paste
func initVars():
	print("initializing")
	interactable = player.get("interactable")
	interactionName = player.get("interactionName")
	interactionGroup = player.get("interactionGroup")
	specificInteraction = player.get("specificInteraction")
	dialogNode = "Start"
	optionEmotion = "Neutral"
	phraseNum = 0
	numPhrases = 0
	pageNum = 0
	interactions = 0
	optionSelected = 1
	currentText = ""
	letters.clear()
	dialogSplitPages.clear()
	finished = false
	showingText = true
	printingText = true
	showNextPage = true
	changePages = false
	showChoices = false
	dialogPath = ["res://dialogue",get_tree().get_current_scene().get_name()]

# this is clunky, but allows us to have a variable dialog path so yay
func getDialogPath():
	dialogPath.append(interactionGroup)
	# in theory, objects with specific dialog trees have their own files
	if specificInteraction:
		dialogPath.append(interactable)
		if interactionName != "":
			dialogPath.append(interactionName)
	else:
		dialogPath.append("default")
	# every file is a json always
	dialogPath = ['/'.join(dialogPath),".json"]
	dialogPath = ''.join(dialogPath)
	
# get our dialog tree name
func getDialogTreeName():
	if specificInteraction:
		if specificTree == "N/A":
			if firstInteraction:
				dialogTree = "FirstMeet"
			elif interactionGroup == "NPC":
				var attitudeNum = player.get("attitude")
				if attitudeNum > 0:
					attitude = "Default//Approving"
				elif attitudeNum < 0:
					attitude = "Default//Disapproving"
				else:
					attitude = "Default//Neutral"
				dialogTree = "Default"
		else:
			dialogTree = specificTree

# get the dialog tree's... dialog tree
func getDialogTreeValue(keys):
	var temp
	# first check if we have an exact match
	if dialogTree in keys:
		return dialogTree
	# if not, we gotta go through the keys individually
	# partial matches can happen in the case of keys like Approving//Neutral
	while len(keys) > 0:
		temp = keys.pop_back()
		if dialogTree in temp:
			return temp
	# if no match, just use default
	return "Default"

# shows textbox and starts animation
func makeVisible():
	print("showing textbox")
	textboxAnim.visible = true
	textboxAnim.play("textbox_test")
	textbox_speaker.visible = true
	textbox_dialogue.visible = true
	$Indicator.visible = false
	print("textbox shown!")
	
# hides everything
# we do this rather than destroying/creating each time
func makeInvisible():
	# conditional prevents reset from coinciding with new instance
	if not (showingText or printingText):
		print("hiding textbox")
		textboxAnim.visible = false
		textboxAnim.stop()
		textbox_speaker.visible = false
		textbox_dialogue.visible = false
		$Indicator.visible = false
		textbox_speaker.text = ""
		textbox_dialogue.text = ""
		print("textbox hidden!")
	
# specifically for clearing options
func hideOptions():
	for i in options:
		i.reset_self()
	
# just putting this here to declutter process
func startInteraction():
	# initialize vars
	initVars()
	# textbox becomes visible
	makeVisible()
	# timer controls how fast text scrolls
	$Timer.wait_time = textSpeed
	# get dialog file path
	getDialogPath()
	# get the dialog tree name
	getDialogTreeName()
	# parse the dialog into something usable
	dialog = getDialog()
	assert(dialog, "Dialog not found")
	# get our current node of dialog
	currentDialog = dialog[dialogNode]
	# split that shit
	dialogSplitPages = dialogSplit()
	# start readin boah
	nextPhrase()
	
func scrollOptions():
	# scrolling down
	if Input.is_action_just_pressed("move_back"):
		optionSelected -= 1
		if optionSelected <= 0:
			optionSelected = numOptions
	# scrolling up
	elif Input.is_action_just_pressed("move_forward"):
		optionSelected += 1
		if optionSelected > numOptions:
			optionSelected = 1
	elif Input.is_action_just_pressed("interact"):
		print("choice selected")
		processChoice()
		

# currently dont need anything initialized upon startup
func _ready():
	pass
 
# constantly runs in background
# allows dialog to happen upon interaction
func _process(_delta):
	# if we are showing text, normal processing
	if showingText:
		if showChoices and finished:
			$Indicator.visible = false
			if not choicesInitialized:
				checkChoicesInit()
			else:
				scrollOptions()
		else:
			checkCompletion()
	# if the user prompted interaction, we show text
	elif Input.is_action_just_pressed("interact") and showingText == false and showDialog:
		startInteraction()
	
# checks if choices have been initialized
func checkChoicesInit():
	choicesInitialized = false
	# initialized means no choices are still printing
	for i in options:
		choicesInitialized = i.get("currentlyPrinting")
	choicesInitialized = !choicesInitialized
	print(choicesInitialized)
	
# when player presses interact, 
# check if we skip to end of dialog
# or if we are done with the current page of dialog
func checkCompletion():
	$Indicator.visible = finished
	if Input.is_action_just_pressed("interact"):
		# normal protocol
		if finished or showNextPage or changePages:
			print("interaction leading to nextPhrase")
			nextPhrase()
		# protocol for skipping scroll
		else:
			print("skipped to end of page")
			$textbox_dialogue.text = dialogSplitPages[pageNum]
			printingText = false
			showNextPage = true

# get the dialog tree from specified file
func getDialog() -> Dictionary:
	# if file doesnt exist, we have an error
	assert(FileAccess.file_exists(dialogPath), "File path does not exist")
	# otherwise, get the json data from the file and store as list of dict
	var json_string = FileAccess.get_file_as_string(dialogPath)
	var output = JSON.parse_string(json_string)
	# now, our dicts will have a very special organization
	# it goes [interactable][dialogTree][dialogNode] 
	# and the name, emotion, text, choices are in there
	if typeof(output) == TYPE_ARRAY:
		# specifically get the dialog for the thing we are interacting with
		var temp = output[0][interactable]
		# get the dialogTree we want by looking through the keys
		return temp[getDialogTreeValue(temp.keys())]
	else:
		return {}
		
# splits stuff up to fit into the box 
func dialogSplit():
	# clear our current dialogue from queue
	dialogSplitPages.clear()
	pageNum = 0
	# see how many phrases of dialog this node has
	numPhrases = len(currentDialog)
	print(' '.join(["numPhrases", numPhrases]))
	# get the next set of dialogue
	# remember the structure: dialog[dialogNode] -> array of text
	var text = currentDialog[phraseNum]["Text"]
	# only do the splitting operation if necessary
	# otherwise, it's a waste of computing
	if len(text) > maxChars:
		# potential problem here in splitting up words across pages...
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
	print("dialogSplitPages: " + ' '.join(dialogSplitPages))
	return dialogSplitPages

# the bulk of the functionality
func nextPhrase() -> void:
	print("entered nextPhrase")
	print(' '.join(["phraseNum", phraseNum]))
	# check if we've reached end of dialog
	if phraseNum >= numPhrases:
		print("phraseNum exceeding")
		# check if there are any choices to display
		if showChoices and not printingText:
			print("about to print choices")
			finished = false
			printChoices()
			return
		else:
			print("dialog end")
			showingText = false
			printingText = false
			makeInvisible()
			return
	# check if we need to get new pages
	elif changePages:
		print("changing pages")
		changePages = false
		showNextPage = true
		dialogSplitPages = dialogSplit()
	
	# only print page if necessary
	if showNextPage:
		print("showing next page")
		# initializing
		finished = false
		showNextPage = false
		printingText = true
		currentText = ""
		$textbox_dialogue.text = currentText
		
		# get emotion and name, and see if there will be choices after printing
		var temp = currentDialog[phraseNum]
		var emotion = temp["Emotion"]
		var speaker = temp["Name"]
		$textbox_speaker.text = speaker
		
		# if there are choices after printing, check if choices dict valid
		# if it is, indicate we will show choices at end
		if "Choices" in temp.keys():
			if len(temp["Choices"].keys()) > 0:
				print("choices available")
				showChoices = true
		else:
			showChoices = false
		
		# get array of characters to iterate over
		var text = dialogSplitPages[pageNum]
		letters = text.split()
		numLetters = len(text)
		
		# havent got any portraits yet so we have placeholder lines lol
		var img = speaker + emotion + ".png"
		if FileAccess.file_exists(img):
			currentLetter = 0
		else: currentLetter = 0
		
		# as we start a new page, start from the beginning
		currentLetter = 0
		
		# print the letters one at a time
		while currentLetter < numLetters:
			if printingText == false:
				break
			currentText = ''.join([currentText,letters[currentLetter]])
			$textbox_dialogue.text = currentText
			currentLetter += 1
			$Timer.start()
			await $Timer.timeout
		
		# once we finish printing, mark page as finished
		print("Finished printing")
		finished = true
		printingText = false
		# go to next page and reset queue
		pageNum+=1
		letters.clear()
		
		# check if we've reached the end
		if pageNum >= len(dialogSplitPages):
			phraseNum+=1
			# tells us to go to the next set of pages
			changePages = true
		# check if we still need to do choices
		if showChoices:
			finished = false
	
	return

# basically copies the above but for printing choices
func printChoices():
	print("printing choices")
	# initializing
	showNextPage = false
	printingText = true
	currentText = ""
	$textbox_dialogue.text = currentText
	# speaker will always be player when making choices
	var speaker = "You"
	$textbox_speaker.text = speaker
	# get and print our options
	var choices = dialog[dialogNode][phraseNum-1]["Choices"]
	var choiceKeys = choices.keys()
	var index = 0
	# the process here is . uh um.
	# we will go over all the choices and assign them to an option
	# there can only be 4 maximum choices because uh. i decreed it.
	for key in choiceKeys:
		options[index].setOption(choices[key], key)
		index += 1
	numOptions = index
	# hold the script until choices are initialized
	while not choicesInitialized:
		checkChoicesInit()
	finished = true
	print("finished setting choices")
	
# allows us to accept and process the choice
func processChoice():
	print("entered processChoice")
	# get our object
	var selection = options[optionSelected-1]
	# indicate that we've completed an interaction
	interactions += 1
	# // is our indicator in case we need to go to a specific node
	var emotion = (selection.get("emotion")).split("//")
	var temp
	# check if anything after //
	if len(emotion) > 1:
		if len(emotion[1]) > 0:
			dialogNode = emotion[1]
		else:
			temp = emotion[0]
			# if nothing was after //, the next node is emotion+interaction#
			dialogNode = ''.join([temp, interactions])
	else:
		temp = emotion[0]
		# if nothing was after //, the next node is emotion+interaction#
		dialogNode = ''.join([temp, interactions])
	# get the new dialogNode data
	currentDialog = dialog[dialogNode]
	changePages = true
	# we are no longer showing choices
	showChoices = false
	choicesInitialized = false
	hideOptions()
	# reset timer
	$Timer.wait_time = textSpeed
	# show the new text
	phraseNum = 0
	# save consequence of choice
	player.processReaction(dialog[dialogNode][phraseNum]["Emotion"])
	nextPhrase()
