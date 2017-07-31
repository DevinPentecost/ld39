extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var enemy = null
var player = null
var area = null
var sprite = null
var tween = null

var color = Color(0x00927d)
var faded_color = Color(0xFFFFFF00)
var fade_percent = 1
var fade_time = 1
var attack_done = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	enemy = get_node('../Enemy')
	player = get_node('../Player')	
	area = get_node('./Area')
	sprite = get_node('./Sprite')
	tween = get_node('./Tween')
	
	set_process(true)
	
	#Move the color of the sprite
	tween.interpolate_property(self, "fade_percent", 1, 0, fade_time, Tween.TRANS_EXPO, Tween.EASE_OUT_IN)
	tween.interpolate_callback(self, fade_time, "_fade_complete_callback")
	tween.start()
	
	
func _process(delta):
	#Did it hit the boss?
	if not attack_done and area.overlaps_area(enemy.area):
		#We hit the enemy
		enemy.take_hit()
		player.recover_power()
		
		#Don't check the attack again
		attack_done = true
		
	
	
	#Change the color
	var current_color = color.linear_interpolate(faded_color, fade_percent)
	var sprite_color = sprite.set_modulate(current_color)
	
func _fade_complete_callback():
	#Die
	queue_free()