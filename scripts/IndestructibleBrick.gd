class_name UnbreakableBrick extends "res://scripts/BrickBase.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	super();
	durability = -1;


func hit(b: Ball):
	super(b);
