extends Node

const MIN_ACTION_DELAY = 1.0
const ACTION_TIME_WINDOW = 0.8

var last_time_action_pressed = 0

var action_peak_height = 0.0

signal boost_proceed()

func get_elapsed_time_last_action():
	return Time.get_unix_time_from_system() - last_time_action_pressed

func boost():
	boost_proceed.emit()
	last_time_action_pressed = 0.0

func get_boost_value():
	return clamp(action_peak_height,256.0,350.0) * (2.0 + get_boost_multiplicator() * 0.8)
	
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
	if Input.is_action_just_pressed("action") and get_elapsed_time_last_action() > MIN_ACTION_DELAY:
		last_time_action_pressed = Time.get_unix_time_from_system()
		print("Action registered")
