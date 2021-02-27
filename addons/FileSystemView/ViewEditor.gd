tool
extends AcceptDialog

onready var edit_name: LineEdit = $HBox/Grid/Name
onready var edit_icon: LineEdit = $HBox/Grid/Icon
onready var edit_apply_include : CheckBox = $HBox/Grid/ApplyInclude
onready var edit_include: TextEdit = $HBox/Grid/Include
onready var edit_apply_exclude : CheckBox = $HBox/Grid/ApplyExclude
onready var edit_exclude: TextEdit = $HBox/Grid/Exclude
onready var edit_hide_dir: CheckBox = $HBox/HideFolder
onready var option_btn: OptionButton = $HBox/HBox/Option

signal closed

var plugin

var views : Array
var current_view

func _init():
	connect("popup_hide", self, "_on_ViewEditor_closed")


func _ready():
	if not plugin:
		return
	
	views = plugin.views
	update_view_list()
	
	$HBox/HBox/Add.icon = get_icon("Add", "EditorIcons")
	$HBox/HBox/Delete.icon = get_icon("Remove", "EditorIcons")


func update_view_list():
	var popup = option_btn.get_popup()
	popup.clear()
	var id = 0
	for view in views:
		popup.add_item(view.name, id)
		if view.icon != "" and has_icon(view.icon, "EditorIcons"):
			popup.set_item_icon(id, get_icon(view.icon, "EditorIcons"))
		id += 1


func load_view(idx: int):
	option_btn.select(idx)
	var view = views[idx]
	
	edit_name.text				= view.name
	edit_icon.text				= view.icon
	edit_apply_include.pressed	= view.apply_include
	edit_include.text			= view.include
	edit_apply_exclude.pressed	= view.apply_exclude
	edit_exclude.text			= view.exclude
	edit_hide_dir.pressed 		= view.hide_empty_dirs
	
	_on_Icon_text_changed(view.icon)
	current_view = view


func save_current():
	current_view.name				= edit_name.text
	current_view.icon				= edit_icon.text
	current_view.apply_include		= edit_apply_include.pressed
	current_view.include			= edit_include.text
	current_view.apply_exclude		= edit_apply_exclude.pressed
	current_view.exclude			= edit_exclude.text
	current_view.hide_empty_dirs	= edit_hide_dir.pressed


func _on_Add_pressed():
	save_current()
	
	var view = plugin.config.defaultView.duplicate()
	views.append(view)
	
	update_view_list()
	var id = views.size() - 1
	load_view(id)


func _on_Delete_pressed():
	var id = option_btn.selected
	views.remove(id)
	update_view_list()
	if views.size() <= id:
		id -= 1
	load_view(id)


func _on_Option_item_selected(id):
	save_current()
	update_view_list()
	load_view(id)


func _on_Icon_text_changed(new_text):
	if has_icon(new_text, "EditorIcons"):
		edit_icon.right_icon = get_icon(new_text, "EditorIcons")
	else:
		edit_icon.right_icon = null


func _on_ViewEditor_closed():
	save_current()
	update_view_list()
	emit_signal("closed")
