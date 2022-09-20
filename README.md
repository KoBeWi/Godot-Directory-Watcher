# <img src="https://github.com/KoBeWi/Godot-Directory-Watcher/blob/master/Media/Icon.png" width="64" height="64"> Godot Directory Watcher

DirectoryWatcher will notify you whenever files or file list has changed in a directory.

## Usage

1. Create the watcher.
```GDScript
var watcher = DirectoryWatcher.new()
add_child(watcher)
```

2. Add a directory to watch.
```GDScript
watcher.add_scan_directory("res://directory")
```
(automatically gets converted to absolute path; you can add more than 1)

3. Connect signals.
```GDScript
watcher.files_created.connect(on_files_created)
watcher.files_modified.connect(on_files_modified)
watcher.files_deleted.connect(on_files_deleted)
```

4. Enjoy.

![](https://github.com/KoBeWi/Godot-Directory-Watcher/blob/master/Media/ReadmeShowcase.gif)

## Some technical info

DirectoryWatcher will periodically crawl over the files in a directory and report all file changes. Sub-directories are ignored and the scan isn't recursive. To reduce I/O operations, the scan runs every second and scans 50 files per frame inside `_process()` method. Rate of scan and files per frame are configurable with `scan_delay` and `scan_step` variables.
```GDScript
watcher.scan_delay = 0.5
watcher.scan_step = 20
```
The signals are emitted at the end of a scan cycle and files are passed as absolute paths.

You can deregister a directory by using `remove_scan_directory()`. This will take effect at the end of the current scan cycle. The class has built-in documentation.

___
You can find all my addons on my [profile page](https://github.com/KoBeWi).

<a href='https://ko-fi.com/W7W7AD4W4' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
