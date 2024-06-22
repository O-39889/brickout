class_name Paddle extends StaticBody2D


enum PaddleSize {
	PADDLE_SIZE_TINY,
	PADDLE_SIZE_SMALL,
	PADDLE_SIZE_NORMAL,
	PADDLE_SIZE_LARGE,
	PADDLE_SIZE_HUMONGOUS,
}


const PADDLE_SIZES = [
	100,
	150,
	240,
	300,
	400,
]


var balls : Array[Ball] = [];
# whether a paddle should spawn a ball on itself or not when created
var spawn_ball;
var sticky : bool = false;

@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
@onready var width := PADDLE_SIZES[PaddleSize.PADDLE_SIZE_NORMAL];


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape.shape.b.x = width;
	if spawn_ball == null:
		spawn_ball = true;
	if spawn_ball == true:
		var b : Ball = load("res://scenes/Ball.tscn").instantiate();
		b.stuck = true;
		b.position.x = width / 2.0;
		b.position.y = -b.BALL_RADIUS;
		add_child(b);
		balls.append(b);


func add_bawl(b: Ball):
	b.reparent(self);
	balls.append(b);


func set_width(idx: PaddleSize):
	width = PADDLE_SIZES[idx];
	collision_shape.shape.b.x = width;


func _input(event: InputEvent):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			position.x += event.relative.x * Globals.MOUSE_SENSITIVITY;
			position.x = clamp(position.x, 0, get_viewport_rect().size.x - width);
		if event is InputEventMouseButton and balls.size() > 0:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# release the bawl
				var first_bawl : Ball = balls.pop_front();
				first_bawl.reparent(get_parent());
				first_bawl.launch();
				pass
