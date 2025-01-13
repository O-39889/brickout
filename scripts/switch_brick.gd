class_name SwitchBrick extends Brick;

enum SwitchState {
	Red, Blue, Random
};


const EXPLOSION_PACKED := preload("res://scenes/Explosion.tscn");


@export var state : SwitchState = SwitchState.Random;

var lock := false;
# Maybe I should do all of that inside of a brick manager component? 


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#super();


#func check_states() -> void:
	#pass


# just bc all the enum stuff is a mouthful
func flip() -> void:
	state = SwitchState.Red if state == SwitchState.Blue\
			else SwitchState.Blue;


func destroy(by: Node2D) -> void:
	super(by);
	explode_stuff();
	queue_free();


# idk lol for now I'll just copy a function from the ball
func explode_stuff():
	var explosion : Explosion = EXPLOSION_PACKED.instantiate() as Explosion;
	# actually this does maybe not make sense since we reparent it to the component anyway xd
	explosion.exclude_parent = true;
	explosion.add_exception(self);
	explosion.global_position = self.global_position;
	get_parent().add_child(explosion);
	explosion.force_shapecast_update();
	for c in explosion.collision_result:
		# should probably also do a raycast and see if there's anything like
		# indestructible bricks between the target and the [brick] before destroying them
		c.collider.hit(explosion, 1997);


func hit(by: Node2D, damage: int) -> void:
	if by is Ball or by is Projectile:
		flip();
		queue_redraw();
		super(by, damage);


func _draw() -> void:
	if state != SwitchState.Random:
		draw_rect(Rect2(
			-Vector2(width, height) / 2, Vector2(width, height)
		), (Color.MEDIUM_BLUE if state == SwitchState.Blue\
		else Color.MAROON));
