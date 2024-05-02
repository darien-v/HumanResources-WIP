extends ProgressBar

# the player can change these later by levelling up
@export var MAX_STAMINA = 100

var MIN_STAMINA = 0

var regen = false
var defaultRegen = .5
var regenChunk
var regenModifier = 1

# allows player to know if they have enough stamina for action
var stamina = MAX_STAMINA;
var sufficientStamina = true;

# allows us to change these values later
var lightAttackStamina = 10;
var rollStamina = 5
# lets us consolidate functions
var staminaDiff = 0;

# lets us easily access staminaDiffs
var diffByType = 	{
						"light_attack":10,
						"heavy_attack":20,
						"roll":5,
						"sprint":.25
					}

@onready var timer = $"../Timer"

# mini-functions to connect necessary signals
func connect_player_signals(player):
	player.staminaUse.connect(self._on_stamina_use)
	player.actionDone.connect(self._on_action_done)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	timer.stop()
	regenChunk = defaultRegen / 100
	value = MAX_STAMINA

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if regen:
		var index = 0
		while index < 100:
			stamina += regenChunk * regenModifier
			index += 1
	if stamina >= MAX_STAMINA:
		stamina = MAX_STAMINA
		regen = false
	value = stamina
	
func _on_stamina_use(type):
	staminaDiff = diffByType[type]
	calcStamina();
	
func _on_action_done():
	timer.start(.5)

func manualChange(amt):
	staminaDiff = amt
	calcStamina();

func calcStamina():
	if stamina >= staminaDiff:
		sufficientStamina = true;
		stamina -= staminaDiff;
	else:
		sufficientStamina = false;

func checkStamina():
	if sufficientStamina:
		regen = false
		timer.stop()
		return true;
	return false;
func returnStamina():
	return stamina;
	
func _on_timer_timeout():
	timer.stop()
	regen = true
