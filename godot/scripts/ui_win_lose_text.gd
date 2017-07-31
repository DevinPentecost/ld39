extends RichTextLabel

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player = null
var enemy = null
var cam = null

var win_image = null
var lose_image = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	player = get_node("../Player")
	enemy = get_node("../Enemy")
	cam = get_node("../Camera")
	
	win_image = get_node("../Win Image")
	lose_image = get_node("../Lose Image")
	win_image.hide()
	lose_image.hide()
	
	set_process(true)
	
func _process(delta):
	#Is someone dead?
	var text = ''
	if not player.alive:
		lose_image.show()
		if cam.sizey > 0.5:
			cam.sizey -= 0.002
	elif enemy.current_power <= 0:
		win_image.show()
		player.attack_current_combo = 0
		if cam.sizey > 0.5:
			cam.sizey -= 0.002

