extends Control

@onready var indicator = $textbox/Indicator
@onready var dialogBox = $dialog
@onready var textbox = $textbox
var keys = []
var objects = {}
var index = 0
var objName
var persistentHide = false

func show_self():
	if len(keys) > 0:
		textbox.visible = true
		# indicator.visible = true
		dialogBox.visible = true
		indicator.play("default")
		if persistentHide:
			persistentHide = false
			show_object()
	
func hide_self(persistentin=false):
	textbox.visible = false
	indicator.visible = false
	dialogBox.visible = false
	indicator.stop()
	persistentHide = persistentin

func get_current():
	if textbox.visible:
		return objects[keys[index]]["object"]
	else:
		return null

func update_objects(newObjects):
	keys = newObjects.keys()
	objects = newObjects
	var keylen = len(keys)
	# check if index needs to be adjusted
	if index >= keylen:
		index = keylen - 1
	if keylen > 1:
		indicator.visible = true
	else:
		indicator.visible = false
	if keylen <= 0:
		index = 0
		hide_self()
	else:
		show_object()

func show_object():
	# check if we need to show self
	if not textbox.visible and not persistentHide:
		show_self()
	var obj = objects[keys[index]]
	dialogBox.text = obj["text"]

func change_index(amt):
	if textbox.visible:
		index += amt
		var keylen = len(keys)
		if index >= keylen:
			index = 0
		elif index < 0:
			index = keylen - 1
		show_object()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
