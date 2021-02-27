tool
extends EditorPlugin

const PLUGIN_DIR = "res://addons/FileSystemView/"
var View = preload("res://addons/FileSystemView/View.gd")

var fsview = preload("FileSystemView.tscn").instance()
var config_dialog = preload("ViewEditor.tscn").instance()

var interface: EditorInterface
var filesystem: EditorFileSystem
var editor_node : Node
var filesystem_dock : Node
var rmb_popup
var tree : Tree

var views : Array

var config : Dictionary

func _enter_tree():
	interface = get_editor_interface()
	filesystem = interface.get_resource_filesystem()
	editor_node = interface.get_base_control().get_parent().get_parent()
	filesystem_dock = interface.get_base_control().find_node("FileSystem", true, false)
	for i in filesystem_dock.get_children():
		if i is VSplitContainer:
			tree = i.get_child(0)
			break
	
	load_views()
	
	config_dialog.plugin = self
	config_dialog.connect("closed", self, "_on_ViewEditor_closed")
	interface.get_base_control().add_child(config_dialog)

	fsview.plugin = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, fsview)


func _exit_tree():
	remove_control_from_docks(fsview)
	fsview.queue_free()
	config_dialog.queue_free()


func load_views():
	var file = File.new()
	if file.open(PLUGIN_DIR + "config.json", File.READ) != OK:
		if file.open(PLUGIN_DIR + "defaultConfig.json", File.READ) == OK:
			print_debug("FileSystemView: load defaultConfig.json")
	
	var result = JSON.parse(file.get_as_text()).result
	self.config = result
	self.views = self.config.views


func save_views():
	var json = to_json(config)
	var file = File.new()
	file.open(PLUGIN_DIR + "config.json", File.WRITE)
	file.store_string(json)
	file.close()


func _on_ViewEditor_closed():
	save_views()


func fsd_open_file(file_path: String):
	## method EditorNode:load_resource is not bound, so use FileSystemDock
	#	if filesystem.get_file_type(file_path) == "PackedScene":
	#		editor_node.call("open_request", file_path)
	#	else:
	#		editor_node.call("load_resource", file_path) # invalid call
	filesystem_dock.call("_select_file", file_path, false)


func _fsd_locate_item(root: TreeItem, path: String):
	var item : TreeItem = root.get_children()
	while item:
		var item_path : String = item.get_metadata(0)
		if path == item_path:
			return item
		elif path.begins_with(item_path):
			return _fsd_locate_item(item, path)
		item = item.get_next()
	print("can't find treepath ", path)
	return null


func fsd_locate_item(path: String) -> TreeItem:
	var res_root = tree.get_root().get_children().get_next()
	if path == "res://":
		return res_root
	return _fsd_locate_item(res_root, path)


func fsd_select_item(path: String):
	var item = fsd_locate_item(path)
	
	# easier way to unselect all
	tree.select_mode = Tree.SELECT_SINGLE
	item.select(0)
	tree.select_mode = Tree.SELECT_MULTI
	# fix show-in-file-manager
	tree.emit_signal("multi_selected", null, 0, true)
