extends Reference

var name : String = ""
var icon : String = ""
var include: String = "" setget _set_include
var exclude: String = "" setget _set_exclude
var hide_empty_dirs: bool = true
var apply_include: bool = true
var apply_exclude: bool

var _includes = []
var _excludes = []

func _set_include(value):
	include = value
	_includes = _split_patterns(value)

func _set_exclude(value):
	exclude = value
	_excludes = _split_patterns(value)

func _split_patterns(pattern: String):
	var patterns = []
	if pattern == "":
		return patterns
	for p in pattern.split(";", false):
		if not p.begins_with("res://"):
			p = "res://" + p
		patterns.append(p)
	return patterns

func _any_match(patterns: Array, path: String) -> bool:
	for pattern in patterns:
		if path.matchn(pattern):
			return true
	return false

func is_match(path: String) -> bool:
	if apply_include and _includes.size() > 0 and not _any_match(_includes, path):
		return false
	if apply_exclude and _excludes.size() > 0 and _any_match(_excludes, path):
		return false
	return true
