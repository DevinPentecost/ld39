extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"


var view_angle = 30

var move_angle = 0
var move_speed = 0
var speed = .01
var speed_threshold = 0.1

#Dash related
var dash_distance = .5
var dash_cooldown = 0.25
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
	set_process_input(true)
	set_process(true)
	
	#Create the dash timer
	dash_timer = Timer.new()
	dash_timer.connect("timeout", self, "_on_dash_timer_timeout")
	dash_timer.set_wait_time(dash_cooldown)
	add_child(dash_timer)
	
func _on_dash_timer_timeout():
	#Re-enable dash
	dash_ready = true

func _process(delta):
	#Move according to our vector
	var movement = Vector3(move_speed * cos(move_angle), 0, move_speed * sin(move_angle))
	var transform = get_transform()
	transform = transform.translated(movement)
	set_transform(transform)
	
	#Drain power
	current_power -= power_drain_rate*delta
	
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
			
		elif event.button_index in [JOYSTICK_BUTTONS.RIGHT_TRIGGER, JOYSTICK_BUTTONS.RIGHT_BUMPER]:
			#We are attacking
			print("Attacking!")
	
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