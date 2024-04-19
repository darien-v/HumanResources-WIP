extends ProgressBar

# the player can change these later by levelling up
@export var MAX_STAMINA = 100

var MIN_STAMINA = 0

var elapsed = 0

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
						"lightAttack":10,
						"heavyAttack":20,
						"roll":5,
						"sprint":.25
					}

# mini-functions to connect necessary signals
func connect_stamina_use(player):
	player.staminaUse.connect(self._on_stamina_use)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	value = MAX_STAMINA

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	elapsed += delta
	if elapsed >= 1 and stamina < MAX_STAMINA:
		stamina += 1
		value = stamina
		elapsed = 0
	
func _on_stamina_use(type):
	staminaDiff = diffByType[type]
	calcStamina();

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
		return true;
	return false;
func returnStamina():
	return stamina;
