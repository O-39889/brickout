class_name Powerup extends CharacterBody2D


signal collected(node, powerup);


const POWERUP_POOL = {
	'good': [
		'paddle_enlarge',
		'add_ball',
		'triple_ball',
		'double_balls',
		'sticky_paddle',
		'barrier',
		'fire_ball',
		'acid_ball',
	],
	'neutral': [
		'ball_speed_up',
		'ball_slow_down',
	],
	'bad': [
		'paddle_shrink',
		'pop_ball',
		'pop_all_balls',
		'ghost_paddle',
		'paddle_freeze',
	],
};


const POWERUP_GRAVITY = 150;
const INITIAL_SPEED = 200;


var powerup : Dictionary;

# level pool, passed when instantiating a node
var pool: Dictionary;


# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = get_launch_vector();
	powerup = choose_powerup();
	match powerup.type:
		'good':
			pass;
		'neutral':
			$CollisionShape2D.debug_color.h = 60.0 / 360.0;
		'bad':
			$CollisionShape2D.debug_color.h = 0.0;
	$DebugLbl.text = powerup.id;


func _physics_process(delta):
	velocity.y += POWERUP_GRAVITY * delta;
	var collision := move_and_collide(velocity * delta);
	if collision:
		if collision.get_collider() is Paddle:
			collected.emit(self, powerup);
			queue_free();


static func get_default_weight_pool() -> Dictionary:	
	return {};


func get_launch_vector() -> Vector2:
	'''
	so, instead of suffering through analytical methods with that
	apparently implicit function/equation, I would instead use numerical
	methods, something like this:
		1) initial angle range is let's say from 50 to 90 degrees
			* for the rightward direction, we rotate Vector2.RIGHT CCW
			* for the leftward direction, we rotate Vector2.LEFT CW
		2) we compute the horizontal distance the body travels at the min angle
		if it's fine then we set it as the lower bound
		3) otherwise we compute the distance at the midpoint between
		the two angles and see whether it's still outside the screen bounds
			* if it's too small then we do the same thing with the midpoint of
			the range with a smaller angle
			* if it overshoots then we redo that with the range from the larger
			angle (so basically this whole thing is kind of a binary search)
			* and if it's within the tolerance threshold (let's say this is 1 px)
			then we set the lower bound as that angle
		4) we do that with both sides and get the lower angle bounds from left
		and right side, with both ranges touching at 90 degrees exactly upward
		then we pick a random angle out of that range
		and rotate the initial speed vector by that angle
	'''
	return Vector2.UP * INITIAL_SPEED;


func choose_powerup(weights: Dictionary = {}) -> Dictionary:
	var pool := [];
	if weights.is_empty():
		for gp in POWERUP_POOL['good']:
			pool.append({
				'type': 'good',
				'id': gp,
				'weight': 1.0,
			});
		for np in POWERUP_POOL['neutral']:
			pool.append({
				'type': 'neutral',
				'id': np,
				'weight': 1.25,
			});
		for bp in POWERUP_POOL['bad']:
			pool.append({
				'type': 'bad',
				'id': bp,
				'weight': float(POWERUP_POOL['good'].size()) / float(POWERUP_POOL['bad'].size()) * 0.6667,
			});
	var pool_size := 0.0;
	for p in pool:
		pool_size += p['weight'];
	var choice := randf_range(0.0, pool_size);
	var cum_weight := 0.0; # haha
	var picked_powerup : Dictionary;
	for p in pool:
		cum_weight += p['weight'];
		if choice < cum_weight:
			var ret_powerup : Dictionary = p.duplicate();
			ret_powerup.erase('weight');
			return ret_powerup;
	# i don't think we would ever reach that point but Godot doesn't like it still
	# over 10k generated powerups and this shit has never been triggered
	print('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
	return pool[0];


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _draw():
	pass


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free();
