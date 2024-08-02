class_name RegularBrick extends Brick


func _ready():
	super();
	find_child("Sprite2D").queue_free();


func hit(ball: Ball, damage: int):
	durability = maxi(0, durability - damage);
	if durability == 0:
		destroy(ball);
	else:
		EventBus.brick_hit.emit(self, ball);
		queue_redraw();


func destroy(ball: Ball):
	EventBus.brick_destroyed.emit(self, ball);
	queue_free();


func get_points() -> int:
	return initial_durability * 100;


func _draw():
	draw_string(ThemeDB.fallback_font, Vector2(0,0), str(durability));
