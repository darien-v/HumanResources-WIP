extends Area3D

var health = 30
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
# temporarily disable delta as a param till needed
func _process(_delta):
	if health <= 0:
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("weapon_hitboxes"):
		print("weapon hit detected")
		health -= area.get_meta("damage")
		print(health)
	
