@tool
extends EditorPlugin

const PLUGIN_DIR = "res://addons/FileSystemView/"
var View = preload("View.gd")

var fsview = preload("FileSystemView.tscn").instantiate()
var config_dialog = preload("ViewEditor.tscn").instantiate()

var interface: EditorInterface
var filesystem: EditorFileSystem
var editor_node : Node
var filesystem_dock : FileSystemDock
var filesystem_popup : PopupMenu
var filesystem_move_dialog: ConfirmationDialog
var tree : Tree

var views : Array
var config : Dictionary

func _enter_tree():
	interface = get_editor_interface()
	filesystem = interface.get_resource_filesystem()
	editor_node = interface.get_base_control().get_parent().get_parent()
	filesystem_dock = interface.get_file_system_dock()
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
	config_dialog.connect("closed", _on_ViewEditor_closed)
	interface.get_base_control().add_child(config_dialog)

	fsview.plugin = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, fsview)


func _exit_tree():
	remove_control_from_docks(fsview)
	fsview.queue_free()
	config_dialog.queue_free()


func load_views():
	var file = FileAccess.open(PLUGIN_DIR + "config.json", FileAccess.READ)
	if not file:
		file = FileAccess.open(PLUGIN_DIR + "defaultConfig.json", FileAccess.READ)
		assert(file, str(FileAccess.get_open_error()))
		print_debug("FileSystemView: load defaultConfig.json")
	
	var config = JSON.parse_string(file.get_as_text())
	assert(config is Dictionary)
	self.config = config
	self.views = self.config.views


func save_views():
	var data = JSON.stringify(config)
	var file = FileAccess.open(PLUGIN_DIR + "config.json", FileAccess.WRITE)
	assert(file, str(FileAccess.get_open_error()))
	file.store_string(data)
	file = null


func _on_ViewEditor_closed():
	save_views()


func fsd_open_file(file_path: String):
	filesystem_dock.call("_select_file", file_path, false)


func fsd_select_paths(paths: PackedStringArray):
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
	
	tree.multi_selected.emit(null, 0, true)
	tree.get_root().remove_child.call_deferred(temp_item)
	tree.queue_redraw.call_deferred()
 
