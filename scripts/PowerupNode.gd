class_name PowerupNode extends CharacterBody2D


signal collected(powerup);


const POWERUP_GRAVITY = 150;
const INITIAL_SPEED = 200;
const MIN_ANGLE = deg_to_rad(50);


var powerup : Powerup;

# level pool, passed when instantiating a node
var pool : Array[Powerup];

@onready var width : float = $CollisionShape2D.shape.radius * 2;


# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = get_launch_vector() * INITIAL_SPEED;
	if pool.is_empty():
		pool = Powerup.get_default_weight_pool();
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
		var collider := collision.get_collider();
		if (collider is Paddle
		or collider.get_collision_layer_value(2)
		or collider.get_collision_layer_value(7)):
			collected.emit(powerup);
			queue_free();


func get_launch_vector() -> Vector2:
	# we shift the whole system horizontally so that x_0, or initial x position
	# of le powerup, is at x = 0
	var right_x : float = get_viewport_rect().size.x - position.x - width;
	var left_x : float = position.x - width;
	var left_angle : float = binary_search_min_angle(left_x);
	left_angle = left_angle - PI / 2;
	var right_angle : float = binary_search_min_angle(right_x);
	right_angle = PI / 2 - right_angle;
	var left_line : Line2D = Line2D.new();
	left_line.clear_points();
	left_line.add_point(global_position);
	left_line.add_point(global_position + Vector2.UP.rotated(left_angle) * 100);
	var right_line : Line2D = Line2D.new();
	right_line.clear_points();
	right_line.add_point(global_position);
	right_line.add_point(global_position + Vector2.UP.rotated(right_angle) * 100);
	left_line.default_color = Color.LIGHT_SEA_GREEN;
	right_line.default_color = Color.WEB_MAROON;
	get_parent().add_child(left_line);
	get_parent().add_child(right_line);
	return Vector2.UP.rotated(randf_range(left_angle, right_angle));


func binary_search_min_angle(max_x: float):
	var min: float = MIN_ANGLE;
	var max: float = PI / 2;
	var mid: float;
	var max_iters: int = ceili(log(rad_to_deg(max - min)) / log(2));
	print('Max iterations: ' + str(max_iters));
	if compute_x(min, compute_t(min)) <= max_x:
		return min;
	for i in range(max_iters):
		mid = (min + max) / 2;
		if compute_x(mid, compute_t(mid)) >= max_x:
			min = mid;
		else:
			max = mid;
	return mid;


# just to clarify, in those two functions we pretend that we use, like,
# a normal coordinate system instead of the one in Godot
func compute_t(phi: float) -> float:
		var V := INITIAL_SPEED;
		var g := -POWERUP_GRAVITY;
		var delta := get_viewport_rect().size.y - position.y - Globals.PADDLE_OFFSET;
		return (-V * sin(phi) - sqrt(
			pow(V * sin(phi), 2)- 2 * g * delta
		)) / g;
	
func compute_x(phi: float, t: float) -> float:
	return INITIAL_SPEED * cos(phi) * t;


# TODO
'''
MAKE THIS SHIT CHECK WHETHER THE POOL VARIABLE IS NOT SET OR EMPTY
THEN IF THAT IS SO FILL IT WITH THE DEFAULT WEIGHT POOL
ACTUALLY MIGHT EVEN DO THAT IN _ready() INSTEAD
IN HERE JUST IMPLEMENT A WEIGHTED RANDOM CHOICE ALGORITHM
'''
func choose_powerup() -> Powerup:
	return choice_weighted(pool);


func choice_weighted(arr: Array[Powerup]):
	# hope this works
	var pool_size : float = arr.reduce(func(accum: float, p: Powerup): return accum + p.weight, 0.0);
	var choice : float = randf_range(0.0, pool_size);
	var cum_weight : float = 0.0; # haha
	for p in arr:
		cum_weight += p.weight;
		if choice < cum_weight:
			return p;
	# i don't think that would happen
	return null;


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free();
