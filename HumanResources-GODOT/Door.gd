extends Node3D

@export var openable = true
@export var unlockable = true
var opening = false
var rotateAmount = 0
@export var playerHasKey = false
@onready var interactionBox = $InteractionArea

# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("doors", true)
	if self.has_meta("locked"):
		if self.get_meta("locked") == true:
			openable = false
	if self.has_meta("key"):
		unlockable = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if opening:
		rotateAmount += 1
		if rotateAmount > 60:
			opening = false
		self.rotation_degrees.y -= 2
			
func check_openable(player):
	if self.get_meta("locked"):
		if unlockable:
			playerHasKey = player.checkInventory("keys", self.get_meta("key"))
			if playerHasKey:
				opening = true
