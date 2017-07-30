extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Attack scene
var player_attack_scene = preload("res://scenes/objects/PlayerAttack.tscn")

#Get nodes
var area = null

var view_angle = 30

var move_angle = 0
var move_speed = 0
var speed = .005
var speed_threshold = 0.1

#Dash related
var dash_distance = .2
var dash_cooldown = 0.5
var min_dash_speed = 0.001
var dash_ready = true
var dash_timer = null

#Player's current power
var current_power = 100
var max_power = 100
var power_drain_rate = 1
var dash_power_drain = 10
var attack_power_drain = 5
var attack_power_gain = 15

#For combo attacks
var can_attack = true
var attack_max_combo = 3
var attack_current_combo = 0
var attack_cooldown = 0.85 #When you aren't in a combo
var attack_combo_cooldown = 0.25 #Wait this long before you combo
var attack_combo_miss_time = 0.65 #Wait this long and leave combo

#Make a bunch of tweens?
var timer_attack = Timer.new()
var timer_attack_combo = Timer.new()
var timer_attack_combo_miss = Timer.new()


#Did you lose?
var alive = true

enum JOYSTICK_AXIS{
	LEFT_STICK_VERTICAL=0,
	LEFT_STICK_HORIZONTAL=1,
	RIGHT_STICK_VERTICAL=2,
	RIGHT_STICK_HORIZONTAL=3,
	LEFT_TRIGGER=6,
	RIGHT_TRIGGER=7
}

enum JOYSTICK_BUTTONS{
	A=0,
	B=1,
	X=2,
	Y=3,
	LEFT_BUMPER=4,
	RIGHT_BUMPER=5,
	LEFT_TRIGGER=6,
	RIGHT_TRIGGER=7,
	LEFT_JOYSTICK=8,
	RIGHT_JOYSTICK=9,
	SELECT=10,
	START=11,
}

enum KEYBOARD_KEYS{
	W=87,
	A=65,
	S=83,
	D=68
}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	area = get_node('./Area')
	
	set_process_input(true)
	set_process(true)
	
	#Create the dash timer
	dash_timer = Timer.new()
	dash_timer.connect("timeout", self, "_on_dash_timer_timeout")
	dash_timer.set_wait_time(dash_cooldown)
	dash_timer.set_one_shot(true)
	add_child(dash_timer)
	
	#Create the attack timers
	timer_attack.connect("timeout", self, "_on_attack_timer_timeout")
	timer_attack.set_wait_time(attack_cooldown)
	timer_attack.set_one_shot(true)
	add_child(timer_attack)
	timer_attack_combo.connect("timeout", self, "_on_attack_combo_timer_timeout")
	timer_attack_combo.set_wait_time(attack_combo_cooldown)
	timer_attack_combo.set_one_shot(true)
	add_child(timer_attack_combo)
	timer_attack_combo_miss.connect("timeout", self, "_on_attack_combo_miss_timer_timeout")
	timer_attack_combo_miss.set_wait_time(attack_combo_miss_time)
	timer_attack_combo_miss.set_one_shot(true)
	add_child(timer_attack_combo_miss)
	
func _on_dash_timer_timeout():
	#Re-enable dash
	print("Can dash")
	dash_ready = true
	
func _on_attack_timer_timeout():
	#We can attack again
	print("Can start a new combo")
	attack_current_combo = 0
	can_attack = true

func _on_attack_combo_timer_timeout():
	#We can attack again
	print("Can combo again")
	can_attack = true

func _on_attack_combo_miss_timer_timeout():
	#We waited too long to combo
	print("Combo over...")
	attack_current_combo = 0
	can_attack = false
	
	#Now we gotta wait
	timer_attack.start()
	

func take_hit():
	#We die or whatever
	alive = false
	print("UR DED PAL")
	
func recover_power(amount=-1):
	#Just add it
	if amount < 0:
		amount = attack_power_gain
	current_power += amount
	
func _make_attack():
	
	#Are we in the middle of a cooldown? Have we attacked too much?
	if not can_attack or attack_current_combo >= attack_max_combo:
		#We can't attack
		return
		
	
	#Make the attack
	attack_current_combo += 1
	var new_player_attack = player_attack_scene.instance()
	
	#Move it to the player
	var new_attack_transform = new_player_attack.get_transform()
	new_attack_transform.origin = get_transform().origin
	
	#Rotate it to match the player
	new_attack_transform = new_attack_transform.rotated(Vector3(0, 1, 0), view_angle)
	new_player_attack.set_transform(new_attack_transform)
	
	#Add it
	get_parent().add_child(new_player_attack)
	
	#Fire off timers
	can_attack = false
	timer_attack_combo.stop()
	timer_attack_combo.start()
	timer_attack_combo_miss.stop()
	timer_attack_combo_miss.start()
	

func _process(delta):
	#Move according to our vector
	var movement = Vector3(move_speed * cos(move_angle), 0, move_speed * sin(move_angle))
	var transform = get_transform()
	transform = transform.translated(movement)
	set_transform(transform)
	
	#Drain power
	current_power -= power_drain_rate*delta
	
	#Don't go over max power
	if current_power > max_power:
		current_power = max_power
	
func _input(event):
	if event.type != InputEvent.MOUSE_MOTION:
		print(event)
	
	# Was this a look-joystick?
	# TODO: Probably poll this per-frame instead of on event? Buttons can be on event...
	if event.type == InputEvent.JOYSTICK_MOTION:
		#Which trigger was it?
		if event.axis in [JOYSTICK_AXIS.RIGHT_STICK_HORIZONTAL, JOYSTICK_AXIS.RIGHT_STICK_VERTICAL]:
			print("Look changed!")
			var x = Input.get_joy_axis(0, JOYSTICK_AXIS.RIGHT_STICK_HORIZONTAL)
			var y = Input.get_joy_axis(0, JOYSTICK_AXIS.RIGHT_STICK_VERTICAL)
			if !(x == 0 or y == 0):
				view_angle = atan2(x, y)
			
		elif event.axis in [JOYSTICK_AXIS.LEFT_STICK_HORIZONTAL, JOYSTICK_AXIS.LEFT_STICK_VERTICAL]:
			print("Moving!")
			
			#Figure out movement angle and direction
			var x = Input.get_joy_axis(0, JOYSTICK_AXIS.LEFT_STICK_HORIZONTAL)
			var y = Input.get_joy_axis(0, JOYSTICK_AXIS.LEFT_STICK_VERTICAL)
			move_angle = atan2(x, y)
			var move_velocity = sqrt(x*x + y*y)
			
			#Are we moving fast enough
			if move_velocity > speed_threshold:
				move_speed = move_velocity * speed
			else:
				move_speed = 0
	
	if event.type == InputEvent.JOYSTICK_BUTTON:
		#Handle presses, not releases
		if not event.pressed:
			return
		
		#Which button was pressed?
		if event.button_index in [JOYSTICK_BUTTONS.A]:
			#We are dashing
			print("Dashing!")
			
			#Can we dodge?
			if(dash_ready and move_speed > min_dash_speed and current_power > 0):
				#Put dash on cooldown
				dash_ready = false
				dash_timer.start()
				
				#And make the movement
				#Move according to our vector
				var movement = Vector3(dash_distance * cos(move_angle), 0, dash_distance * sin(move_angle))
				var transform = get_transform()
				transform = transform.translated(movement)
				set_transform(transform)
				
				#Drain dash energy
				current_power -= dash_power_drain
			
		elif event.button_index in [JOYSTICK_BUTTONS.RIGHT_TRIGGER, JOYSTICK_BUTTONS.RIGHT_BUMPER, JOYSTICK_BUTTONS.X]:
			#We are attacking
			print("Attacking!")
			
			self._make_attack()
	
	# Handle WASD movement for now
	if event.type == InputEvent.KEY:
		#Was it W A S D?
		if event.scancode == KEYBOARD_KEYS.W:
			move_angle = 1.5*PI
			move_speed = speed if event.pressed else 0
		elif event.scancode == KEYBOARD_KEYS.A:
			move_angle = 1*PI
			move_speed = speed if event.pressed else 0
		elif event.scancode == KEYBOARD_KEYS.S:
			move_angle = .5*PI
			move_speed = speed if event.pressed else 0
		elif event.scancode == KEYBOARD_KEYS.D:
			move_angle = 2*PI
			move_speed = speed if event.pressed else 0
	
	#Was it a start? Quit
	if Input.is_joy_button_pressed(0, JOYSTICK_BUTTONS.START):
		get_tree().quit()