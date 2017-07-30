extends RichTextLabel

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player = null
var enemy = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	player = get_node("../Player")
	enemy = get_node("../Enemy")
	set_process(true)
	
func _process(delta):
	#Is someone dead?
	var text = ''
	if not player.alive:
		text = 'YOU LOSE'
	elif enemy.current_power <= 0:
		text = 'YOU WIN!'
	
	set_bbcode(text)
