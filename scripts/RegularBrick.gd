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
		if $GPUParticles2D:
			$GPUParticles2D.visible = value;
			$GPUParticles2D.emitting = value;
			if not Engine.is_editor_hint():
				if not value:
					$GPUParticles2D.queue_free();

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
		protected_sides = value;
		if Engine.is_editor_hint():
			queue_redraw();
		else:
			set_armor_sprites();


@onready var initial_durability : int = get_durability(color);
@onready var durability : int = initial_durability;
@onready var brick_sprite : Sprite2D = $Sprite2D;
@onready var crack_sprite : Sprite2D = $CrackSprite;
@onready var is_reinforced : bool:
	get:
		return protected_sides != 0 and protected_sides != null;
	set(value):
		assert(is_reinforced and not is_reinforced, 'Trying to write to le read-only (hopefully) variable is_reinforced.\n(Sorry guys there\'s no other way to write read-only properties, would be hella cool if it was like in C# where you can just tell it to only have a getter and no setter would mean it cannot be set)');



func _ready():
	if is_shimmering:
		if not Engine.is_editor_hint():
			$GPUParticles2D.amount_ratio = 0.0;
			to_tween.append({
				'object': $GPUParticles2D,
				'property': 'amount_ratio',
				'final_val': 1.0,
				'duration': 0.1,
			});
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
	if is_reinforced:
		if Engine.is_editor_hint():
			queue_redraw();
		else:
			set_armor_sprites();
	if $GPUParticles2D:
		$GPUParticles2D.visible = is_shimmering;
		$GPUParticles2D.emitting = is_shimmering;
	if Engine.is_editor_hint():
		$GPUParticles2D.amount = 5;
	elif not Engine.is_editor_hint():
		if not is_shimmering:
			$GPUParticles2D.queue_free();
		else:
			$GPUParticles2D.amount = 10;


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
	if is_reinforced and not Engine.is_editor_hint():
		var sprites_node : Node2D = $ArmorSprites;
		for child in sprites_node.get_children():
			child.queue_free();
		
		var sides := [];
		var corners := [];
		# have to do one by one by hand since trying to be a smartass
		# didn't work because of some bullshit
		# UPD: sorry guys I just mixed up width and height
		# but alas, the old one is gone
		# it was literally bulkier than this one though
		if protected_sides & Direction.Top:
			sides.append(0);
		if protected_sides & Direction.Right:
			sides.append(1);
		if protected_sides & Direction.Bottom:
			sides.append(2);
		if protected_sides & Direction.Left:
			sides.append(3);
		if 0 in sides and 1 in sides:
			corners.append(0);
		if 1 in sides and 2 in sides:
			corners.append(1);
		if 2 in sides and 3 in sides:
			corners.append(2);
		if 3 in sides and 0 in sides:
			corners.append(3);
	
		for side_idx in sides:
			var sprite := Sprite2D.new();
			sprite.region_enabled = true;
			sprite.region_rect.position.x = 0;
			sprite.region_rect.position.y = height * side_idx;
			sprite.region_rect.size.x = width;
			sprite.region_rect.size.y = height;
			sprite.centered = true;
			sprite.texture = ARMOR_TEXTURE;
			sprite.name = 'Side' + 'NESW'[side_idx];
			sprites_node.add_child(sprite);
		for corner_idx in corners:
			var sprite := Sprite2D.new();
			sprite.region_enabled = true;
			sprite.region_rect.position.x = width;
			sprite.region_rect.position.y = height * corner_idx;
			sprite.region_rect.size.x = width;
			sprite.region_rect.size.y = height;
			sprite.centered = true;
			sprite.texture = ARMOR_TEXTURE;
			sprite.name = 'Corner' + [
				'NE', 'SE', 'SW', 'NW'
			][corner_idx]
			sprites_node.add_child(sprite);


func set_crack_sprite(new_durability: int, initial_durability: int):
	if new_durability == initial_durability:
		# not broken yet, just in case I accidentally call it somewhere else
		return;
	if crack_sprite:
		# just why lmao
		var idx : int = [
			[3],		# 2		1
			[1, 3],		# 3		2 1
			[1, 2, 3],	# 4		3 2 1
			[0, 1, 2, 3]# 5		4 3 2 1
		][initial_durability - 2][initial_durability - new_durability - 1];
		crack_sprite.region_rect.position.x = width * idx;


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
			if $GPUParticles2D:
				$GPUParticles2D.amount_ratio -= 1.0 / (initial_durability + 1);
			if crack_sprite:
				crack_sprite.visible = true;
				set_crack_sprite(durability, initial_durability);


func destroy(by: Node2D):
	EventBus.brick_destroyed.emit(self, by);
	if $GPUParticles2D:
		var particles : GPUParticles2D = $GPUParticles2D;
		particles.reparent(get_parent());
		(particles as GPUParticles2D).lifetime /= 2.0;
		particles.emitting = false;
		get_tree().create_timer(1).timeout.connect(func(): particles.queue_free());
	queue_free();


func get_points() -> int:
	return initial_durability * 100;


func _process(delta):
	#if is_shimmering:
		#$Sprite2D.modulate.a = sin(Time.get_ticks_msec() / 42) / 2 + 0.5;
	pass


func _draw():
	if Engine.is_editor_hint():
		if is_reinforced:
			# TODO: have this shit actually draw the armor on top of it
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
