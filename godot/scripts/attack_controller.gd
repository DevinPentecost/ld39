extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Grab some nodes
var player = null
var sprite = null

#Color variables
var start_color = Color(0x838383ff)
var end_color = Color(0xff0000ff)
var color_percent = 0.0

#How long till the attack lands, in seconds
var attack_time = 1
var fade_time = 0.25

#The tween for the attack
var attack_tween = null

#How close to hit?
var attack_radius = 0.05
var range_squared = 0.0025




func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	player = get_node('../Player')
	
	#Set the color of the sprite
	sprite = get_node("./Sprite")
	sprite.set_modulate(Color(start_color))
	
	#Make a tween to launch the attack
	attack_tween = get_node("Tween")
	attack_tween.interpolate_property(self, "color_percent", 0, 1, attack_time, Tween.TRANS_EXPO, Tween.EASE_IN)
	attack_tween.interpolate_callback(self, attack_time, "_attack_complete_callback")
	attack_tween.start()
	
func _attack_complete_callback():
	#print("Attack complete!")
	
	#Did we hit the player?
	var player_origin = player.get_transform().origin
	var origin = get_transform().origin
	var distance_squared = player_origin.distance_squared_to(origin)
	if distance_squared < range_squared:
		#We can heal the player's power
		player.take_hit()
		
	#We also fade away
	start_color = end_color
	end_color = Color(0xFFFFFF00)
	attack_tween.interpolate_property(self, "color_percent", 0, 1, fade_time, Tween.TRANS_EXPO, Tween.EASE_OUT_IN)
	attack_tween.interpolate_callback(self, fade_time, "_fade_complete_callback")
	attack_tween.start()
	
func _fade_complete_callback():
	#We go away
	#print("Fade complete!")
	queue_free()
	
func _process(delta):
	#Set the color
	var color = start_color.linear_interpolate(end_color, color_percent)
	sprite.set_modulate(color)