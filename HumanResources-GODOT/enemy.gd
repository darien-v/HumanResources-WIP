extends Area3D

@export var health = 30
@export var humanResources = 10
signal death(humanResources)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
# temporarily disable delta as a param till needed
func _process(_delta):
	if health <= 0:
		death.emit(humanResources);
		queue_free();

func _on_area_entered(area):
	if area.is_in_group("Weapon_Hitboxes") and area.isActive():
		print("weapon hit detected")
		health -= area.get_meta("damage")
		print(health)
	
