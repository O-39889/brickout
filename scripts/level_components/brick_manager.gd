extends Node2D;

@onready var level : Node2D = get_parent();


func _ready():
	EventBus.brick_destroyed.connect(_on_brick_destroyed);


func _on_brick_destroyed(brick: Brick, ball: Ball):
	if brick.is_in_group(&'destructible_bricks'):
		GameProgression.score += brick.initial_durability * 100;
		await get_tree().physics_frame;
		if get_tree().get_nodes_in_group(&'destructible_bricks').is_empty():
			print('Win!');
			await get_tree().create_timer(1.0).timeout;
			get_tree().reload_current_scene();
