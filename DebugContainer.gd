extends CenterContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	ActionPressManager.boost_proceed.connect(self._update_boost_multiplicator_values)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _update_boost_multiplicator_values():
	$VBoxContainer/BoostValue.text = "Boost Value : %.2f" % [ActionPressManager.get_boost_value()]
	$VBoxContainer/BoostMultiplicator.text = "Boost : %.2f" % [ActionPressManager.get_boost_multiplicator()]
	$VBoxContainer/ActionTimeElapsed.text = "Boost time : %.2f" % [ActionPressManager.get_elapsed_time_last_action()]
