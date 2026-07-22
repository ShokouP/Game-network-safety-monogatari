class_name Connection
extends RefCounted

## 人脉 - 员工与外部角色的关系

enum ConnectionType { HEADHUNTER, EXPERT, VENDOR, COMMUNITY, REGULATOR }

var id: int
var name: String
var type: ConnectionType
var relation: int = 0  # 0-100，关系值
var specialty_bonus: String = ""  # 擅长领域（影响招聘质量）
var avatar_id: int = 0

func get_type_name() -> String:
	match type:
		ConnectionType.HEADHUNTER: return "猎头"
		ConnectionType.EXPERT: return "安全专家"
		ConnectionType.VENDOR: return "供应商"
		ConnectionType.COMMUNITY: return "技术社区"
		ConnectionType.REGULATOR: return "监管机构"
	return "?"

func get_relation_level() -> String:
	if relation >= 80: return "莫逆之交"
	elif relation >= 60: return "好友"
	elif relation >= 40: return "熟悉"
	elif relation >= 20: return "认识"
	else: return "陌生"

func to_dict() -> Dictionary:
	return {"id": id, "name": name, "type": type, "relation": relation, "specialty_bonus": specialty_bonus, "avatar_id": avatar_id}

static func from_dict(d: Dictionary) -> Connection:
	var c := Connection.new()
	c.id = d.get("id", 0)
	c.name = d.get("name", "")
	c.type = d.get("type", ConnectionType.HEADHUNTER)
	c.relation = d.get("relation", 0)
	c.specialty_bonus = d.get("specialty_bonus", "")
	c.avatar_id = d.get("avatar_id", 0)
	return c
