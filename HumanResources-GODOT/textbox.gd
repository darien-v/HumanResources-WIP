# actual textbox functionality
# absolute *base* functionality taken from here https://www.youtube.com/watch?v=GzPvN5wsp7Y
# had to rewrite and add a shit ton
# also i need to clean this up for efficiency eventually
extends AnimatedSprite3D

# things we can adjust later
@export var textSpeed = 0.005
@export var showDialog = true

# we can have at max 305 chars per page
@export var maxChars = 305

# get the player object so we can determine interaction params
@onready var player = $"../.."

# basically state variables
var showingText = false
var printingText = true
var changePages = false
var showNextPage = true
var showChoices = false
var choicesInitialized = false
var finished = false

# all of the other vars we need
var dialogNode = "Start"
var dialog
var currentDialog
var dialogSplitPages = []
var numLetters
var currentLetter
var phraseNum = 0
var numPhrases = 0
var pageNum = 0
var interactions = 0

# also, we need to actually set up the textbox!
@onready var textboxAnim  = $"."
@onready var textbox_speaker = $textbox_speaker
@onready var textbox_dialogue = $textbox_dialogue
# and the ever infamous options
@onready var options = [$option1, $option2, $option3, $option4]
@export var optionSelected = 1
var numOptions = 0

# oh, and the portraits
@onready var speakerPortrait = $speaker_portrait
@onready var playerPortrait = $player_portrait
var playerShowing = false

# initializes our common vars. easier than copy paste
func initVars():
	#print("initializing")
	dialogNode = "Start"
	phraseNum = 0
	numPhrases = 0
	pageNum = 0
	interactions = 0
	optionSelected = 1
	dialogSplitPages.clear()
	finished = false
	showingText = true
	printingText = true
	showNextPage = true
	changePages = false
	showChoices = false
	playerShowing = false

# this is clunky, but allows us to have a variable dialog path so yay
func getDialogPath(interactionGroup, specificInteraction, interactionName, interactable) -> String:
	var dialogPath = ["res://dialogue",get_tree().get_current_scene().get_name(), interactionGroup]
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
	return dialogPath
	
# get our dialog tree name
func getDialogTreeName(specificInteraction, specificTree, interactionGroup, interactable, keys):
	# blank var to store attitude
	var attitude = ""
	# blank variable to hold our result
	var dialogTree = ""
	# use this information to determine possible tree name
	if specificInteraction:
		if specificTree == "":
			if interactionGroup == "NPC":
				attitude = player.checkNPCApproval()
				dialogTree = "Default" + "//" + attitude
		else:
			dialogTree = specificTree
	# then use the keys from the dialog dict to find actual tree name
	# first check if we have an exact match
	if dialogTree in keys:
		return dialogTree
	# if not, we gotta go through the keys individually
	# partial matches can happen in the case of keys like Approving//Neutral
	for key in keys:
		if dialogTree in key:
			return key
	# if no match, just use default
	return "Default"

# shows textbox and starts animation
func makeVisible():
	#print("showing textbox")
	textboxAnim.visible = true
	textboxAnim.play("textbox_test")
	textbox_speaker.visible = true
	textbox_dialogue.visible = true
	$Indicator.visible = false
	$Indicator.play("default")
	speakerPortrait.initialize()
	#print("textbox shown!")
	
# hides everything
# we do this rather than destroying/creating each time
func makeInvisible():
	# conditional prevents reset from coinciding with new instance
	if not (showingText or printingText):
		#print("hiding textbox")
		textboxAnim.visible = false
		textboxAnim.stop()
		textbox_speaker.visible = false
		textbox_dialogue.visible = false
		$Indicator.visible = false
		$Indicator.stop()
		textbox_speaker.text = ""
		textbox_dialogue.text = ""
		speakerPortrait.hideSelf()
		playerPortrait.hideSelf()
		#print("textbox hidden!")
	
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
	# need to pass these to path and tree
	# get all the variables we need from the player
	# maybe make interaction into its own object later? idk
	var interactionName = player.get("interactionName")
	var specificInteraction = player.get("specificInteraction")
	var specificTree = player.get("specificTree")
	var interactionGroup = player.get("interactionGroup")
	var interactable = player.get("interactable")
	# parse the dialog into something usable
	dialog = getDialog(interactionName, specificInteraction, specificTree, interactionGroup, interactable)
	assert(dialog, "Dialog not found")
	# get our current node of dialog
	currentDialog = dialog[dialogNode]
	# split that shit
	dialogSplitPages = dialogSplit()
	# start readin boah
	nextPhrase()
		
# get the dialog tree from specified file
func getDialog(interactionName, specificInteraction, specificTree, interactionGroup, interactable) -> Dictionary:
	var dialogPath = getDialogPath(interactionGroup, specificInteraction, interactionName, interactable)
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
		return temp[getDialogTreeName(specificInteraction, specificTree, interactionGroup, interactable, temp.keys())]
	else:
		return {}
		
func scrollOptions():
	# only scroll once previous scrolling done
	if not $option_indicator.get("moving"):
		# scrolling down
		if Input.is_action_just_pressed("move_back"):
			optionSelected += 1
			if optionSelected > numOptions:
				while optionSelected != 1:
					$option_indicator.moveUp()
					optionSelected -= 1
			$option_indicator.moveDown()
		# scrolling up
		elif Input.is_action_just_pressed("move_forward"):
			optionSelected -= 1
			if optionSelected <= 0:
				while optionSelected != numOptions:
					$option_indicator.moveDown()
					optionSelected += 1
			$option_indicator.moveUp()
		elif Input.is_action_just_pressed("interact"):
			#print("choice selected")
			$option_indicator.reset()
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
			$option_indicator.initialize()
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
	#print(choicesInitialized)
	
# when player presses interact, 
# check if we skip to end of dialog
# or if we are done with the current page of dialog
func checkCompletion():
	$Indicator.visible = finished
	if Input.is_action_just_pressed("interact"):
		# normal protocol
		if finished or showNextPage or changePages:
			#print("interaction leading to nextPhrase")
			nextPhrase()
		# protocol for skipping scroll
		else:
			#print("skipped to end of page")
			$textbox_dialogue.text = dialogSplitPages[pageNum]
			printingText = false
			showNextPage = true

# splits stuff up to fit into the box 
func dialogSplit():
	# clear our current dialogue from queue
	dialogSplitPages.clear()
	pageNum = 0
	# see how many phrases of dialog this node has
	numPhrases = len(currentDialog)
	#print(' '.join(["numPhrases", numPhrases]))
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
	#print("dialogSplitPages: " + ' '.join(dialogSplitPages))
	return dialogSplitPages

# the bulk of the functionality
func nextPhrase() -> void:
	#print("entered nextPhrase")
	#print(' '.join(["phraseNum", phraseNum]))
	# check if we've reached end of dialog
	if phraseNum >= numPhrases:
		#print("phraseNum exceeding")
		# check if there are any choices to display
		if showChoices and not printingText:
			#print("about to print choices")
			finished = false
			printChoices()
			return
		else:
			#print("dialog end")
			showingText = false
			printingText = false
			makeInvisible()
			return
	# check if we need to get new pages
	elif changePages:
		#print("changing pages")
		changePages = false
		showNextPage = true
		dialogSplitPages = dialogSplit()
	
	# only print page if necessary
	if showNextPage:
		#print("showing next page")
		# initializing globals
		finished = false
		showNextPage = false
		printingText = true
		# initializing locals
		var letters = []
		var currentText = ""
		$textbox_dialogue.text = currentText
		
		# get emotion and name, and see if there will be choices after printing
		var temp = currentDialog[phraseNum]
		var emotion = temp["Emotion"]
		var speaker = temp["Name"]
		$textbox_speaker.text = speaker
		
		# set up the portrait
		if speaker.to_lower() != "you":
			speakerPortrait.setPortrait(speaker)
		speakerPortrait.playEmotion(emotion)
		
		# set color according to emotion of speaker
		setEmotion(emotion)
		
		# if there are choices after printing, check if choices dict valid
		# if it is, indicate we will show choices at end
		if "Choices" in temp.keys():
			# if we havent yet, bring the player portrait in
			if not playerShowing:
				playerPortrait.comeOntoScreen()
				playerShowing = true
			if len(temp["Choices"].keys()) > 0:
				#print("choices available")
				showChoices = true
		else:
			showChoices = false
		
		# get array of characters to iterate over
		var text = dialogSplitPages[pageNum]
		letters = text.split()
		numLetters = len(text)
		
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
		#print("Finished printing")
		finished = true
		printingText = false
		# go to next page
		pageNum+=1
		
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
	#print("printing choices")
	# initializing
	showNextPage = false
	printingText = true
	var currentText = ""
	$textbox_dialogue.text = currentText
	speakerPortrait.pauseEmotion()
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
	# set color and player to match first option
	var firstEmotion = (options[0].get("emotion").split('//'))[0]
	textboxAnim.setEmotion(firstEmotion)
	playerPortrait.playEmotion(firstEmotion)
	# hold the script until choices are initialized
	while not choicesInitialized:
		checkChoicesInit()
	finished = true
	#print("finished setting choices")
	
# allows us to accept and process the choice
func processChoice():
	#print("entered processChoice")
	# pause player portrait
	playerPortrait.pauseEmotion()
	# get our object
	var selection = options[optionSelected-1]
	# indicate that we've completed an interaction
	interactions += 1
	# // is our indicator in case we need to go to a specific node
	var emotion = (selection.get("emotion")).split("//")
	#print(emotion)
	var temp
	# check if anything after //
	if len(emotion) > 1:
		# if so, adjust node and interactions accordingly
		if len(emotion[1]) > 0:
			dialogNode = emotion[1]
			# get only the number using regex
			var regex = RegEx.new()
			regex.compile("([0-9])*")
			interactions = (regex.search(emotion[1]).get_string()).to_int()
			# repeat interaction increment, otherwise it breaks
			interactions+=1
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
	optionSelected = 1
	# save consequence of choice
	player.processReaction(dialog[dialogNode][phraseNum]["Emotion"])
	nextPhrase()
	
func setEmotion(emotion):
	if emotion in player.get("positive"):
		self.set_modulate(Color(1,1,0.800,1))
	elif emotion in player.get("negative"):
		self.set_modulate(Color(0.800,1,1,1))
	elif emotion in player.get("strong"):
		self.set_modulate(Color(1,0.345,0.541,1))
	else:
		self.set_modulate(Color(1,1,1,1))
