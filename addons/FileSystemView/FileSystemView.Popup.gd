tool
extends PopupMenu

var filesystem : EditorFileSystem
var editor_interface : EditorInterface
var plugin : EditorPlugin

enum Menu {
	FILE_OPEN,
	FILE_INHERIT,
	FILE_MAIN_SCENE,
	FILE_INSTANCE,
	FILE_ADD_FAVORITE,
	FILE_REMOVE_FAVORITE,
	FILE_DEPENDENCIES,
	FILE_OWNERS,
	FILE_MOVE,
	FILE_RENAME,
	FILE_REMOVE,
	FILE_DUPLICATE,
	FILE_REIMPORT,
	FILE_INFO,
	FILE_NEW_FOLDER,
	FILE_NEW_SCRIPT,
	FILE_NEW_SCENE,
	FILE_SHOW_IN_EXPLORER,
	FILE_COPY_PATH,
	FILE_NEW_RESOURCE,
	FOLDER_EXPAND_ALL,
	FOLDER_COLLAPSE_ALL,
	#
	FSV_PLAY_SCENE = 50,
	FSV_COPY_PATHS
}

func _ready():
	plugin = get_parent().plugin
	if not plugin:
		return
	editor_interface = plugin.interface
	filesystem = plugin.filesystem
	
	set_hide_on_window_lose_focus(true)
	

func fill(paths: PoolStringArray):
	clear()
	set_size(Vector2(1,1))
	
	var all_files = true
	var all_files_scene = true
	var all_folders = true

	for path in paths:
		if path.ends_with("/"):
			all_files = false
		else:
			all_folders = false
			all_files_scene = all_files_scene and filesystem.get_file_type(path) == "PackedScene"
			
	if all_files:
		if paths.size() == 1 or all_files_scene:
			_add_item(Menu.FILE_OPEN, "Open", "Load")
		if all_files_scene:
			if paths.size() == 1:
				_add_item(Menu.FILE_INSTANCE, "New Inherited Scene", "CreateNewSceneFrom")
				_add_item(Menu.FSV_PLAY_SCENE, "Play Scene", "PlayScene")
			_add_item(Menu.FILE_INSTANCE, "Instance", "Instance")
		# todo handle other types
		
	# Favorite removed
		
	if all_files and paths.size() == 1:
		_fix_separator()
		_add_item(Menu.FILE_DEPENDENCIES, "Edit Dependencies...")
		_add_item(Menu.FILE_OWNERS, "View Owners...")
	
	_fix_separator()
	# currently can't get editor's shortcuts (#44307)
	_add_item(Menu.FSV_COPY_PATHS, "Copy Path", "ActionCopy")
	if paths[0] != "res://":
		if paths.size() == 1:
			_add_item(Menu.FILE_RENAME, "Rename...", "Rename")
			_add_item(Menu.FILE_DUPLICATE, "Duplicate...", "Duplicate")
		_add_item(Menu.FILE_MOVE, "Move To...", "MoveUp")
		_add_item(Menu.FILE_REMOVE, "Move to Trash", "Remove")
	
	if paths.size() == 1:
		_fix_separator()
		_add_item(Menu.FILE_NEW_FOLDER, "New Folder...", "Folder")
		_add_item(Menu.FILE_NEW_SCENE, "New Scene...", "PackedScene")
		_add_item(Menu.FILE_NEW_SCRIPT, "New Script...", "Script")
		_add_item(Menu.FILE_NEW_RESOURCE, "New Resource...", "Object")
		add_separator()
		_add_item(Menu.FILE_SHOW_IN_EXPLORER, "Show in File Manager", "Filesystem")


func _add_item(id, label, icon = null):
	if icon:
		add_icon_item(get_icon(icon, "EditorIcons"), label, id)
	else:
		add_item(label, id)


func _fix_separator():
	if get_item_count() > 0 and not is_item_separator(get_item_count()-1):
		add_separator()


func _rmb_option(id):
	var paths = get_parent().get_selected_paths()
	
	if id < 50:
		plugin.fsd_select_paths(paths)
		plugin.filesystem_dock.call("_tree_rmb_option", id)
		return
	
	match id:
		Menu.FSV_COPY_PATHS:
			var file_paths = ""
			for path in paths:
				file_paths += path + "\n"
			OS.clipboard = file_paths.trim_suffix("\n")
		Menu.FSV_PLAY_SCENE:
			var path = paths[0]
			editor_interface.play_custom_scene(path)
