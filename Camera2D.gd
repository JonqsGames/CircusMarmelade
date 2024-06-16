extends Camera2D

var _duration = 0.0
var _period_in_ms = 0.0
var _amplitude = 0.0
var _timer = 0.0
var _previous_x = 0.0
var _previous_y = 0.0
var _last_offset = Vector2(0, 0)
var _last_shook_timer = 0

# Variables to control zoom level
var default_zoom = Vector2(1, 1)
var zoom_speed = 2  # Control how fast the zoom changes

# Variables to control zoom speed
var min_speed = 0
var max_speed = 1000

# Initial position of the camera in y axis
var initial_position_y = 0

func _ready():
	initial_position_y = self.position.y

# Shake with decreasing intensity while there's time remaining.
func _process(delta):
	adjustZoom(delta)
	# Only shake when there's shake time remaining.
	if _timer == 0:
		return
	# Only shake on certain frames.
	_last_shook_timer = _last_shook_timer + delta
	# Be mathematically correct in the face of lag; usually only happens once.
	while _last_shook_timer >= _period_in_ms:
		_last_shook_timer = _last_shook_timer - _period_in_ms
		# Lerp between [amplitude] and 0.0 intensity based on remaining shake time.
		var intensity = _amplitude * (1 - ((_duration - _timer) / _duration))
		# Noise calculation logic from http://jonny.morrill.me/blog/view/14
		var new_x = randf_range(-1.0, 1.0)
		var x_component = intensity * (_previous_x + (delta * (new_x - _previous_x)))
		var new_y = randf_range(-1.0, 1.0)
		var y_component = intensity * (_previous_y + (delta * (new_y - _previous_y)))
		_previous_x = new_x
		_previous_y = new_y
		# Track how much we've moved the offset, as opposed to other effects.
		var new_offset = Vector2(x_component, y_component)
		set_offset(get_offset() - _last_offset + new_offset)
		_last_offset = new_offset
	# Reset the offset when we're done shaking.
	_timer = _timer - delta
	if _timer <= 0:
		_timer = 0
		set_offset(get_offset() - _last_offset)

func adjustZoom(delta):
	# Control zoom camera
	var camera_size = get_viewport_rect().size * zoom
	var camera_rect = Rect2(get_screen_center_position() - camera_size / 2, camera_size)
	var camera_top_position = abs(camera_rect.position.y)
	
	var highest_player = find_highest_player()
	
	var player_speed = highest_player.get_aerial_speed()
	var normalized_speed = clamp((player_speed - min_speed) / (max_speed - min_speed), 0, 1)
	
	var camera_top_offset = 100
	if abs(highest_player.global_position.y) > camera_top_position - camera_top_offset:
		# Zoom to 0.5 when player reach the top of the camera
		# Need to fix it to match the zoom level based on player altitude
		zoom = zoom.lerp(Vector2(0.5, 0.5), normalized_speed)
		move_camera_y_smoothly(initial_position_y / 0.5, 5, delta)
	else:
		# Back to normal zoom
		zoom = zoom.lerp(Vector2(1, 1), normalized_speed)
		move_camera_y_smoothly(initial_position_y, 5, delta)

# Kick off a new screenshake effect.
func shake(duration, frequency, amplitude):
	if frequency == 0: return
	# Initialize variables.
	_duration = duration
	_timer = duration
	_period_in_ms = 1.0 / frequency
	_amplitude = amplitude
	_previous_x = randf_range(-1.0, 1.0)
	_previous_y = randf_range(-1.0, 1.0)
	# Reset previous offset, if any.
	set_offset(get_offset() - _last_offset)
	_last_offset = Vector2(0, 0)
	
# Method to move the camera's y position smoothly to a target y position
func move_camera_y_smoothly(target_y_position: float, camera_speed: float, delta):
	self.position.y = lerp(self.position.y, target_y_position, camera_speed * delta)
	
func find_highest_player():
	var highest_y = -INF
	var current_player = null
	for character in get_tree().get_nodes_in_group("Character"):
		if abs(character.global_position.y) > highest_y:
			highest_y = abs(character.global_position.y)
			current_player = character
	return current_player
