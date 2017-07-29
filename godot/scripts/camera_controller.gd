extends Camera

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player = null
var movement_rate = .9
var offset = Vector3(0, 2, 2.15)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	player = get_node('../Player')

func _process(delta):
	#Get the target positions for the lerp
	var transform = get_transform()
	
	#Get the positions and distances
	var player_origin = player.get_transform().origin
	var player_x = player_origin.x
	var player_z = player_origin.z
	var target_x = player_x
	var target_z = player_z + offset.z
	
	var x_position = lerp(transform.origin.x, target_x, movement_rate*delta)
	var z_position = lerp(transform.origin.z, target_z, movement_rate*delta)
	var y_position = offset.y
	
	#Get the new position
	var position = Vector3(x_position, y_position, z_position)
	var oldOrigin = transform.origin
	transform.origin = position
	set_transform(transform)
	
	
	
	