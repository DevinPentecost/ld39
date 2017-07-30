extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player = null
var area = null
var power_recharge_rate = 5

var range_squared = 0.025

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	player = get_node('../Player')
	area = get_node('./Area')
	area.connect("area_enter", self, "_on_area_enter")

func _on_area_enter(target_area):
	pass

func _process(delta):
	# Is the player close enough
	var player_area = player.area
	if area.overlaps_area(player_area):
		#We can heal the player's power
		player.current_power += power_recharge_rate*delta
	