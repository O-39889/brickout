class_name LevelChooseButton extends Button;


var num : int;
var target_level_name : String;


func _ready() -> void:
	text = str(num);
