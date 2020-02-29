tool
extends Control

const PLUGIN_DIR = "res://addons/FileSystemView/"

var View = preload("res://addons/FileSystemView/View.gd")

var agent = preload("EditorAgent.gd").new()

onready var tree : Tree = $VBox/Tree

var views: Array
var current_view

func _ready():
	load_views()
	update_view_list()
	
	$VBox/MenuButton.select(0)
	_on_MenuButton_item_selected(0)

func change_view(view):
	current_view = view
	refresh_tree()

func update_view_list():
	var menu = $VBox/MenuButton.get_popup()
	menu.clear()
	var id = 0
	for view in views:
		menu.add_item(view.name, id)
		if view.icon != "" and has_icon(view.icon, "EditorIcons"):
			menu.set_item_icon(id, get_icon(view.icon, "EditorIcons"))
			menu.set_item_metadata(id, view)
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
		config.set_value(istr, "include", view.include)
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
