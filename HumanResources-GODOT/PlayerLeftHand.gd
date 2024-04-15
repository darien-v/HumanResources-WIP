extends BoneAttachment3D

@onready var player = $"../../../../.."

var currentlyHolding = null

# paths and transformation adjustments for each object
var itemData = {
					"Amoray Note":
					{
						"path":"res://weapons/Amoray Note.tscn",
						"transformations":
						{
							"position":Vector3(0.221,0.255,-0.018),
							"rotation":Vector3(-39.1,-64.9,13.3),
							"scale":Vector3(1,1,1)
						}
					}
				}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# allows us to clear items from hand
func unequip():
	if currentlyHolding != null:
		currentlyHolding.queue_free()
		currentlyHolding = null

# called when the player equips something in this hand
func equip(item):
	# make sure hands are empty
	unequip()
	# load item node from item name
	var scene = (load(itemData[item]["path"]))
	var node = scene.instantiate()
	# add the node as child, store it as being held
	add_child(node)
	currentlyHolding = node
	# oh also set the hitbox. kinda important
	player.setHitbox(node.find_child("hitbox"))
	applyTransforms(item)
	# kill the interaction hitbox, if applicable
	var oldHitbox = node.find_child("InteractionArea")
	if oldHitbox != null:
		print(oldHitbox)
		oldHitbox.queue_free()
	
func applyTransforms(item):
	var temp = itemData[item]["transformations"]
	for key in temp:
		currentlyHolding.set(key, temp[key])
