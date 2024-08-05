extends Node2D


const BALL_PACKED : PackedScene = preload('res://scenes/Ball.tscn');


@onready var level : Node2D = get_parent();
@onready var sussy : bool = false;


# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.brick_destroyed.connect(_on_brick_destroyed);


func _on_brick_destroyed(brick: Brick, by: Node2D):
	if brick is RegularBrick:
		if randf() < 0.08 and (get_tree()
		.get_nodes_in_group(&'balls').size() < level.BALL_LIMIT
		or randf() < 0.01): # 1 percent chance to ignore the ball limit idk why lmao
			var new_ball : Ball = BALL_PACKED.instantiate();
			new_ball.position = brick.position;
			new_ball.direction = Vector2.UP.rotated(randf() * TAU);
			level.add_child(new_ball);
	await get_tree().physics_frame;
	if get_tree().get_nodes_in_group(&'destructible_bricks').is_empty():
		pass # do something idk lol
