extends VBoxContainer;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.should_fade_level_select:
		Globals.should_fade_level_select = false;
		var level_list : Container = %LevelList;
		#for choose_btn : BaseButton in level_list.get_children():
			#pass # Holy stuff I can't do that in here obviously because of it being a container so I will actually have to override the container node itself
			## sounds like a lot of pain so whatever
	
	%ExitBtn.position.y = (%ChooseLevelLbl.size.y - %ExitBtn.size.y) / 2.0;


func _on_exit_btn_pressed() -> void:
	# SCREW THIS ONE SCENE IN PARTICULAR
	print(TitleScreen.TITLE_PACKED);
	print(TitleScreen.TITLE_PACKED.can_instantiate());
	print(TitleScreen.TITLE_PACKED.instantiate());
	#get_tree().change_scene_to_packed(TitleScreen.TITLE_PACKED);
	#return;
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
