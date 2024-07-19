extends Node2D


const BALL_PACKED : PackedScene = preload('res://scenes/Ball.tscn');


@onready var level : Node2D = get_parent();


# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.brick_hit.connect(_on_brick_hit);


func _on_brick_hit(brick: Brick, ball: Ball):
	if brick is RegularBrick:
		if brick.durability == 1:
			if randf() < 0.08 and get_tree().get_nodes_in_group(&'balls').size() < level.BALL_LIMIT:
				var new_ball : Ball = BALL_PACKED.instantiate();
				new_ball.position = brick.position;
				new_ball.direction = Vector2.UP.rotated(randf() * TAU);
				level.add_child(new_ball);
