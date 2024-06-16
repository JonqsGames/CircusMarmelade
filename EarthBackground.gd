@tool
extends Node2D

# Colors for the circles
@export var color_earth: Color = Color(0, 1, 0)   # Green
@export var color_sky: Color = Color(0, 0, 1)     # Blue
@export var color_space: Color = Color(0, 0, 0.5) # Dark blue

@export var radius_earth: float = 50.0
@export var sky_ratio: float = 2.0
@export var space_ratio: float = 3.0

func _draw():
	var radius_sky: float = radius_earth * sky_ratio
	var radius_space: float = radius_earth * space_ratio

	var position = Vector2(0, 0)
	# Draw the space circle
	draw_circle(position, radius_space, color_space)
	
	# Draw the sky circle
	draw_circle(position, radius_sky, color_sky)

	# Draw the earth circle
	draw_circle(position, radius_earth, color_earth)
