class_name ReinforcedBrick extends RegularBrick;

@export_flags('Top', 'Right', 'Bottom', 'Left') var protected_sides;

enum Direction {
	Top = 1, # haha top
	Right = 2,
	Bottom = 4, # haha bottom
	Left = 8
};


func _ready():
	super();
	queue_redraw();
	if protected_sides == (Direction.Top | Direction.Right | Direction.Bottom | Direction.Left):
		printerr('Warning: reinforced brick ' + str(self) + ' has all sides protected and won\'t be able to be broken with regular balls or projectiles.');
	if protected_sides == 0:
		printerr('Warning: reinforced brick ' + str(self) + ' has no protected sides. Use RegularBrick instead.');


# can't handle collisions using regular hit() method because there's just
# not enough info so will have to do this instead ig
func is_valid_hit(normal: Vector2) -> bool:
	var closest_direction : Direction;
	# i don't care if it looks bad
	# my brain is just not braining after 5 hours of sleep because of this
	# freaking dumbass mosquito	
	
	# no armor on the left side and the normal angle is close to here
	var left_angle_diff : float = _angle_diff(normal, Direction.Left);
	var top_angle_diff : float = _angle_diff(normal, Direction.Top);
	var right_angle_diff : float = _angle_diff(normal, Direction.Right);
	var bottom_angle_diff : float = _angle_diff(normal, Direction.Bottom);
	
	# basically first we determine if the collision normal angle deviates
	# no more than 45 degrees from the given direction, which means a ball
	# collided with that edge or at least corner of the brick
	if absf(left_angle_diff) <= 45\
	and protected_sides & Direction.Left == 0:
		# adjust the allowed angle range: if we have armor on an adjacent side
		# then reduce the max angle there a bit so that it's as if there's
		# also a protected corner there
		var range_min : float = -40 if protected_sides & Direction.Top else -45;
		var range_max : float = 40 if protected_sides & Direction.Bottom else 45;
		# and then see if the normal still fits in that range, if yes, then
		# count that as a valid hit
		if range_min <= left_angle_diff and left_angle_diff <= range_max:
			return true;
	# repeat with other directions
	elif absf(top_angle_diff) <= 45\
	and protected_sides & Direction.Top == 0:
		var range_min : float = -40 if protected_sides & Direction.Right else -45;
		var range_max : float = 40 if protected_sides & Direction.Left else 45;
		if range_min <= top_angle_diff and top_angle_diff <= range_max:
			return true;
	elif absf(right_angle_diff) <= 45\
	and protected_sides & Direction.Right == 0:
		var range_min : float = -40 if protected_sides & Direction.Bottom else -45;
		var range_max : float = 40 if protected_sides & Direction.Top else 45;
		if range_min <= right_angle_diff and right_angle_diff <= range_max:
			return true;
	elif absf(bottom_angle_diff) <= 45\
	and protected_sides & Direction.Bottom == 0:
		var range_min : float = -40 if protected_sides & Direction.Left else -45;
		var range_max : float = 40 if protected_sides & Direction.Right else 45;
		if range_min <= bottom_angle_diff and bottom_angle_diff <= range_max:
			return true;
	return false;


func _angle_diff(normal: Vector2, dir: Direction) -> float:
	var vec : Vector2;
	match dir:
		Direction.Top:
			vec = Vector2.UP;
		Direction.Right:
			vec = Vector2.RIGHT;
		Direction.Bottom:
			vec = Vector2.DOWN;
		Direction.Left:
			vec = Vector2.LEFT;
	return rad_to_deg(angle_difference(normal.angle(), vec.angle()));


func _draw():
	super();
	if protected_sides & Direction.Top:
		draw_rect(Rect2(
			-width / 2, -height / 2, width, 10
		), Color.BLACK, true);
	if protected_sides & Direction.Right:
		draw_rect(Rect2(
			width / 2 - 10, -height / 2, 10, height
		), Color.BLACK, true);
	if protected_sides & Direction.Bottom:
		draw_rect(Rect2(
			-width / 2, height / 2 - 10, width, 10
		), Color.BLACK, true);
	if protected_sides & Direction.Left:
		draw_rect(Rect2(
			-width / 2, -height / 2, 10, height
		), Color.BLACK, true);
