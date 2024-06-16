extends CenterContainer
@onready var h_slider : HSlider = $HSlider
@onready var animation_player = $AnimationPlayer

func _ready():
	ActionPressManager.boost_proceed.connect(self._on_boost)
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

func _on_boost(bm):
	if bm > 0.85:
		animation_player.play("perfect")
	elif bm <= 0.1:
		animation_player.play("fail")
	else:
		animation_player.play("success")
