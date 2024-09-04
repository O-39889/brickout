@tool
class_name RegularBrick extends Brick;


enum Direction {
	Top = 1, # haha top
	Right = 2,
	Bottom = 4, # haha bottom
	Left = 8
};


const ARMOR_TEXTURE := preload('res://assets/brick-edges-placeholder.png');


## Whether the brick should always provide a power-up when hit
## (tries to give out a good power-up).
@export var is_shimmering : bool = false:
	get:
		return is_shimmering;
	set(value):
		if value == false and Engine.is_editor_hint():
			$Sprite2D.modulate.a = 1.0;
		is_shimmering = value;
		if particles:
			particles.visible = value;
			particles.emitting = value;
			if not Engine.is_editor_hint():
				if not value:
					particles.queue_free();
					particles = null;

## Color of the brick, also determines the overall durability of the brick.
@export_enum(
	# 1 durability point
	'(1) Cyan',		# 0
	'(1) Blue',		# 1
	'(1) Green',	# 2
	# 2 durability points
	'(2) Yellow',	# 3
	'(2) Orange',	# 4
	# 3 durability points
	'(3) Red',		# 5
	# 4
	'(4) Purple',	# 6
	# 5
	'(5) Pink'		# 7
	) var color = 0:
		get:
			return color;
		set(value):
			color = value;
			update_sprites();

## Sides of the brick protected by armor; the brick can only be hit
## with a regular ball from the unprotected sides.
@export_flags('Top', 'Right', 'Bottom', 'Left') var protected_sides = 0:
	get:
		return protected_sides;
	set(value):
		#print('Setter activated for ', name);
		protected_sides = value;
		if armor_sprite:
			armor_sprite.visible = protected_sides != 0;
		if Engine.is_editor_hint():
			if protected_sides == (Direction.Top | Direction.Right | Direction.Bottom | Direction.Left):
				printerr('Warning: reinforced brick ' + str(self) + ' ' + str(self.global_position) + ' has all sides protected and won\'t be able to be broken with regular balls or projectiles.');
			if armor_sprite:
				#print(name, ' queueieuign ', armor_sprite, ' to redraw NOW!');
				armor_sprite.queue_redraw();
		elif not Engine.is_editor_hint():
			if armor_sprite:
				if protected_sides == 0:
					armor_sprite.queue_free();
					armor_sprite = null;
				else:
					armor_sprite.queue_redraw();


@onready var initial_durability : int = get_durability(color);
@onready var durability : int = initial_durability;
@onready var brick_sprite : Sprite2D = $Sprite2D;
@onready var crack_sprite : Sprite2D = $CrackSprite;
@onready var armor_sprite : Node2D = $ArmorSprites;
@onready var particles : GPUParticles2D = $GPUParticles2D;
@onready var is_reinforced : bool:
	get:
		return protected_sides != 0 and protected_sides != null;


func _ready():
	if not Engine.is_editor_hint():
		pass;
	super();
	if initial_durability == 1 and not Engine.is_editor_hint():
		$CrackSprite.queue_free();
		crack_sprite = null;
	if protected_sides == (Direction.Top | Direction.Right | Direction.Bottom | Direction.Left):
		printerr('Warning: reinforced brick ' + str(self) + ' ' + str(self.global_position) + ' has all sides protected and won\'t be able to be broken with regular balls or projectiles.');
		if not Engine.is_editor_hint():
			# to prevent softlocks or idk lol
			self.remove_from_group(&'destructible_bricks');
	update_sprites();
	if particles:
		particles.visible = is_shimmering;
		particles.emitting = is_shimmering;
	if armor_sprite:
		# even when it's hidden, like, in the editor when it's not a reinforced brick
		armor_sprite.brick = self;
	if Engine.is_editor_hint():
		particles.amount = 5;
		if is_reinforced:
			armor_sprite.queue_redraw();
	elif not Engine.is_editor_hint():
		if not is_shimmering:
			particles.queue_free();
			particles = null;
		else:
			particles.amount = 10;
			
		if is_reinforced:
			armor_sprite.queue_redraw();
		else:
			armor_sprite.queue_free();
			armor_sprite = null;


func get_durability(color_idx : int) -> int:
	if color_idx < 3 and color_idx >= 0:
		return 1;
	if color_idx < 5:
		return 2;
	if color_idx < 6:
		return 3;
	if color_idx < 7:
		return 4;
	if color_idx < 8:
		return 5;
	return 1; # fallback lmao


func update_sprites():
	$Sprite2D.region_rect = Rect2(
				Vector2(0, height) * color,
				Vector2(width, height)
			);
	if not Engine.is_editor_hint():
		set_crack_sprite(durability, initial_durability);


func set_armor_sprites():
	pass


func set_crack_sprite(new_durability: int, init_durability: int):
	if new_durability == init_durability:
		# not broken yet, just in case I accidentally call it somewhere else
		return;
	if crack_sprite:
		crack_sprite.region_rect.position.x = (
			width * (new_durability - 1)
		);

# can't handle collisions using regular hit() method because there's just
# not enough info so will have to do this instead ig
func is_valid_hit(normal: Vector2) -> bool:
	if protected_sides == 0:
		return true;
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


func hit(by: Node2D, damage: int):
	durability = maxi(0, durability - damage);
	if durability == 0:
		destroy(by);
	else:
		EventBus.brick_hit.emit(self, by);
		if damage != 0:
			if particles:
				particles.amount_ratio -= 1.0 / (initial_durability + 1);
			if crack_sprite:
				crack_sprite.visible = true;
				set_crack_sprite(durability, initial_durability);


func destroy(by: Node2D):
	EventBus.brick_destroyed.emit(self, by);
	if particles:
		particles.reparent(get_parent());
		(particles as GPUParticles2D).lifetime /= 2.0;
		particles.emitting = false;
		get_tree().create_timer(1).timeout.connect(func():
			particles.queue_free()
			particles = null);
	queue_free();


func get_points() -> int:
	return initial_durability * 100;


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
