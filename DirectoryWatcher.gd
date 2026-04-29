## Scans the provided directory (or directories) and informs about file changes. The scan is done periodically with configurable speed.
class_name DirectoryWatcher extends Node

## Delay between directory scans (in seconds).
@export var scan_delay := 1.0
## Files scanned per frame.
@export var scan_step := 50
## List of directories to scan. They can be assigned from the inspect, as an alternative to [method add_scan_directory]. The folders are registered in [constant Node.NOTIFICATION_READY] and can't be modified afterwards via the property.
@export_dir var directory_list: PackedStringArray

var _directory := DirAccess.open(".")

var _directory_list: Dictionary[String, _WatchedDirectory]
var _directory_cache: PackedStringArray
var _to_delete: PackedStringArray

var _current_directory_index: int
var _current_directory_name: String
var _remaining_steps: int
var _current_delay: float

## Emitted when files are created in the scanned directories.
signal files_created(files: PackedStringArray)
## Emitted when files are modified in the scanned directories (based on modified time).
signal files_modified(files: PackedStringArray)
## Emitted when files are deleted in the scanned directories.
signal files_deleted(files: PackedStringArray)

## Adds a directory that will be scanned. You can add more than 1. Only supports absolute paths and res://, user://.
func add_scan_directory(directory: String):
	directory = ProjectSettings.globalize_path(directory)
	_directory_list[directory] = _WatchedDirectory.new()
	_directory_cache = _directory_list.keys()

## Removes a scanned directory. Does nothing if the directory wasn't added.
func remove_scan_directory(directory: String):
	directory = ProjectSettings.globalize_path(directory)
	_to_delete.append(directory)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			for dir in directory_list:
				add_scan_directory(dir)
			
			directory_list.clear()
			
			_current_delay = scan_delay
			_remaining_steps = scan_step
			_directory.include_hidden = true
			
			set_process_internal(true)
		
		NOTIFICATION_INTERNAL_PROCESS:
			if _directory_list.is_empty():
				push_error("No directory to watch. Please kill me ;_;")
				return
			
			if _current_delay > 0:
				_current_delay -= get_process_delta_time()
				return
			
			while _remaining_steps > 0:
				if _current_directory_name.is_empty():
					_current_directory_name = _directory_cache[_current_directory_index]
					_directory.change_dir(_current_directory_name)
					_directory.list_dir_begin()
				
				var directory := _directory_list[_current_directory_name]
				
				var file := _directory.get_next()
				if file.is_empty():
					_current_directory_index += 1
					_current_directory_name = ""
					_directory.list_dir_end()
					
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
							_to_delete.clear()
						
						_current_directory_index = 0
						break
				else:
					if _directory.current_is_dir():
						continue
					var full_file := _directory.get_current_dir().path_join(file)
					
					var current_modtime := FileAccess.get_modified_time(full_file)
					directory.current[file] = current_modtime
					
					var old_modtime: int = directory.previous.get(file, -1)
					if old_modtime == -1:
						directory.new.append(full_file)
					elif current_modtime > old_modtime:
						directory.modified.append(full_file)
					
					_remaining_steps -= 1
			
			_remaining_steps = scan_step
			_current_delay = scan_delay

class _WatchedDirectory:
	var first_scan := true
	var new: PackedStringArray
	var modified: PackedStringArray
	var current: Dictionary[String, int]
	var previous: Dictionary[String, int]
