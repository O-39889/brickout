class_name MainBrickComponent extends Node2D;

var level : MainLevel;


func _ready():
	EventBus.brick_destroyed.connect(_on_brick_destroyed);


func _on_brick_destroyed(brick: Brick, by: Node2D):
	# so if it's an acid ball hitting a non-reinforced brick
	# then it gives you less points than usual
	# so that's kind of a balance thingy
	if (by is Ball and by.state == Ball.BallState.Acid
		and brick is RegularBrick
		and not brick.is_reinforced): # le short circuit evaluation, baby
		# snippedi snappedi :DDDDDDDDDDDD
		GameProgression.add_score(maxi(snappedi(brick.get_points() * 0.666667, 100), 100));
	else:
		# testing purposes: don't get points from bricks yet
		#GameProgression.add_score(brick.get_points());
		pass
	
	if brick.is_in_group(&'destructible_bricks'):
		# I guess because the brick queue_frees itself so you gotta wait for it
		# to actually disappear
		await get_tree().physics_frame;
		if get_tree().get_nodes_in_group(&'destructible_bricks').is_empty():
			level.finish();
