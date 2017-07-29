extends TextureProgress

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	player = get_node('../Player')

func _process(delta):
	# Update the bar
	set_val(player.current_power)