tool
extends Object

var plugin: EditorPlugin
var interface: EditorInterface
var filesystem: EditorFileSystem
var editor_node : Node
var filesystem_dock : Node

func _set_interface(plugin: EditorPlugin):
	self.plugin = plugin
	interface = plugin.get_editor_interface()
	filesystem = interface.get_resource_filesystem()
	editor_node = interface.get_base_control().get_parent().get_parent()
	filesystem_dock = interface.get_base_control().find_node("FileSystem", true, false)

func open_file(file_path: String):
## method EditorNode:load_resource is not bound, so use FileSystemDock
#	if filesystem.get_file_type(file_path) == "PackedScene":
#		editor_node.call("open_request", file_path)
#	else:
#		editor_node.call("load_resource", file_path) # invalid call
	filesystem_dock.call("_select_file", file_path, false)
