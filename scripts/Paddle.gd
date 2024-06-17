extends StaticBody2D


const PADDLE_SIZE = 250;

@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
@onready var width = PADDLE_SIZE;


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape.shape.b.x = width;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _input(event: InputEvent):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			position.x += event.relative.x * Globals.MOUSE_SENSITIVITY;
			position.x = clamp(position.x, 0, get_viewport_rect().size.x - width);
