@tool
extends PopupMenu

var filesystem : EditorFileSystem
var plugin : EditorPlugin

var _tree_rmb_option : Callable

var new_menu : PopupMenu

enum Menu {
	FILE_OPEN,
	FILE_INHERIT,
	FILE_MAIN_SCENE,
	FILE_INSTANTIATE,
	FILE_ADD_FAVORITE,
	FILE_REMOVE_FAVORITE,
	FILE_SHOW_IN_FILESYSTEM,
	FILE_DEPENDENCIES,
	FILE_OWNERS,
	FILE_MOVE,
	FILE_RENAME,
	FILE_REMOVE,
	FILE_DUPLICATE,
	FILE_REIMPORT,
	FILE_NEW,
	FILE_SHOW_IN_EXPLORER,
	FILE_OPEN_EXTERNAL,
	FILE_OPEN_IN_TERMINAL,
	FILE_COPY_PATH,
	FILE_COPY_ABSOLUTE_PATH,
	FILE_COPY_UID,
	FOLDER_EXPAND_ALL,
	FOLDER_COLLAPSE_ALL,
	FILE_NEW_RESOURCE,
	FILE_NEW_TEXTFILE,
	FILE_NEW_FOLDER,
	FILE_NEW_SCRIPT,
	FILE_NEW_SCENE,
	CONVERT_BASE_ID = 1000,
	#
	FSV_PLAY_SCENE = 50,
	FSV_COPY_PATHS
}

func _ready():
	plugin = get_parent().plugin
	if not plugin:
		return
	filesystem = plugin.filesystem
	
	# get callable `FileSystemDock::_tree_rmb_option`
	for connection in plugin.filesystem_popup.get_signal_connection_list("id_pressed"):
		var callable : Callable = connection.callable
		if str(callable) == "FileSystemDock::_file_list_rmb_option":
			_tree_rmb_option = callable
			break
	assert(_tree_rmb_option, "can't find callable `_tree_rmb_option`")
	
	# set_hide_on_window_lose_focus(true)
	

func fill(paths: PackedStringArray): 
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
				_add_item(Menu.FILE_INHERIT, "New Inherited Scene", "CreateNewSceneFrom")
				_add_item(Menu.FSV_PLAY_SCENE, "Play Scene", "PlayScene")
			_add_item(Menu.FILE_INSTANTIATE, "Instance", "Instance")
		# TODO handle other types
		
	# Favorite removed
		
	if all_files and paths.size() == 1:
		_fix_separator()
		_add_item(Menu.FILE_DEPENDENCIES, "Edit Dependencies...")
		_add_item(Menu.FILE_OWNERS, "View Owners...")
	
	_fix_separator()
	if paths.size() == 1:
		if not new_menu:
			new_menu = PopupMenu.new()
			new_menu.name = "New"
			new_menu.id_pressed.connect(_rmb_option)
			_add_item(Menu.FILE_NEW_FOLDER, "Folder...", "Folder", new_menu)
			_add_item(Menu.FILE_NEW_SCENE, "Scene...", "PackedScene", new_menu)
			_add_item(Menu.FILE_NEW_SCRIPT, "Script...", "Script", new_menu)
			_add_item(Menu.FILE_NEW_RESOURCE, "Resource...", "Object", new_menu)
			_add_item(Menu.FILE_NEW_TEXTFILE, "TextFile...", "TextFile", new_menu)
			add_child(new_menu)
		add_submenu_item("New", "New")
	_fix_separator()
	# TODO folder OPEN/EXPAND/COLLAPSE
	# TODO folder color
	# TODO waiting for editor's shortcuts (#58585)
	_add_item(Menu.FSV_COPY_PATHS, "Copy Path", "ActionCopy")
	if paths[0] != "res://":
		if paths.size() == 1:
			# TODO re-implement
			# _add_item(Menu.FILE_RENAME, "Rename...", "Rename")
			_add_item(Menu.FILE_DUPLICATE, "Duplicate...", "Duplicate")
		_add_item(Menu.FILE_MOVE, "Move/Duplicate To...", "MoveUp")
		_add_item(Menu.FILE_REMOVE, "Remove", "Remove")
	
	if paths.size() == 1:
		_fix_separator()
		_add_item(Menu.FILE_SHOW_IN_EXPLORER, "Show in File Manager", "Filesystem")
		if all_files:
			_add_item(Menu.FILE_OPEN_EXTERNAL, "Open in External Program", "ExternalLink")


func _add_item(id, label, icon = "", popup = null):
	if not popup:
		popup = self
	if icon != "":
		popup.add_icon_item(get_theme_icon(icon, "EditorIcons"), label, id)
	else:
		popup.add_item(label, id)


func _fix_separator():
	if get_item_count() > 0 and not is_item_separator(get_item_count()-1):
		add_separator()


func _rmb_option(id):
	var paths = get_parent().get_selected_paths()
	
	if id < 50:
		plugin.fsd_select_paths(paths)
		_tree_rmb_option.call(id)
		return
	
	match id:
		Menu.FSV_COPY_PATHS:
			var file_paths = ""
			for path in paths:
				file_paths += path + "\n"
			DisplayServer.clipboard_set(file_paths.trim_suffix("\n"))
		Menu.FSV_PLAY_SCENE:
			var path = paths[0]
			EditorInterface.play_custom_scene(path)
