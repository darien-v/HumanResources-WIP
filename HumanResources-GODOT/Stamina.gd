extends Label

# the player can change these later by levelling up
@export var MAX_STAMINA = 100

var MIN_STAMINA = 0

var elapsed = 0

# allows player to know if they have enough stamina for action
var stamina = MAX_STAMINA;
var sufficientStamina = true;

# allows us to change these values later
var lightAttackStamina = 10;
# lets us consolidate functions
var staminaDiff = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	elapsed += delta
	if elapsed >= 1 and stamina < MAX_STAMINA:
		stamina += 1
		text = "STAMINA: %s" % stamina
		elapsed = 0

func _on_light_attack():
	staminaDiff = lightAttackStamina;
	calcStamina();

func calcStamina():
	if stamina >= staminaDiff:
		sufficientStamina = true;
		stamina -= staminaDiff;
		text = "STAMINA: %s" % stamina
	else:
		sufficientStamina = false;

func checkStamina():
	if sufficientStamina:
		return true;
	return false;
func returnStamina():
	return stamina;
