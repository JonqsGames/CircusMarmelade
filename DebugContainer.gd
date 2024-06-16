extends CenterContainer
@onready var animation_player = $"../BounceBar/AnimationPlayer"


# Called when the node enters the scene tree for the first time.
func _ready():
	ActionPressManager.boost_proceed.connect(self._update_boost_multiplicator_values)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	$VBoxContainer/TimeScaleStopTime.text = "Time scale stop %.2f" % [ActionPressManager.time_scale_stop_time]
	if animation_player.current_animation != "":
		$VBoxContainer/BoostStatus.text = "Status : %s" % [animation_player.current_animation]

func _update_boost_multiplicator_values(_bm):
	$VBoxContainer/BoostValue.text = "Boost Value : %.2f" % [ActionPressManager.get_boost_value()]
	$VBoxContainer/BoostMultiplicator.text = "Boost : %.2f" % [ActionPressManager.get_boost_multiplicator()]
	$VBoxContainer/ActionTimeElapsed.text = "Boost time : %.2f" % [ActionPressManager.get_elapsed_time_last_action()]
