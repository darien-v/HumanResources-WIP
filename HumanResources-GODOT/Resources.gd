extends Label

var MIN_RESOURCES = 0
var resources = 0;

# mini-functions to connect necessary signals
func connect_enemy_death(enemy):
	enemy.death.connect(self._on_kill)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	text = "HR: %s" % resources;
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_kill(humanResources):
	gain(humanResources);

func gain(gainAmt):
	resources += gainAmt;
	update();
	
func _on_spend(spendAmt):
	if spendAmt < resources:
		resources-=spendAmt;
		update();

func _on_death():
	# somehow drop the resources as a collectible object
	# then reset it to 0
	resources = 0;
	update();

func update():
	text = "HR: %s" % resources;

func returnResources():
	return resources;
