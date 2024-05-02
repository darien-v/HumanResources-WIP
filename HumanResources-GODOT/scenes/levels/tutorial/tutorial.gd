extends Node

@onready var player = $Player
@onready var resources = $UserInterface/Resources
var paused = false
signal soul(humanResources)

# mini-functions to connect necessary signals
func connect_enemy_death(enemy):
	enemy.death.connect(self._on_kill)
func return_player():
	return player
func return_resources():
	return resources

# Called when the node enters the scene tree for the first time.
func _ready():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var floors = get_tree().get_nodes_in_group("floor")
	for enemy in enemies:
		enemy._connect_death(self)
		for floor in floors:
			enemy.add_exception(floor)
	get_tree().call_group("watercoolers", "set_on_interact", $UserInterface/completion)
	$smokecontrol/loader/smoke.load_complete()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	get_tree().call_group("enemies", "update_target_location", player.global_position)

func _on_pause():
	if not paused:
		get_tree().paused = true
		paused = true
	else:
		get_tree().paused = false
		paused = false

func _on_kill(humanResources, pos):
	print("killed")
	add_child(load("res://scenes/items/soulOrb/soul_orb.tscn").instantiate())
	get_tree().call_group("hr", "_connect_soul", self)
	soul.emit(humanResources, pos, player)
