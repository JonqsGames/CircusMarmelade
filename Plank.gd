extends StaticBody2D
class_name Plank

signal release()

const TILT_ANGLE = PI * 0.1

func tilt(left_side):
	var t = create_tween()
	t.tween_property(self,"rotation",-TILT_ANGLE if left_side else TILT_ANGLE,0.12)
	t.tween_callback(self._on_tilt_end)

func _on_tilt_end():
	print("Tilt")
	release.emit()
