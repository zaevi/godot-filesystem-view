tool
extends EditorPlugin

var fsview
const FSVIEW_PATH = "res://addons/FileSystemView/FileSystemView.tscn"

func _enter_tree():
	fsview = preload(FSVIEW_PATH).instance()
	fsview.agent._set_interface(self)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, fsview)

func _exit_tree():
	remove_control_from_docks(fsview)
