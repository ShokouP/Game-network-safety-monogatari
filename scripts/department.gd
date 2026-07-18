class_name Department
extends RefCounted

## 部门 - 可升级的职能单元

var id: String
var level: int = 0  # 0=未建设

func to_dict() -> Dictionary:
	return {"id": id, "level": level}

static func from_dict(d: Dictionary) -> Department:
	var dept := Department.new()
	dept.id = d.get("id", "")
	dept.level = d.get("level", 0)
	return dept
