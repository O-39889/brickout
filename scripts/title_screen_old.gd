extends Level;


@export_dir var layout_directory : String;

var spawned_balls_amount := randi_range(2, 3);
var last_layout_name : String = '';
var brick_layout : Node2D;


func _ready():
	layout_directory = layout_directory.trim_suffix('/');
	super(); # put right wall in its place <>_<>
	$Walls/WallBottom.position.y = get_viewport_rect().size.y;
	find_child("MeLbl").text += str(Time.get_date_dict_from_system()['year']);
	reset_brick_layout();


func reset_brick_layout():
	for b : Ball in get_tree().get_nodes_in_group(&'balls'):
		b.process_mode = Node.PROCESS_MODE_DISABLED;
		b.queue_free();
	if brick_layout:
		brick_layout.queue_free();
		brick_layout = null;
	var to_choose := DirAccess.get_files_at(layout_directory);
	if not last_layout_name.is_empty() and to_choose.size() > 1:
		to_choose.remove_at(to_choose.find(last_layout_name));
	var scene_name = to_choose[randi_range(0, to_choose.size() - 1)];
	last_layout_name = scene_name;
	var absolute_name = layout_directory + '/' + last_layout_name;
	brick_layout = load(absolute_name).instantiate();
	brick_layout.level = self;
	# it has to have "hardcoded" position in the scene tree so to speak
	# just so that it renders in a specified way
	ball_component.add_sibling(brick_layout);
	await get_tree().create_timer(2.0).timeout;
	ball_component.spawn_balls(spawned_balls_amount);


func finish():
	EventBus.level_cleared.emit();
	await get_tree().create_timer(1.5).timeout;
	reset_brick_layout();


func _on_quit_btn_pressed():
	get_tree().quit();
