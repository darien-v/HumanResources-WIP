extends Control

@onready var optionIndicator = $textbox/option_indicator
@onready var loadingScreen = $smokecontrol/loader/smoke
var loading = false
var newScene

# will eventually do something
func load_save():
	pass
	
# TODO: create save file
func new_game():
	print("new game")
	newScene = "res://scenes/levels/tutorial/tutorial.tscn"
	start_loading()

func start_loading():
	loadingScreen.fade_overlay()
	loadingScreen.make_visible()
	optionIndicator.queue_free()
	loading = true
	ResourceLoader.load_threaded_request(newScene)

# Called when the node enters the scene tree for the first time.
func _ready():
	loadingScreen.make_invisible()
	optionIndicator.becomeActive(2)
	$option1.set("option", "New Game")
	$option2.set("option", "Load File")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if loading:
		if ResourceLoader.load_threaded_get_status(newScene) == 3:
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(newScene))
