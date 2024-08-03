@tool
class_name RegularBrick extends Brick


@export_enum(
	# 1 durability point
	'(1) Cyan',
	'(1) Blue',
	'(1) Green',
	# 2 durability points
	'(2) Yellow',
	'(2) Orange',
	# 3 durability points
	'(3) Red',
	# 4 and more
	'(4) Purple',
	'(5) Pink'
	) var color;


#const COLORS = [
	#Color.DARK_TURQUOISE,
	#Color.ROYAL_BLUE,
	#Color.LIME_GREEN,
	#Color.GOLD,
	#Color.ORANGE_RED,
	#Color.RED,
	#Color.MEDIUM_PURPLE,
	#Color.HOT_PINK,
#];


func _ready():
	super();
	#find_child("Sprite2D").queue_free();


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


func _process(delta):
	if Engine.is_editor_hint():
		queue_redraw();


func _draw():
	$CollisionShape2D.visible = color == null;
	if color != null:
		$Sprite2D.region_rect = Rect2(
			Vector2(0, height) * color, Vector2(width, height)
		);
		#draw_rect(Rect2(Vector2(-width / 2, -height / 2), $CollisionShape2D.shape.size),
		#COLORS[color]);
		#draw_rect(Rect2(Vector2(-width / 2, -height / 2), $CollisionShape2D.shape.size),
		#Color(0.2, 0.2, 0.2), false, 2);
	if not Engine.is_editor_hint():
		if color == 0 or color == 3: # cyan or yellow
			self_modulate = Color.BLACK;
		draw_string(ThemeDB.fallback_font, Vector2(0,0), str(durability),0,-1,
		28);
