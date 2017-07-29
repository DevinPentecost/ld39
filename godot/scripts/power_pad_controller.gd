extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player = null
var power_recharge_rate = 5

var range_squared = 0.025

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	player = get_node('../Player')

func _process(delta):
	# Is the player close enough
	var player_origin = player.get_transform().origin
	var origin = get_transform().origin
	var distance_squared = player_origin.distance_squared_to(origin)
	if distance_squared < range_squared:
		#We can heal the player's power
		player.current_power += power_recharge_rate*delta
	