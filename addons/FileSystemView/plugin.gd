tool
extends EditorPlugin

var agent = preload("EditorAgent.gd").new(self)
var fsview = preload("FileSystemView.tscn").instance()

func _enter_tree():
	fsview.agent = agent
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, fsview)


func _exit_tree():
	remove_control_from_docks(fsview)
	fsview.queue_free()
