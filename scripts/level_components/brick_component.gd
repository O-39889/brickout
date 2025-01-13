class_name MainBrickComponent extends Node2D;

var level : MainLevel;


func _ready():
	EventBus.brick_hit.connect(_on_brick_hit);
	EventBus.brick_destroyed.connect(_on_brick_destroyed);
	if get_tree().get_node_count_in_group(&'switch_bricks') != 0:
		var briccs : Array = get_tree()\
		.get_nodes_in_group(&'switch_bricks');
		# what happens if the creator themselves places
		# all red/blue briccs? well then the creator is a jackass
		# so we'll try to just not think of this scenario and have all of them
		# be random by default
		while true:
			briccs.shuffle();
			var current_bricc := true;
			for b : SwitchBrick in briccs:
				b.state = SwitchBrick.SwitchState.Red\
				if current_bricc else SwitchBrick.SwitchState.Blue;
				current_bricc = !current_bricc;
				#if b.state == SwitchBrick.SwitchState.Random:
					#b.state = SwitchBrick.SwitchState.Red\
					#if current_bricc else SwitchBrick.SwitchState.Blue;
			if briccs.all(func(br): return br.state\
					== SwitchBrick.SwitchState.Red)\
			or briccs.all(func(br): return br.state\
					== SwitchBrick.SwitchState.Blue):
				continue;
			else:
				break;
			# gotta make sure that the briccs aren't all red or all blue


func _on_brick_hit(brick: Brick, by: Node2D) -> void:
	# yet another short-circuit evaluation yay
	if brick is SwitchBrick and !brick.lock:
		# already after flipping
		# so we gotta check states
		var briccs : Array = get_tree()\
		.get_nodes_in_group(&'switch_bricks');
		if briccs.all(func(br): return br.state\
				== SwitchBrick.SwitchState.Red)\
		or briccs.all(func(br): return br.state\
				== SwitchBrick.SwitchState.Blue):
			var t := get_tree().create_timer(0.5, false, true);
			for b : SwitchBrick in briccs:
				b.lock = true;
				# CAUTION: what if `by` is destroyed after that time period?
				t.timeout.connect(b.destroy.bind(by));

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
		GameProgression.add_score(brick.get_points());
	
	if brick.is_in_group(&'destructible_bricks'):
		# I guess because the brick queue_frees itself so you gotta wait for it
		# to actually disappear
		await get_tree().physics_frame;
		if get_tree().get_nodes_in_group(&'destructible_bricks').is_empty():
			level.finish();
