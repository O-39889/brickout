@tool
class_name ShimmeringBrick extends RegularBrick;


func _process(delta):
	super(delta);
	$Sprite2D.modulate.a = sin(Time.get_ticks_msec() / 42) / 2 + 0.5
