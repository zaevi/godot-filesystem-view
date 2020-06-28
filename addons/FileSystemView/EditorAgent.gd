tool
extends Object

var plugin: EditorPlugin
var interface: EditorInterface
var filesystem: EditorFileSystem
var editor_node : Node
var filesystem_dock : Node
var rmb_popup
var tree : Tree

func _set_interface(plugin: EditorPlugin):
	self.plugin = plugin
	interface = plugin.get_editor_interface()
	filesystem = interface.get_resource_filesystem()
	editor_node = interface.get_base_control().get_parent().get_parent()
	filesystem_dock = interface.get_base_control().find_node("FileSystem", true, false)
	for i in filesystem_dock.get_children():
		if i is VSplitContainer:
			tree = i.get_child(0)
			break


func open_file(file_path: String):
## method EditorNode:load_resource is not bound, so use FileSystemDock
#	if filesystem.get_file_type(file_path) == "PackedScene":
#		editor_node.call("open_request", file_path)
#	else:
#		editor_node.call("load_resource", file_path) # invalid call
	filesystem_dock.call("_select_file", file_path, false)

func _locate_item(root: TreeItem, path: String):
	var item : TreeItem = root.get_children()
	while item:
		var item_path : String = item.get_metadata(0)
		if path == item_path:
			return item
		elif path.begins_with(item_path):
			return _locate_item(item, path)
		item = item.get_next()
	print("can't find treepath ", path)
	return null

func locate_item(path: String) -> TreeItem:
	var res_root = tree.get_root().get_children().get_next()
	return _locate_item(res_root, path)

func select_item(path: String):
	var item = locate_item(path)
	
	# easier way to unselect all
	tree.select_mode = Tree.SELECT_SINGLE
	item.select(0)
	tree.select_mode = Tree.SELECT_MULTI
