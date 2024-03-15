# actual textbox functionality
# absolute *base* functionality taken from here https://www.youtube.com/watch?v=GzPvN5wsp7Y
# had to rewrite and add a shit ton
# also i need to clean this up for efficiency eventually
extends AnimatedSprite2D

# needed features:
# # initialization/reset of important variables
# # way to toggle visibility
# # function to get dialog filepath
# # function to get dialog tree name
# # # parse/process emotion from tree name/node name?
# # choice/option functionality
# # # print options
# # # listen for input
# # # # move optionIndicator
# # # # process option selection
# # function to split longer dialog into pages
# # function to differentiate between skipping textscroll and moving pages
# # keep the base functionality from the youtube video
# thoughts to streamline:
# # make use of signals to other nodes rather than state vars?

# things we can adjust later
@export var textSpeed = 0.005
@export var showDialog = true

# get the player object so we can determine interaction params
@onready var player = $"../../Player"

# signal to different objects that they need to reset
signal resetTextboxes
signal resetOptions
signal resetSprites

# signal to the options to print themselves
signal printOption(optionNum, key, text)

# signal to the option indicator to listen for input
signal playerOption(numOptions)

# basically state variables
var showingText = false
var printingText = true
var changePages = true
var showNextPage = true
var showChoices = false
var choiceSetup = false
var finished = false

# all of the other vars we need
var dialogNode = "Start"
var dialog
var currentDialogNode
var currentDialogText
var visibleDialogText
var numLetters
var currentLetter = 0
var phraseNum = 0
var numPhrases = 0
var interactions = 0

# also, we need to actually set up the textbox!
@onready var textboxAnim  = $"."
@onready var textbox_speaker = $"../speaker"
@onready var textbox_dialogue = $"../dialog"
# and the ever infamous options
@onready var optionIndicator = $option_indicator
@export var optionSelected = 1
var numOptions = 0
var initializedOptions = 0
var playerChoosing = false

# oh, and the portraits
@onready var speakerPortrait = $"../SpeakerSprite/speaker_portrait"
@onready var playerPortrait = $"../ResponseSprite/response_portrait"
var playerShowing = false

# initializes our common vars. easier than copy paste
func initVars():
	#print("initializing")
	dialogNode = "Start"
	phraseNum = 0
	numPhrases = 0
	interactions = 0
	optionSelected = 1
	finished = false
	showingText = true
	printingText = true
	showNextPage = true
	changePages = true
	showChoices = false
	playerShowing = false

# this is clunky, but allows us to have a variable dialog path so yay
func getDialogPath(interactionGroup, specificInteraction, interactionName, interactable) -> String:
	var dialogPath = ["res://dialogSystem/dialogue",get_tree().get_current_scene().get_name(), interactionGroup]
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
	print(dialogPath)
	return dialogPath
	
# get our dialog tree name
func getDialogTreeName(specificInteraction, specificTree, interactionGroup, interactable, keys):
	# blank variable to hold our result
	var dialogTree = ""
	# use this information to determine possible tree name
	if specificInteraction:
		if specificTree == "":
			if interactionGroup == "NPC":
				dialogTree = player.checkNPCApproval()
		else:
			dialogTree = specificTree
	# then use the keys from the dialog dict to find actual tree name
	# first check if we have an exact match
	if dialogTree in keys:
		return dialogTree
	# if not, we gotta go through the keys individually
	# partial matches can happen in the case of keys like Approving//Neutral
	print(dialogTree)
	for key in keys:
		#print("Key: " + key)
		var temp = key.split("//")
		print(temp)
		if dialogTree in temp:
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
	currentDialogNode = dialog[dialogNode]
	numPhrases = len(currentDialogNode)
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

# currently dont need anything initialized upon startup
func _ready():
	pass
 
# constantly runs in background
# allows dialog to happen upon interaction
func _process(_delta):
	# if we are showing text, normal processing
	if showingText:
		# if showing choices, check if they are done printing
		# if they are, then we wait for a selection
		if showChoices and not choiceSetup:
			if finished and not playerChoosing:
				playerOption.emit(numOptions)
				playerChoosing = true
		else:
			checkCompletion()
	# if the user prompted interaction, we show text
	elif Input.is_action_just_pressed("interact"):
		print("interaction pressed")
		if showingText == false and showDialog:
			print("starting interaction")
			startInteraction()
	
# receives signal to say choices have been initialized
func checkChoicesInit():
	# only mark true if all options initialized
	initializedOptions += 1
	print("initOptions: %s" % initializedOptions)
	print("numOptions: %s" % numOptions)
	if initializedOptions == numOptions:
		finished = true
		choiceSetup = false
		optionIndicator.initialize()
	
# when player presses interact, 
# check if we skip to end of dialog
# or if we are done with the current page of dialog
func checkCompletion():
	$Indicator.visible = finished
	if Input.is_action_just_pressed("interact"):
		# normal protocol
		if showChoices and choiceSetup:
			printChoices()
		elif finished or showNextPage or changePages:
			print("interaction leading to nextPhrase")
			printingText = true
			nextPhrase()
		# protocol for skipping scroll
		else:
			print("skipped to end of page")
			textbox_dialogue.text = currentDialogText
			if checkTextSpill(currentLetter):
				splitText(true)
			else:
				phraseNum += 1
				changePages = true
			printingText = false
			showNextPage = true

# checks if text is outside textbox bounds
# we do this by verifying total lines is same or less than visible lines
# if there is an invisible line, then it has been clipped
func checkTextSpill(index):
	# if at the start, skip. because obviously nothing is visible yet
	if index == 0:
		return false
	var totalLines = textbox_dialogue.get_line_count()
	var visibleLines = textbox_dialogue.get_visible_line_count()
	#print("Total Lines: %s" % totalLines)
	#print("Visible Lines: %s" % visibleLines)
	if visibleLines < totalLines:
		# indicate that we are not done
		# simply moving to another dialog page
		showNextPage = true
		return true
	return false
	
# splits the text in a way that ensures a word won't be split across pages
func splitText(scrollSkip=false):
	# truncate the dialog string using the currentLetter index
	currentLetter -= 1
	var len = len(currentDialogText)
	visibleDialogText = []
	for n in range(currentLetter,len):
		visibleDialogText.push_back(currentDialogText[n])
	visibleDialogText = ''.join(visibleDialogText)
	# if skipping textscroll, display this new text
	# and update currentLetter
	if scrollSkip:
		currentLetter += len
		textbox_dialogue.text = visibleDialogText

# the bulk of the functionality
func nextPhrase() -> void:
	print("entered nextPhrase")
	#print(' '.join(["phraseNum", phraseNum]))
	# check if we've reached end of dialog
	if phraseNum >= numPhrases:
		#print("phraseNum exceeding")
		#print("dialog end")
		showingText = false
		printingText = false
		makeInvisible()
		return
	# check if we need to get new page from node
	elif changePages:
		currentDialogText = currentDialogNode[phraseNum]["Text"]
		print(currentDialogText)
		visibleDialogText = currentDialogText
		changePages = false
		showNextPage = true
	
	# only print page if necessary
	if showNextPage:
		# initializing globals
		print(visibleDialogText)
		finished = false
		showNextPage = false
		printingText = true
		# initializing locals
		var letters = []
		var currentText = ""
		textbox_dialogue.text = currentText
		
		# get emotion and name, and see if there will be choices after printing
		var temp = currentDialogNode[phraseNum]
		var emotion = temp["Emotion"]
		var speaker = temp["Name"]
		textbox_speaker.text = speaker
		
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
				print("choices available")
				showChoices = true
				choiceSetup = true
		else:
			showChoices = false
			choiceSetup = false
		
		# get array of characters to iterate over
		letters = visibleDialogText.split()
		numLetters = len(visibleDialogText)
		
		# as we start a new page, start from the beginning
		# do a temp in case we split a page :3
		var tempCurrentLetter = 0
		
		# print the letters one at a time
		while tempCurrentLetter < numLetters:
			if printingText == false:
				break
			# check if the text has spilled over at all
			# if it has, we separate the rest of the dialog into another page 
			# and break loop
			if checkTextSpill(tempCurrentLetter):
				print("text spilling")
				currentLetter += tempCurrentLetter
				splitText()
				break
			currentText = ''.join([currentText,letters[tempCurrentLetter]])
			textbox_dialogue.text = currentText
			tempCurrentLetter += 1
			$Timer.start()
			await $Timer.timeout
		
		# once we finish printing, mark page as finished
		#print("Finished printing")
		finished = true
		printingText = false
		
		# update our position in the overall textblock
		currentLetter += tempCurrentLetter
		
		# if we're still reading from the same node, we know 
		# # checkTextSpill will have marked showNextPage = true
		# # if !showNextPage, we advance phraseNum
		if not showNextPage:
			changePages = true
			phraseNum += 1
			currentLetter = 0
		
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
	textbox_dialogue.text = ""
	# speaker will always be player when making choices
	textbox_speaker.text = "You"
	# get and print our options
	var choices = dialog[dialogNode][phraseNum-1]["Choices"]
	var choiceKeys = choices.keys()
	var index = 0
	# the process here is . uh um.
	# we will go over all the choices and assign them to an option
	# there can only be 4 maximum choices because uh. i decreed it.
	for key in choiceKeys:
		index += 1
		print(index)
		printOption.emit(index, choices[key], key)
	numOptions = index
	# hide the text indicator
	$Indicator.visible = false
	# hold the script until choices are initialized
	finished = false
	#print("finished setting choices")
	
# allows us to accept and process the choice
func processChoice(selection):
	#print("entered processChoice")
	# player no longer actively choosing
	playerChoosing = false
	# indicate that we've completed an interaction
	interactions += 1
	# no options initialized-- kill them
	initializedOptions = 0
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
	currentDialogNode = dialog[dialogNode]
	numPhrases = len(currentDialogNode)
	changePages = true
	# we are no longer showing choices
	showChoices = false
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
