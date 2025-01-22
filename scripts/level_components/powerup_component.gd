class_name MainPowerupComponent extends Node2D;


const POWERUP_PACKED = preload('res://scenes/Powerup.tscn');
const BALL_PACKED = preload('res://scenes/Ball.tscn');
var powerup_weights : Dictionary = get_default_weights();

var y_sort_balls_asc : Callable = func(a: Ball, b: Ball):
	if a.position.y < b.position.y:
		return true;
	return false;

var level : MainLevel;
var level_cleared : bool = false;


func _ready():
	EventBus.brick_destroyed.connect(_on_brick_destroyed);
	EventBus.powerup_collected.connect(_on_powerup_collected);
	EventBus.level_cleared.connect(func(): level_cleared = true);
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
	
	if VersionManager.VERSION.containsn('alpha'):
		for żyldyrbyl in [&'ghost_paddle']:
			# those power-ups are not done yet lol
			# probably gonna remove the ghost paddle one
			# altogether lol
			if new_weights.has(żyldyrbyl):
				new_weights.erase(żyldyrbyl);
	
	# "on request of the working people"
	if level.barrier == null or is_instance_valid(level.barrier):
		if new_weights.has(&'barrier'):
			new_weights.erase(&'barrier');
	
	if Ball.target_speed_idx == Ball.BallSpeed.BALL_SPEED_FAST:
		if new_weights.has(&'ball_speed_up'):
			new_weights[&'ball_speed_up'] /= 8;
	if Ball.target_speed_idx == Ball.BallSpeed.BALL_SPEED_SLOW:
		if new_weights.has(&'ball_slow_down'):
			new_weights[&'ball_slow_down'] /= 8;
	
	if (level.paddle as Paddle).width_idx == Paddle.PaddleSize.PADDLE_SIZE_TINY\
		and new_weights.has(&'paddle_shrink'):
			new_weights[&'paddle_shrink'] /= 8;
	if (level.paddle as Paddle).width_idx == Paddle.PaddleSize.PADDLE_SIZE_HUMONGOUS\
		and new_weights.has(&'paddle_enlarge'):
			new_weights[&'paddle_enlarge'] /= 8;
	
	if ball_count == 1:
		new_weights.erase(&'pop_ball');
		new_weights.erase(&'pop_all_balls');
	if ball_count == 2:
		if randf() < 0.5:
			new_weights.erase(&'pop_ball');	
		new_weights.erase(&'pop_all_balls');
	
	if ball_count > ball_limit / 1.5:
		if new_weights.has(&'add_ball'):
			# don't be a smartass
			# hope that the square root function
			# won't make it taper as quickly in the beginning
			new_weights[&'add_ball'] *= sqrt(
				1 - (ball_count / ball_limit)
			);
		if new_weights.has(&'triple_ball'):
			# don't be a smartass 2: electric boogaloo
			new_weights[&'triple_ball'] *= (
				1 - (ball_count / ball_limit)
			)
		if new_weights.has(&'double_balls'):
			# starting at 1.0 at half the limit and tapering to 0 at 3/4 of limit 
			new_weights[&'double_balls'] *= pow(
				1 - (ball_count / ball_limit), 2
			)
	
	if (level.paddle.state == Paddle.PaddleState.Frozen or
		level.paddle.state == Paddle.PaddleState.Ghost):
			new_weights.erase(&'add_ball');
	
	if ball_count >= ball_limit / 3:
		if new_weights.has(&'fire_ball'):
			new_weights[&'fire_ball'] *= 2;
		if new_weights.has(&'acid_ball'):
			new_weights[&'acid_ball'] *= 1.500042069;
	
	if level.paddle.has_gun:
		var guns := [&'gun'];
		for id in guns:
			if new_weights.has(id):
				new_weights[id] /= 3;
	
	if get_tree().get_nodes_in_group(
		&'destructible_bricks').size() <= 5\
		and level.allow_level_finish_powerup:
		new_weights[&'finish_level'] = 2.25; # idk just ballpark lol
	
	# I don't remember what this shit does lol
	var what : StringName = new_weights.keys().pick_random() as StringName;
	var weight_sum : float = (func():
			var sum := 0.0;
			for k in new_weights:
				if k != what:
					sum += new_weights[k];
			return sum;
	).call();
	new_weights[what] *= (1 - 1 / (weight_sum * weight_sum)); # idk why lmao
	
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
	printerr('Houston, we have a big troublem: we are all out of IDs and weights!');
	# just because you would complain about no return value otherwise
	return weights.keys().pick_random();
	# wait it wouldn't???
	# unless there's actually something weird like one of weights being inf lmao


func generate_powerup(pos: Vector2, try_good: bool = false):
	var powerup_node : PowerupNode = POWERUP_PACKED.instantiate();
	powerup_node.level_cleared = self.level_cleared;
	powerup_node.global_position = pos;
	var weights : Dictionary = recalculate_weights(powerup_weights);
	var new_id : StringName;
	# try_good is true, for example, for gem bricks (the ones that always
	# contain a power-up)
	# in this case, it will try to generate a good power-up
	# first, it will make one attempt
	# if the generated power-up isn't a good one, then it will make
	# another attempt with all non-good power-up weight reduced
	if try_good:
		# so, attempt № 1
		new_id = choose_weighted(weights);
		# if it fails (not a good powerup)
		if not Powerup.POWERUP_POOL[&'good'].has(new_id):
			# iterate over weights, reducing the weights of all
			# non good powerups
			for id in weights:
				if not Powerup.POWERUP_POOL[&'good'].has(id):
					weights[id] /= 2.5;
			# and then try again
			new_id = choose_weighted(weights);
	else:
		new_id = choose_weighted(weights);
	var new_type : StringName;
	for type in Powerup.POWERUP_POOL.keys():
		if new_id in Powerup.POWERUP_POOL[type]:
			new_type = type;
			break;
	var new_powerup : Powerup = Powerup.new(
		new_id, new_type);
	powerup_node.powerup = new_powerup;
	add_child(powerup_node);


func _on_brick_destroyed(brick: Brick, by: Node2D):
	if brick is RegularBrick:
		if not level_cleared and (brick.is_shimmering
		# lmao the multiplier would be 1 at durability of 1 and then slowly
		# decrease very very slightly with increasing durability, thus
		# increasing the chance for a powerup to appear
		or randf() * (pow(1.015625, -brick.initial_durability + 1)) <
		level.powerup_chance * (0.95 if by is Explosion else 1.0)):
			generate_powerup(brick.global_position, brick.is_shimmering);


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
			level.add_ball_to_paddle(new_ball, true);
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
			level.activate_sticky_powerup();
		&'barrier':
			level.add_barrier();
		&'fire_ball':
			for b in get_tree().get_nodes_in_group(&'balls'):
				b.state = Ball.BallState.Fire;
		&'acid_ball':
			level.activate_acid_powerup();
			#for b in get_tree().get_nodes_in_group(&'balls'):
				#b.state = Ball.BallState.Acid;
			## probably move to somewhere else
			#Globals.start_or_extend_timer(level.timer_acid, level.ACID_TIME);
		&'gun':
			level.paddle.equip_gun(Projectile.GunType.Regular);
		&'finish_level':
			level.finish();
		
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
			level.activate_freeze_powerup();
	GameProgression.add_score(Powerup.POWERUP_LIST[powerup.id][&'points']);


func _request_powerup(id: StringName, pos: Vector2):
	if not OS.is_debug_build():
		print('Hey, what are you trying to do? Cheat in some power-ups?');
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
