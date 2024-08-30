class_name TitleScreenBrickComponent extends Node2D;


# WHY IS IT DOING THIS
# oh wait it's to spawn balls from already created stuff
# then nvm haha
const BALL_PACKED : PackedScene = preload('res://scenes/Ball.tscn');


var level : Level;


# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.brick_destroyed.connect(_on_brick_destroyed);


func _on_brick_destroyed(brick: Brick, _by: Node2D):
	if brick is RegularBrick:
		if randf() < 0.075\
		and get_tree().get_nodes_in_group(&'balls').size() < level.BALL_LIMIT:
			var new_ball : Ball = BALL_PACKED.instantiate();
			new_ball.position = brick.position;
			level.add_ball(new_ball);
			new_ball.launch(Vector2.UP.rotated(randf() * TAU).rotated(randf() * TAU));
	await get_tree().physics_frame;
	if get_tree().get_nodes_in_group(&'destructible_bricks').is_empty():
		level.finish();
