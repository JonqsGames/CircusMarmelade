extends Node

const MIN_ACTION_DELAY = 1.0
const ACTION_TIME_WINDOW = 0.1

var last_time_action_pressed = 0
var landing_time = 0

var action_peak_height = 0.0
var time_scale_stop_time = 0.0

signal boost_proceed()
signal action_pressed()


func set_landing_time():
	landing_time = Time.get_unix_time_from_system()

func get_elapsed_time_last_action():
	return abs(landing_time - last_time_action_pressed)

func boost():
	var b_m = get_boost_multiplicator()
	time_scale_stop_time = 0.1 * b_m
	boost_proceed.emit(b_m)
	last_time_action_pressed = 0.0

func get_boost_value():
	var p_max = 0.0
	for c in get_tree().get_nodes_in_group("Character"):
		if c.status == Character.Status.PILED and c.global_position.y < p_max:
			p_max = c.global_position.y
	return clamp(action_peak_height,256.0 - p_max * 0.1,300.0 - p_max) * (0.55 + get_boost_multiplicator() * 0.35)
	
func get_boost_multiplicator():
	var v = 0.0
	# Evaluate based on latest action the amount of boost the character will get
	# Will return value between 1.0 for perject jump and 0.0 for failed jump
	var dt = get_elapsed_time_last_action() / ACTION_TIME_WINDOW
	if dt >= 0.0 and dt <= 1.0:
		# out of defined window
		v = 1.0 - dt
	return v
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if time_scale_stop_time > 0.0:
		time_scale_stop_time = time_scale_stop_time  - delta / Engine.time_scale
		Engine.time_scale = 0.25 if time_scale_stop_time > 0.0 else 1.0
	if Input.is_action_just_pressed("action") and get_elapsed_time_last_action() > MIN_ACTION_DELAY:
		last_time_action_pressed = Time.get_unix_time_from_system()
		action_pressed.emit()
		print("Action registered")
