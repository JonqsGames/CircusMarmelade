extends CenterContainer
@onready var h_slider : HSlider = $HSlider
@onready var animation_player = $AnimationPlayer

func _ready():
	ActionPressManager.boost_proceed.connect(self._on_boost)
	ActionPressManager.action_pressed.connect(self._on_action_pressed)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var active_c : Character = null
	for c in get_tree().get_nodes_in_group("Character"):
		if c.status == Character.Status.AERIAL:
			active_c = c
	# 
	if active_c != null:
		var v = clamp(active_c.global_position.y + 55.0,-200.0,0.0)
		h_slider.value = -v
		if active_c.left_side:
			h_slider.value = -h_slider.value
func _on_action_pressed():
	var t = create_tween()
	t.tween_property(h_slider,"theme_override_constants/grabber_offset",-12.0,0.02) 
	t.tween_property(h_slider,"theme_override_constants/grabber_offset",8.0,0.02)
	t.tween_property(h_slider,"theme_override_constants/grabber_offset",0.0,0.02)
	
func _on_boost(bm):
	if bm > 0.85:
		animation_player.play("perfect")
	elif bm <= 0.1:
		animation_player.play("fail")
	else:
		animation_player.play("success")
