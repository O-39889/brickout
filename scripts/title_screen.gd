extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	find_child("MeLbl").text += str(Time.get_date_dict_from_system()['year']);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
