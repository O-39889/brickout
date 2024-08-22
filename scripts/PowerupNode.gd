class_name PowerupNode extends CharacterBody2D


const POWERUP_GRAVITY = 120;
const INITIAL_SPEED = 200;
const MIN_ANGLE = deg_to_rad(55.55555);


var powerup : Powerup;
var level_cleared : bool = false;

@onready var width : float = $CollisionShape2D.shape.radius * 2;


# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.level_cleared.connect(func(): level_cleared = true);
	velocity = get_launch_vector() * INITIAL_SPEED;
	assert(powerup != null, 'Powerup not set for ' + str(self));
	match powerup.type:
		&'good':
			pass;
		&'neutral':
			$CollisionShape2D.debug_color.h = 60.0 / 360.0;
		&'bad':
			$CollisionShape2D.debug_color.h = 0.0;
	$DebugLbl.text = powerup.id;


func _physics_process(delta):
	velocity.y += POWERUP_GRAVITY * delta * (0.50001 if level_cleared else 1);
	var collision := move_and_collide(velocity * delta);
	if collision:
		var collider := collision.get_collider();
		if (collider is Paddle
		# paddle
		or collider.get_collision_layer_value(2)
		# paddle hitbox for powerups
		or collider.get_collision_layer_value(7)):
			if get_parent().level.state == Level.LevelCompletionState.Clear:
				velocity = velocity.bounce(collision.get_normal());
			else:
				EventBus.powerup_collected.emit(powerup);
				queue_free();
	if position.y > get_viewport_rect().size.y + width * 3:
		queue_free();

# ENTERING PAIN TERRITORY

func get_launch_vector() -> Vector2:
	# we shift the whole system horizontally so that x_0, or initial x position
	# of le powerup, is at x = 0
	var right_x : float = get_viewport_rect().size.x - position.x - width;
	var left_x : float = position.x - width;
	
	var left_angle : float = binary_search_min_angle(left_x);
	left_angle = left_angle - PI / 2;
	var right_angle : float = binary_search_min_angle(right_x);
	right_angle = PI / 2 - right_angle;
	
	return Vector2.UP.rotated(randf_range(left_angle, right_angle));


func binary_search_min_angle(max_x: float):
	var min: float = MIN_ANGLE;
	var max: float = PI / 2;
	var mid: float;
	var max_iters: int = ceili(log(rad_to_deg(max - min)) / log(2));
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

# PAIN TERRITORY PASSED
