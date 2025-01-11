extends Node;


const AUTOSAVE_FILENAME = 'autosave.sav';
const AUTOSAVE_DIR = 'user://saves';
const AUTOSAVE_PATH = AUTOSAVE_DIR + '/' + AUTOSAVE_FILENAME;


func _ready():
	if not DirAccess.dir_exists_absolute(AUTOSAVE_DIR):
		DirAccess.make_dir_recursive_absolute(AUTOSAVE_DIR);


## Loads game data from the autosave file.
func load_from_autosave() -> Savedata:
	if not DirAccess.dir_exists_absolute(AUTOSAVE_DIR):
		print('No directory %s exists' % AUTOSAVE_DIR);
		return null;
	if not FileAccess.file_exists(AUTOSAVE_PATH):
		print('No save file %s exists in the directory %s' % [AUTOSAVE_FILENAME, AUTOSAVE_DIR]);
		return null;
	var file = FileAccess.open(AUTOSAVE_PATH, FileAccess.READ);
	var err := FileAccess.get_open_error();
	if err:
		printerr('Couldn\'t load the save file: error code %d' % err);
		return null;
	var dict := JSON.parse_string(file.get_as_text());
	if dict != null:
		return Savedata.from_dict(dict);
	return null;


## Saves the current game data to the autosave file.
func save_to_autosave(savedata: Savedata) -> Error:
	#var savedata = create_savedata_object();
	if not DirAccess.dir_exists_absolute(AUTOSAVE_DIR):
		print('No directory %s exists for saving,creating...' % AUTOSAVE_DIR);
		DirAccess.make_dir_recursive_absolute(AUTOSAVE_DIR)
	if not FileAccess.file_exists(AUTOSAVE_PATH):
		print('No file %s exists at a given directory, creaitng...' % AUTOSAVE_FILENAME);
	var file = FileAccess.open(AUTOSAVE_PATH, FileAccess.WRITE);
	var err = FileAccess.get_open_error();
	if err:
		printerr('Couldn\'t save game: error code %d' % err);
		return err;
	var json = JSON.stringify(savedata.to_dict());
	file.store_line(json);
	return Error.OK;


# actually I think I will NOT create a dictionary in here
# but instead let GameProgression handle its creation
# itself even though it's probably still gonna be a pain?
# but idk
# I want it to save: when the level is cleared (maybe
# immediately), reset the data on game overed,
# and also save upon exiting to menu, although technically
# probably doesn't need to do that since we already kinda
# just have already saved when the levle is cleared
# YES it will probably be less pain to just
# have GameProgression create that object itself
## Converts the current save data in the GameProgression
## autoload into a dictionary object.
func create_savedata_object() -> Dictionary:
	var data := {
		'has_session': GameProgression.has_progress,
		'max_level_reached': GameProgression.max_level_reached + 1,
		'version': 1,
	};
	if GameProgression.has_progress:
		data.merge({
			'score': GameProgression.last_level_score,
			'lives': GameProgression.last_level_lives,
			# extra lives earned should be derived from the score I think
			'time': GameProgression.last_level_time_total,
			'started_at': GameProgression.session_started_idx + 1,
			'left_at': GameProgression.current_level_idx + 1,
		});
	return data;


## Parses a dictionary object and alters the state
## of the GameProgression autoload.
func unpack_savedata_object(data: Dictionary) -> void:
	pass


## Parses a dictionary savedata object and converts
## it to the new version format if it has an older version.
func _convert_versions(data: Dictionary) -> Dictionary:
	return data;
