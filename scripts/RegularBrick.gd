class_name RegularBrick extends Brick


func _ready():
	super();
	find_child("Sprite2D").queue_free();


func hit(b: Ball, damage: int):
	durability = maxi(0, durability - damage);
	if durability == 0:
		destroy(b);
	else:
		EventBus.brick_hit.emit(self, b);
		queue_redraw();


func destroy(b: Ball):
	EventBus.brick_destroyed.emit(self, b);
	queue_free();


func _draw():
	draw_string(ThemeDB.fallback_font, Vector2(0,0), str(durability));
