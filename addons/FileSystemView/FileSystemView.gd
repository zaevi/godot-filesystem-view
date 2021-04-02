tool
extends Control

const PLUGIN_DIR = "res://addons/FileSystemView/"

var View = preload("res://addons/FileSystemView/View.gd")

var plugin

onready var tree : Tree = $VBox/Tree
onready var option_btn : OptionButton = $VBox/HBox/Option

var views: Array
var current_view

var _is_changing = false

var _cache_collapsed = {}

var _deferred = false

func _ready():
	if not plugin:
		return

	$VBox/HBox/Config.icon = get_icon("Tools", "EditorIcons")
	$VBox/HBox2/Unfold.icon = get_icon("AnimationTrackGroup", "EditorIcons")
	$VBox/HBox2/Collapse.icon = get_icon("AnimationTrackList", "EditorIcons")
	tree.set_drag_forwarding(self)
	
	views = plugin.views
	current_view = View.new()
	update_view_list()
	
	option_btn.select(0)
	_on_MenuButton_item_selected(0)
	
	plugin.filesystem.connect("filesystem_changed", self, "refresh_tree")
	plugin.config_dialog.connect("closed", self, "_on_ViewEditor_closed")


func change_view(view):
	cache_collapsed()
	current_view.name = view.name
	current_view.icon = view.icon
	current_view.include = view.include
	current_view.exclude = view.exclude
	current_view.hide_empty_dirs = view.hide_empty_dirs
	current_view.apply_include = view.apply_include
	current_view.apply_exclude = view.apply_exclude
	_is_changing = true
	$VBox/HBox2/HideEmpty.pressed = view.hide_empty_dirs
	$VBox/HBox2/ApplyInclude.pressed = view.apply_include
	$VBox/HBox2/ApplyExclude.pressed = view.apply_exclude
	_is_changing = false
	tree.clear()
	refresh_tree()


func update_view_list():
	var menu = option_btn.get_popup()
	menu.clear()
	var id = 0
	for view in views:
		menu.add_item(view.name, id)
		if view.icon != "" and has_icon(view.icon, "EditorIcons"):
			menu.set_item_icon(id, get_icon(view.icon, "EditorIcons"))
		id += 1


func refresh_tree():
	if tree.get_root():
		cache_collapsed()
		tree.clear()
		
	var fs = plugin.filesystem.get_filesystem()
	_create_tree(null, fs)
	
	if current_view and current_view.hide_empty_dirs:
		_clean_empty_dir(tree.get_root())
	
	if current_view.name and _cache_collapsed.has(current_view.name):
		_set_folder_collapsed(tree.get_root(), false, _cache_collapsed[current_view.name])


func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		var dd = get_viewport().gui_get_drag_data()
		if dd.has("type") and dd["type"] in ["files", "files_and_dirs", "resource"]:
			tree.drop_mode_flags = Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM
	elif what == NOTIFICATION_DRAG_END:
		tree.drop_mode_flags = 0


func _clean_empty_dir(current: TreeItem):
	var should_clean = true
	
	var item: TreeItem = current.get_children()
	while item:
		var path : String = item.get_metadata(0)
		if path.ends_with("/"):
			if _clean_empty_dir(item):
				current.remove_child(item)
			else:
				should_clean = false
		else:
			return false
		item = item.get_next()
		
	return should_clean


func _create_tree(parent: TreeItem, current: EditorFileSystemDirectory):
	var item = tree.create_item(parent)
	var dname = current.get_name()
	if dname == "":
		dname = "res://"
		
	item.set_text(0, dname)
	item.set_selectable(0, true)
	item.set_icon(0, get_icon("Folder", "EditorIcons"));
	item.set_icon_modulate(0, tree.get_color("folder_icon_modulate", "FileDialog"));
	
	var dir_path = current.get_path()
	item.set_metadata(0, dir_path)
	
	for i in current.get_subdir_count():
		_create_tree(item, current.get_subdir(i))
	
	var previewer = plugin.get_editor_interface().get_resource_previewer()
	
	for i in current.get_file_count():
		var file_name = current.get_file(i)
		var file_path = dir_path.plus_file(file_name)
		
		if current_view and not current_view.is_match(file_path):
			continue
		
		var file_type = current.get_file_type(i)
		var file_item = tree.create_item(item)
		file_item.set_text(0, file_name)
		file_item.set_icon(0, _get_tree_item_icon(current, i))
		file_item.set_metadata(0, file_path)
		previewer.queue_resource_preview(file_path, self, "_create_tree_preview_callback", file_item)


func _get_tree_item_icon(dir: EditorFileSystemDirectory, idx: int) -> Texture:
	var icon : Texture
	if not dir.get_file_import_is_valid(idx):
		icon = get_icon("ImportFail", "EditorIcons")
	else:
		var file_type = dir.get_file_type(idx)
		if has_icon(file_type, "EditorIcons"):
			icon = get_icon(file_type, "EditorIcons")
		else:
			icon = get_icon("File", "EditorIcons")
	return icon


func _create_tree_preview_callback(path, preview, small_preview : Texture, file_item):
	if small_preview and file_item:
		file_item.set_icon(0, small_preview)


func _on_MenuButton_item_selected(id):
	if id >= 0:
		var view = views[id]
		change_view(view)
	else:
		change_view(null)


func _on_Tree_item_activated():
	var item = tree.get_selected()
	var path: String = item.get_metadata(0)
	if path.ends_with("/"):
		item.collapsed = not item.collapsed
	else:
		plugin.fsd_open_file(path)


func _on_ConfigBtn_pressed():
	plugin.config_dialog.load_view(option_btn.selected)
	plugin.config_dialog.popup_centered()


func _on_ViewEditor_closed():
	update_view_list()
	
	var found_view
	for view in views:
		if view.name == current_view.name:
			found_view = view
			break

	if found_view:
		var id = views.find(found_view)
		option_btn.select(id)
		change_view(found_view)
	else:
		option_btn.select(0)
		change_view(views[0])


func _set_folder_collapsed(current:TreeItem, collapsed:bool, excepts = null):
	var item: TreeItem = current.get_children()
	
	while item:
		var path : String = item.get_metadata(0)
		if path.ends_with("/"):
			_set_folder_collapsed(item, collapsed, excepts)
			if excepts and path in excepts:
				item.collapsed = not collapsed
			else:
				item.collapsed = collapsed
		item = item.get_next()


func _on_Unfold_pressed():
	var root = tree.get_root()
	_set_folder_collapsed(root, false)


func _on_Collapse_pressed():
	var root = tree.get_root()
	_set_folder_collapsed(root, true)


func _on_Locate_pressed():
	pass


func _on_Tree_item_rmb_selected(position):
	var paths = get_selected_paths()
	$Popup.fill(paths)
	$Popup.set_position(tree.get_global_rect().position + position)
	$Popup.popup()

func _on_Tree_multi_selected(item, column, selected):
	if _deferred:
		return
	_deferred = true
	call_deferred("_update_remote_tree")
	call_deferred("set", "_deferred", false)


func _update_remote_tree():
	var paths = get_selected_paths()
	plugin.fsd_select_paths(paths)


func _on_ApplyInclude_toggled(button_pressed):
	if not _is_changing:
		current_view.apply_include = button_pressed
		refresh_tree()


func _on_ApplyExclude_toggled(button_pressed):
	if not _is_changing:
		current_view.apply_exclude = button_pressed
		refresh_tree()


func _on_HideEmpty_toggled(button_pressed):
	if not _is_changing:
		current_view.hide_empty_dirs = button_pressed
		refresh_tree()


func get_drag_data_fw(position, from_control):
	var paths = get_selected_paths()
	plugin.fsd_select_paths(paths)
	return plugin.filesystem_dock.get_drag_data_fw(get_global_mouse_position(), plugin.tree)


func can_drop_data_fw(position, data, from_control):
	var type = data["type"] if data.has("type") else null
	# todo resource is not supported
	if not type in ["files", "files_and_dirs"]:
		return false
	var target = _get_drag_target_folder(position)
	if not target:
		return false
	
	if type == "files_and_dirs":
		for path in data["files"]:
			if path.ends_with("/") and target.begins_with(path):
				return false
	
	return true


func drop_data_fw(position, data, from_control):
	if not can_drop_data_fw(position, data, from_control):
		return
	
	var target = _get_drag_target_folder(position)
	var type = data["type"] if data.has("type") else null
	
	plugin.fsd_select_paths(data["files"])
	plugin.filesystem_dock.call("_tree_rmb_option", $Popup.Menu.FILE_MOVE)
	if plugin.filesystem_move_dialog.visible:
		plugin.filesystem_move_dialog.hide()
		plugin.filesystem_move_dialog.emit_signal("dir_selected", target)


func _get_drag_target_folder(pos: Vector2):
	var item = tree.get_item_at_position(pos)
	var section = tree.get_drop_section_at_position(pos)
	if item:
		var path = item.get_metadata(0)
		var is_folder = path.ends_with("/")
		if is_folder and section == 0:
			return path # drop in folder
		elif is_folder and section != 0 and path != "res://":
			return path.substr(0, len(path)-1).get_base_dir() # drop in folder's base dir
		elif not is_folder:
			return path.get_base_dir() # drop in file's base dir
			
	return null


func cache_collapsed():
	var root = tree.get_root()	
	if not current_view.name or not root:
		return
	var list = []
	_cache_collapsed_list(root, list)
	_cache_collapsed[current_view.name] = list


func _cache_collapsed_list(parent: TreeItem, list: Array):
	var item: TreeItem = parent.get_children()
	while item: 
		var path : String = item.get_metadata(0)
		if path.ends_with("/"):
			_cache_collapsed_list(item, list)
			if item.collapsed:
				list.append(path)
		item = item.get_next()


func get_selected_paths():
	var paths = []
	var item = tree.get_next_selected(null)
	while item:
		paths.push_back(item.get_metadata(0))
		item = tree.get_next_selected(item)
	
	return paths
	

