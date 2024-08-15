extends Node
class_name DirectoryWatcher

## Scans the provided directory (or directories) and informs about file changes. The scan is done periodically with configurable speed.

class WatchedDirectory:
	var first_scan := true
	var new: PackedStringArray
	var modified: PackedStringArray
	var current: Dictionary#[String, int]
	var previous: Dictionary#[String, int]

var _directory := DirAccess.open(".")

var _directory_list: Dictionary#[String, WatchedDirectory]
var _directory_cache: Array[String]
var _to_delete: Array

var _current_directory_index: int
var _current_directory_name: String
var _remaining_steps: int
var _current_delay: float

## Delay between directory scans (in seconds).
var scan_delay: float = 1
## Files scanned per frame.
var scan_step := 50

## Emitted when files are created in the scanned directories.
signal files_created(files: PackedStringArray)
## Emitted when files are modified in the scanned directories (based on modified time).
signal files_modified(files: PackedStringArray)
## Emitted when files are deleted in the scanned directories.
signal files_deleted(files: PackedStringArray)

func _ready() -> void:
	_current_delay = scan_delay
	_remaining_steps = scan_step
	_directory.include_hidden = true

## Adds a directory that will be scanned. You can add more than 1. Only supports absolute paths and res://, user://.
func add_scan_directory(directory: String):
	directory = ProjectSettings.globalize_path(directory)
	_directory_list[directory] = WatchedDirectory.new()
	_directory_cache.assign(_directory_list.keys())

## Removes a scanned directory. Does nothing if the directory wasn't added.
func remove_scan_directory(directory: String):
	directory = ProjectSettings.globalize_path(directory)
	_to_delete.append(directory)

func _process(delta: float) -> void:
	if _directory_list.is_empty():
		push_error("No directory to watch. Please kill me ;_;")
		return
	
	if _current_delay > 0:
		_current_delay -= delta
		return
	
	while _remaining_steps > 0:
		if _current_directory_name.is_empty():
			_current_directory_name = _directory_cache[_current_directory_index]
			_directory.change_dir(_current_directory_name)
			_directory.list_dir_begin()
		
		var directory: WatchedDirectory = _directory_list[_current_directory_name]
		
		var file := _directory.get_next()
		if file.is_empty():
			_current_directory_index += 1
			_current_directory_name = ""
			
			if directory.first_scan:
				directory.new.clear()
				directory.modified.clear()
				directory.first_scan = false
			else:
				if not directory.new.is_empty():
					files_created.emit(directory.new)
					directory.new.clear()
				
				if not directory.modified.is_empty():
					files_modified.emit(directory.modified)
					directory.modified.clear()
				
				var deleted: PackedStringArray
				for path in directory.previous:
					if not path in directory.current:
						deleted.append(_directory.get_current_dir().path_join(path))
				
				if not deleted.is_empty():
					files_deleted.emit(deleted)
			
			directory.previous = directory.current
			directory.current = {}
			
			if _current_directory_index == _directory_list.size():
				if not _to_delete.is_empty():
					for dir in _to_delete:
						_directory_list.erase(dir)
				
				_current_directory_index = 0
				break
		else:
			if _directory.current_is_dir():
				continue
			var full_file := _directory.get_current_dir().path_join(file)
			
			directory.current[file] = FileAccess.get_modified_time(full_file)
			if directory.previous.get(file, -1) == -1:
				directory.new.append(full_file)
			elif directory.current[file] > directory.previous[file]:
				directory.modified.append(full_file)
			
			_remaining_steps -= 1
	
	_remaining_steps = scan_step
	_current_delay = scan_delay
