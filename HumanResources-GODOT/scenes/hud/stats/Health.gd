extends ProgressBar

var MAX_HEALTH = 100
var MIN_HEALTH = 0
var health = MAX_HEALTH
var elapsed = 0

# for smooth draining anim
var takingDamage = false
var damages = []


@onready var player = $"../../Player"

# Called when the node enters the scene tree for the first time.
func _ready():
	value = MAX_HEALTH
	player.connect_player_hurt(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if takingDamage:
		var index = 0
		var damageLen = len(damages)
		if damageLen != 0:
			for i in range(0,damageLen):
				if i >= len(damages):
					break
				var totalDamage = damages[index][1]
				value -= 1
				totalDamage += 1
				if totalDamage >= damages[index][0]:
					value += (totalDamage-damages[index][0])
					damages.pop_front()
					if len(damages) == 0:
						takingDamage = false
				else:
					damages[index][1] = totalDamage
					index += 1

func _on_damage(damageAmt):
	print(damageAmt)
	health -= damageAmt;
	damages.append([damageAmt, 0])
	print(damages)
	takingDamage = true
	# death condition
	if health < 0:
		$"../death".show()
		
func returnHealth():
	return health;
