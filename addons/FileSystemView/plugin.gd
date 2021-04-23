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
var filesystem_popup : PopupMenu
var filesystem_move_dialog: ConfirmationDialog
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
		elif i is PopupMenu:
			filesystem_popup = i
		elif i is ConfirmationDialog and i.has_signal("dir_selected"):
			filesystem_move_dialog = i
		if tree and filesystem_popup and filesystem_move_dialog:
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
	filesystem_dock.call("_select_file", file_path, false)


func fsd_select_paths(paths: PoolStringArray):
	if paths.size() == 0:
		return

	var temp_item = tree.create_item(tree.get_root())
	var _start_select = false
	for path in paths:
		var item = tree.create_item(temp_item)
		item.set_metadata(0, path)
		if _start_select:
			item.select(0)
		else:
			tree.select_mode = Tree.SELECT_SINGLE
			item.select(0)
			tree.select_mode = Tree.SELECT_MULTI
			_start_select = true
	
	tree.emit_signal("multi_selected", null, 0, true)
	tree.get_root().call_deferred("remove_child", temp_item)
	tree.call_deferred("update")
