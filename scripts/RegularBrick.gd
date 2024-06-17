class_name RegularBrick extends "res://scripts/BrickBase.gd"


func _ready():
	super();
	find_child("Sprite2D").queue_free();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func hit(b: Ball):
	durability -= 1;
	if durability <= 0:
		queue_free();
	queue_redraw();


func _draw():
	draw_string(ThemeDB.fallback_font, Vector2(0,0), str(durability));
