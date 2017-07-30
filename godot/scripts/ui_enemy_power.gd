extends TextureProgress

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var enemy = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	enemy = get_node('../Enemy')

func _process(delta):
	# Update the bar
	set_val(enemy.current_power)