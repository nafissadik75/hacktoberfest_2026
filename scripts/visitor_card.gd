class_name VisitorCard
extends PanelContainer

@export var portrait_rect: TextureRect
@export var birth_date_label: Control
@export var statement_label: Control


func show_visitor(visitor: VisitorData) -> void:
	if portrait_rect != null:
		portrait_rect.texture = visitor.portrait

	_set_text(birth_date_label, "Birth date: " + visitor.birth_date)
	_set_text(statement_label, visitor.statement)


func _set_text(target: Control, value: String) -> void:
	if target is Label:
		target.text = value
	elif target is RichTextLabel:
		target.text = value
