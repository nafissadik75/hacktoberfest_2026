# scripts/visitor_data.gd
class_name VisitorData
extends RefCounted

var is_ghost: bool = false
var birth_date: String = ""
var portrait: Texture2D = null

var situation: String = ""
var clue: String = ""
var explanation: String = ""

var statement: String = ""
var fallback_statement: String = ""
var generated_by_ai : bool = false
