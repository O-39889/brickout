extends StaticBody2D


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


var counter = PaddleSize.PADDLE_SIZE_NORMAL;

@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
@onready var width := PADDLE_SIZES[PaddleSize.PADDLE_SIZE_NORMAL];


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape.shape.b.x = width;
	pass # Replace with function body.


func set_width(idx: PaddleSize):
	width = PADDLE_SIZES[idx];
	collision_shape.shape.b.x = width;


func _input(event: InputEvent):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			position.x += event.relative.x * Globals.MOUSE_SENSITIVITY;
			position.x = clamp(position.x, 0, get_viewport_rect().size.x - width);
