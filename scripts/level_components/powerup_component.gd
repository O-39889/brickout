extends Node2D;


const POWERUP_PACKED = preload('res://scenes/Powerup.tscn');
const BALL_PACKED = preload('res://scenes/Ball.tscn');

var powerup_weights : Dictionary = get_default_weights();

var y_sort_balls_asc : Callable = func(a: Ball, b: Ball):
	if a.position.y < b.position.y:
		return true;
	return false;

var level : Node2D;


func _ready():
	EventBus.brick_destroyed.connect(_on_brick_destroyed);
	EventBus.powerup_collected.connect(_on_powerup_collected);
	match level.pool_type:
		Global.PowerupPoolType.Default:
			pass # already set
		Global.PowerupPoolType.Simple:
			powerup_weights = get_simple_weights();
		Global.PowerupPoolType.Custom:
			pass # idk what to do lol bruh


func get_default_weights() -> Dictionary:
	var pool : Dictionary = Powerup.POWERUP_POOL;
	var result : Dictionary = {};
	var good_weight := 1.0;
	var neutral_weight := 1.3;
	var bad_weight_rel := 2.0 / 3.0;
	var bad_weight := float(pool[&'good'].size()) / float(pool[&'bad'].size()) * bad_weight_rel;
	for good_id in pool[&'good']:
		if good_id != &'finish_level':
			result[good_id] = good_weight;
	for neutral_id in pool[&'neutral']:
		result[neutral_id] = neutral_weight;
	for bad_id in pool[&'bad']:
		result[bad_id] = bad_weight;
	return result;


func get_simple_weights() -> Dictionary:
	var result : Dictionary = {};
	var good_weight_common := 1.0;
	var good_weight_uncommon := 0.6;
	var neutral_weight := 1.25;
	var bad_weight := 0.9;
	for id in [&'paddle_enlarge', &'add_ball', &'sticky_paddle', &'add_points_100']:
		result[id] = good_weight_common;
	for id in [&'triple_ball', &'barrier', &'fire_ball', &'add_points_200']:
		result[id] = good_weight_uncommon;
	for id in [&'ball_speed_up', &'ball_slow_down']:
		result[id] = neutral_weight;
	for id in [&'paddle_shrink', &'pop_ball']:
		result[id] = bad_weight;
	return result;


# recalculate the weight pool based on some specific circumstances
# to make it more convenient so to speak
func recalculate_weights(original_weights: Dictionary) -> Dictionary:
	var new_weights : Dictionary = original_weights.duplicate();
	var ball_count : float = get_tree().get_nodes_in_group(&'balls').size();
	var ball_limit : float = level.BALL_LIMIT;
	
	if Ball.target_speed_idx == Ball.BallSpeed.BALL_SPEED_FAST:
		if new_weights.has(&'ball_speed_up'):
			new_weights[&'ball_speed_up'] /= 4;
	if Ball.target_speed_idx == Ball.BallSpeed.BALL_SPEED_SLOW:
		if new_weights.has(&'ball_slow_down'):
			new_weights[&'ball_slow_down'] /= 4;
	
	if ball_count == 1:
		new_weights.erase(&'pop_ball');
		new_weights.erase(&'pop_all_balls');
	if ball_count == 2:
		if randf() < 0.5:
			new_weights.erase(&'pop_ball');	
		new_weights.erase(&'pop_all_balls');
	
	if ball_count > level.BALL_LIMIT / 2:
		if new_weights.has(&'add_ball'):
			# starting at 1 at half the limit and tapering towards 0 at the limit
			new_weights[&'add_ball'] *= (
				-2 * ball_count / ball_limit + 2
			);
		if new_weights.has(&'triple_ball'):
			# starting at 1 at half the limit and tapering to 0 at limit - 1
			new_weights[&'triple_ball'] *= maxf(0.0,
			ball_count / (1 - ball_limit / 2) + 1 - (ball_limit / (2 - ball_limit)));
		if new_weights.has(&'double_balls'):
			# starting at 1.0 at half the limit and tapering to 0 at 3/4 of limit 
			new_weights[&'double_balls'] *= maxf(0.0, 
			-4 * ball_count / ball_limit + 3);
	
	if (level.paddle.state == Paddle.PaddleState.Frozen or
		level.paddle.state == Paddle.PaddleState.Ghost):
			new_weights.erase(&'add_ball');
	
	if ball_count >= ball_limit / 3:
		if new_weights.has(&'fire_ball'):
			new_weights[&'fire_ball'] *= 2;
		if new_weights.has(&'acid_ball'):
			new_weights[&'acid_ball'] *= 1.8;
	
	if get_tree().get_nodes_in_group(&'destructible_bricks').size() <= 5:
		new_weights[&'finish_level'] = 2.5; # idk just ballpark lol
	
	new_weights[&'add_ball'] *= 1.09;
	
	return new_weights;


func choose_weighted(weights: Dictionary) -> StringName:
	var pool_size : float = weights.values().reduce(
		func(accum: float, weight: float): return accum + weight, 0.0);
	var choice : float = randf() * pool_size;
	var cum_weight : float = 0.0; # haha
	for id in weights:
		cum_weight += weights[id];
		if choice < cum_weight:
			return id;
	print('Houston, we have a big troublem: we are all out of IDs and weights!');
	# just because you would complain about no return value otherwise
	return weights.keys().pick_random();
	# wait it wouldn't???
	# unless there's actually something weird like one of weights being inf lmao


func _on_brick_destroyed(brick: Brick, ball: Ball):
	if brick is RegularBrick:
		if randf() < level.powerup_chance or OS.is_debug_build():
			var powerup_node : PowerupNode = POWERUP_PACKED.instantiate();
			powerup_node.global_position = brick.global_position;
			var new_id : StringName = choose_weighted(recalculate_weights(powerup_weights));
			var new_type : StringName;
			for type in Powerup.POWERUP_POOL.keys():
				if new_id in Powerup.POWERUP_POOL[type]:
					new_type = type;
					break;
			var new_powerup : Powerup = Powerup.new(
				new_id, new_type);
			powerup_node.powerup = new_powerup;
			add_child(powerup_node);


func _on_powerup_collected(powerup: Powerup):
	match powerup.id:
		# GOOD
		&'paddle_enlarge':
			level.paddle.enlarge();
		&'paddle_shrink':
			level.paddle.shrink();
		&'add_ball':
			# we will actually not even add it to the level
			# but parent it to the paddle instead
			var new_ball : Ball = BALL_PACKED.instantiate();
			#new_ball.position.y = -Ball.BALL_RADIUS - Paddle.PADDLE_HEIGHT / 2;
			new_ball.position.x = 0;
			level.add_ball_to_paddle(new_ball);
		&'triple_ball':
			var ball_selection : Array[Ball];
			# have a lower chance of picking a stuck ball
			for b in get_tree().get_nodes_in_group(&'balls'):
				if b.stuck:
					if randf() < 0.3:
						ball_selection.append(b);
				# only check the free bawls above the paddle
				elif b.position.y <= level.paddle.position.y:
					ball_selection.append(b);
			# fallback (just get the first bawl available)
			if ball_selection.is_empty():
				ball_selection = [get_tree().get_first_node_in_group(&'balls')];
			level.clone_balls(ball_selection.pick_random(), 2);
		&'double_balls':
			for b in get_tree().get_nodes_in_group(&'balls'):
				level.clone_balls(b, 1);
		&'sticky_paddle':
			level.paddle.state = Paddle.PaddleState.Sticky;
		&'barrier':
			level.add_barrier();
		&'fire_ball':
			for b in get_tree().get_nodes_in_group(&'balls'):
				b.state = Ball.BallState.Fire;
		&'acid_ball':
			for b in get_tree().get_nodes_in_group(&'balls'):
				b.state = Ball.BallState.Acid;
			# probably move to somewhere else
			Globals.start_or_extend_timer(level.timer_acid, level.ACID_TIME);
		&'finish_level':
			print('Win!');
		# NEUTRAL
		&'ball_speed_up':
			Ball.increase_speed();
		&'ball_slow_down':
			Ball.decrease_speed();
		# BAD
		&'pop_ball':
			var balls_arr : Array[Ball];
			# can't pop the only remaining bawl
			if get_tree().get_nodes_in_group(&'balls').size() == 1:
				return;
			# we form a list of potential targets
			for b in get_tree().get_nodes_in_group(&'balls'):
				if b.stuck:
					# stuck balls only have a small chance to be popped
					# (unless there are only stuck ones)
					if randf() < 0.4:
						balls_arr.append(b);
				else:
					balls_arr.append(b);
			if balls_arr.is_empty():
				balls_arr.append(get_tree().get_first_node_in_group(&'balls'));
			# then we need to pop the ball with the smallest Y coordinate
			# i. e. the topmost one
			balls_arr.sort_custom(y_sort_balls_asc);
			level.murder_ball(balls_arr[0]);
		&'pop_all_balls':
			var balls_arr : Array = get_tree().get_nodes_in_group(&'balls');
			# can't pop the only remaining ball
			if balls_arr.size() == 1:
				return;
			# the ball that won't be popped
			var safe_ball : Ball = null;
			for b in balls_arr:
				# prioritize not popping a stuck ball
				if b.stuck:
					safe_ball = b;
					break;
			# if no stuck balls, just pick the topmost one
			if safe_ball == null:
				balls_arr.sort_custom(y_sort_balls_asc);
				safe_ball = balls_arr[0];
			balls_arr.erase(safe_ball);
			for b in balls_arr:
				level.murder_ball(b);
		&'paddle_freeze':
			level.paddle.state = Paddle.PaddleState.Frozen;
	GameProgression.score += Powerup.POWERUP_LIST[powerup.id][&'points'];


func _request_powerup(id: StringName, pos: Vector2):
	if not OS.is_debug_build():
		return;
	var powerup_node : PowerupNode = POWERUP_PACKED.instantiate() as PowerupNode;
	powerup_node.global_position = pos;
	var powerup_type : StringName;
	for type in Powerup.POWERUP_POOL.keys():
		if id in Powerup.POWERUP_POOL[type]:
			powerup_type = type;
			break;
	powerup_node.powerup = Powerup.new(id, powerup_type);
	add_child(powerup_node);
