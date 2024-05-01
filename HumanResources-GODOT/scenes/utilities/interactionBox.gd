extends Area3D

# this basically just defines the behavior for objects that can be picked up
# npcs that can be talked to
# etc
# allows us to put an area around them that basically says
# # "if you are in x distance, you can interact with me!"

# the object this collision concerns
var parent
var objName

# if the object can be picked up
var collectible = false
# if the object can be equipped
var equipable = false

# lets us know if the player is actively interacting with this object
# this is a TODO later
var active = true

# Called when the node enters the scene tree for the first time.
func _ready():
	# get whatever our parent node is
	parent = get_parent()
	objName = parent.name
	# check if collectible or equipable
	if parent.is_in_group("collectibles"):
		self.add_to_group("collectibles", true)
		collectible = true
	if parent.is_in_group("equipables"):
		self.add_to_group("equipables", true)
		equipable = true
	if parent.is_in_group("doors"):
		self.add_to_group("doors", true)
	if parent.is_in_group("watercoolers"):
		self.add_to_group("watercoolers", true)
	# default to monitoring
	monitoring = true
	# mark this as an interactable
	self.add_to_group("interactables", true)
	# connect signals to self
	self.area_entered.connect(self._on_area_entered)
	self.area_exited.connect(self._on_area_exited)

# self-explanatory
func toggle_monitoring():
	monitoring = !monitoring
func toggle_active():
	active = !active
func return_active():
	return active
func return_name():
	return objName

# allows us to send object to player upon player entering area
# also allows us to verify player is the one entering
func _on_area_entered(area):
	# check that the area's parent is player
	var temp = area.get_parent()
	if temp.name == "Player":
		temp.entered_interactable_area(self)
# allows us to let player know theyve left the area
func _on_area_exited(area):
	# check that the area's parent is player
	var temp = area.get_parent()
	if temp.name == "Player":
		temp.exited_interactable_area(return_name())

# special case for things that can be picked up and/or equipped
# after being added to inventory, this area3d node DIES
# TODO: ACTUALLY HAVE AN INVENTORY
func pickedUp(player):
	if equipable:
		if parent.is_in_group("weapons"):
			var type = parent.get_meta("type")
			player.equipWeapon(objName, type)
	parent.queue_free()
