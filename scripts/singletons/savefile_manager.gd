extends Node;


const AUTOSAVE_FILENAME = 'autosave.sav';


## Loads game data from the autosave file.
func load_from_autosave() -> Error:
	return Error.OK;


## Saves the current game data to the autosave file.
func save_to_autosave() -> Error:
	return Error.OK;


## Converts the current save data in the GameProgression
## autoload into a dictionary object.
func create_savedata_object() -> Dictionary:
	return {};


## Parses a dictionary object and alters the state
## of the GameProgression autoload.
func unpack_savedata_object(data: Dictionary) -> void:
	pass
