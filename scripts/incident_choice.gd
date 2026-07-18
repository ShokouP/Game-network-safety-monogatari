class_name IncidentChoiceNode
extends RefCounted

## 选择树节点

var id: String
var title: String
var description: String
# 选项：[{ text, hint, requirements: {skill, min_value, min_level}, effects: {funds, rep, exp, progress, escalate_to, next_node} }]
var options: Array = []

func to_dict() -> Dictionary:
	return {"id": id, "title": title, "description": description, "options": options}

static func from_dict(d: Dictionary) -> IncidentChoiceNode:
	var n := IncidentChoiceNode.new()
	n.id = d.get("id", "")
	n.title = d.get("title", "")
	n.description = d.get("description", "")
	n.options = d.get("options", [])
	return n
