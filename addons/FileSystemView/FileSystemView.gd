tool
extends Control

const PLUGIN_DIR = "res://addons/FileSystemView/"

var View = preload("res://addons/FileSystemView/View.gd")

var agent = preload("EditorAgent.gd").new()

onready var tree : Tree = $VBox/Tree
onready var option_btn : OptionButton = $VBox/HBox/Option

var views: Array
var current_view

var config_dialog = null

func _ready():
	pass


func init(plugin: EditorPlugin):
	agent._set_interface(plugin)
	
	$VBox/HBox/Config.icon = get_icon("Tools", "EditorIcons")
	$VBox/HBox2/Unfold.icon = get_icon("AnimationTrackGroup", "EditorIcons")
	$VBox/HBox2/Collapse.icon = get_icon("AnimationTrackList", "EditorIcons")
	
	current_view = View.new()
	load_views()
	update_view_list()
	
	option_btn.select(0)
	_on_MenuButton_item_selected(0)
	
	agent.filesystem.connect("filesystem_changed", self, "refresh_tree")
	
	


func change_view(view):
#	current_view = view
	current_view.name = view.name
	current_view.icon = view.icon
	current_view.include = view.include
	current_view.exclude = view.exclude
	current_view.hide_empty_dirs = view.hide_empty_dirs
	current_view.apply_include = view.apply_include
	current_view.apply_exclude = view.apply_exclude
	$VBox/HBox2/HideEmpty.pressed = view.hide_empty_dirs
	$VBox/HBox2/ApplyInclude.pressed = view.apply_include
	$VBox/HBox2/ApplyExclude.pressed = view.apply_exclude
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


func load_views():
	views = []
	
	var config = ConfigFile.new()
	if config.load(PLUGIN_DIR + "views.cfg") != OK:
		if config.load(PLUGIN_DIR + "default_views.cfg") == OK:
			print_debug("FileSystemView: load default_views.cfg")
			
	for i in config.get_sections():
		var view = View.new()
		view.name = config.get_value(i, "name", "")
		view.icon = config.get_value(i, "icon", "")
		view.apply_include = config.get_value(i, "apply_include", true)
		view.apply_exclude = config.get_value(i, "apply_exclude", false)
		view.include = config.get_value(i, "include", "")
		view.exclude = config.get_value(i, "exclude", "")
		view.hide_empty_dirs = config.get_value(i, "hide_empty_dirs", true)
		views.append(view)


func save_views():
	var config = ConfigFile.new()
	var i = 0
	for view in views:
		var istr = str(i)
		config.set_value(istr, "name", view.name)
		config.set_value(istr, "icon", view.icon)
		config.set_value(istr, "apply_include", view.apply_include)
		config.set_value(istr, "include", view.include)
		config.set_value(istr, "apply_exclude", view.apply_exclude)
		config.set_value(istr, "exclude", view.exclude)
		config.set_value(istr, "hide_empty_dirs", view.hide_empty_dirs)
		i += 1
		
	config.save(PLUGIN_DIR + "views.cfg")


func refresh_tree():
	tree.clear()
	var fs = agent.filesystem.get_filesystem()
	_create_tree(null, fs)
	
	if current_view and current_view.hide_empty_dirs:
		_clean_empty_dir(tree.get_root())


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
	item.set_metadata(0, current.get_path())
	
	for i in current.get_subdir_count():
		_create_tree(item, current.get_subdir(i))
	
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


func _exit_tree():
	if config_dialog:
		config_dialog.queue_free()


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
		agent.open_file(path)


func _on_ConfigBtn_pressed():
	if not config_dialog:
		config_dialog = preload("ViewEditor.tscn").instance()
		agent.interface.get_base_control().add_child(config_dialog)
		config_dialog.init()
		config_dialog.connect("popup_hide", self, "_on_ViewEditor_closed")
		config_dialog.views = views
		config_dialog.update_view_list()
	
	config_dialog.load_view(option_btn.selected)
	config_dialog.popup_centered()


func _on_ViewEditor_closed():
	config_dialog.save_current()
	save_views()
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
	pass # Replace with function body.


func _on_Tree_item_rmb_selected(position):
	var path = tree.get_selected().get_metadata(0)
	agent.select_item(path)
	agent.tree.emit_signal("item_rmb_selected", position)
	pass # Replace with function body.


func _on_ApplyInclude_toggled(button_pressed):
	current_view.apply_include = button_pressed
	refresh_tree()


func _on_ApplyExclude_toggled(button_pressed):
	current_view.apply_exclude = button_pressed
	refresh_tree()


func _on_HideEmpty_toggled(button_pressed):
	current_view.hide_empty_dirs = button_pressed
	refresh_tree()

