extends CharacterBody2D


const BALL_RADIUS = 25;


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");


func _ready():
	collision_shape.shape.radius = BALL_RADIUS;
