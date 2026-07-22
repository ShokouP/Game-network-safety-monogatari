class_name Client
extends RefCounted

## 客户 - 外部安全咨询单

var id: int
var name: String
var company: String
var task_type: String  # pentest / audit / training / incident_response
var difficulty: int = 20
var reward_funds: int = 5000
var reward_rep: int = 2
var days_left: int = 7
var assigned_emp_id: int = -1
var progress: float = 0.0
var is_done: bool = false

func get_type_name() -> String:
	match task_type:
		"pentest": return "渗透测试"
		"audit": return "安全审计"
		"training": return "企业培训"
		"incident_response": return "应急响应"
	return "?"

func to_dict() -> Dictionary:
	return {"id": id, "name": name, "company": company, "task_type": task_type, "difficulty": difficulty, "reward_funds": reward_funds, "reward_rep": reward_rep, "days_left": days_left, "assigned_emp_id": assigned_emp_id, "progress": progress, "is_done": is_done}

static func from_dict(d: Dictionary) -> Client:
	var c := Client.new()
	c.id = d.get("id", 0)
	c.name = d.get("name", "")
	c.company = d.get("company", "")
	c.task_type = d.get("task_type", "pentest")
	c.difficulty = d.get("difficulty", 20)
	c.reward_funds = d.get("reward_funds", 5000)
	c.reward_rep = d.get("reward_rep", 2)
	c.days_left = d.get("days_left", 7)
	c.assigned_emp_id = d.get("assigned_emp_id", -1)
	c.progress = d.get("progress", 0.0)
	c.is_done = d.get("is_done", false)
	return c
