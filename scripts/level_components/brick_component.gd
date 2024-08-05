extends Node2D;

var level : Node2D;


func _ready():
	EventBus.brick_destroyed.connect(_on_brick_destroyed);


func _on_brick_destroyed(brick: Brick, by: Node2D):
	# I intended for reinforced bricks to still give full points when broken with acid balls
	if (by is Ball and by.state == Ball.BallState.Acid
		and brick is RegularBrick
		and not brick.is_reinforced): # le short circuit evaluation, baby
		# reduce score from regular bricks destroyed by acid bawls
		GameProgression.score += maxi(snappedi(brick.get_points() * 0.666667, 100), 100);
	else:
		GameProgression.score += brick.get_points();
	if brick.is_in_group(&'destructible_bricks'):
		await get_tree().physics_frame;
		if get_tree().get_nodes_in_group(&'destructible_bricks').is_empty():
			print('Win!');
			await get_tree().create_timer(1.0).timeout;
			get_tree().reload_current_scene();
