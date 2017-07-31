extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player = null
var angle_offset = 0
var previous_angle = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	player = get_parent()
	
func _process(delta):
	
	if player.all_done:
		return
	
	#We need to match the angle the player wants
	var angle_delta = player.view_angle + angle_offset - previous_angle
	previous_angle += angle_delta
	
	var transform = get_transform()
	transform = transform.rotated(Vector3(0, 1, 0), angle_delta)
	set_transform(transform)
	