class_name Incident
extends RefCounted

## 安全事件（v2：状态机 + 选择树钩子 + 派遣员工列表）

enum Severity { LOW, MEDIUM, HIGH, CRITICAL }
enum Status {
	ACTIVE,             # 刚出现，等待分配
	IN_PROGRESS,        # 已分配，处置中
	AWAITING_CHOICE,    # 触发分支选择，暂停倒计时
	RESOLVED_SUCCESS,
	RESOLVED_FAIL,
	ESCALATED,          # 恶化升级
}

var id: int
var type_id: String
var name: String
var description: String
var severity: Severity
var status: Status = Status.ACTIVE

var required_skill: String = "skill_detect"
var difficulty: int = 20
var days_remaining: int = 3
var initial_days: int = 3  # 用于计算"消耗天数"

var rep_reward: int = 3
var rep_penalty: int = 5
var fund_reward: int = 2000
var fund_penalty: int = 5000
var exp_reward: int = 30

var assigned_employee_id: int = -1
var progress: float = 0.0

# 选择树相关
var current_choice_node_id: String = ""  # 若为空表示未触发选择
var choices_made: Array[String] = []     # 已做过的选择节点 id 历史
var mid_choice_triggered: bool = false   # 50% 进度选择是否已触发

# 专班（严重事件要求同一员工连续处置）
var is_special_team: bool = false
var special_team_days: int = 0  # 已连续处置天数

func is_active() -> bool:
	return status == Status.ACTIVE or status == Status.IN_PROGRESS or status == Status.AWAITING_CHOICE

func is_resolved() -> bool:
	return status == Status.RESOLVED_SUCCESS or status == Status.RESOLVED_FAIL

func get_severity_name() -> String:
	match severity:
		Severity.LOW: return "低危"
		Severity.MEDIUM: return "中危"
		Severity.HIGH: return "高危"
		Severity.CRITICAL: return "严重"
	return "?"

func get_severity_color() -> Color:
	match severity:
		Severity.LOW: return Color(0.5, 0.8, 1.0)
		Severity.MEDIUM: return Color(1.0, 0.85, 0.3)
		Severity.HIGH: return Color(1.0, 0.5, 0.2)
		Severity.CRITICAL: return Color(1.0, 0.2, 0.3)
	return Color.WHITE

func get_status_name() -> String:
	match status:
		Status.ACTIVE: return "待分配"
		Status.IN_PROGRESS: return "处置中"
		Status.AWAITING_CHOICE: return "需决策"
		Status.RESOLVED_SUCCESS: return "已解决"
		Status.RESOLVED_FAIL: return "已失败"
		Status.ESCALATED: return "已升级"
	return "?"

func to_dict() -> Dictionary:
	return {
		"id": id, "type_id": type_id, "name": name, "description": description,
		"severity": severity, "status": status,
		"required_skill": required_skill, "difficulty": difficulty,
		"days_remaining": days_remaining, "initial_days": initial_days,
		"rep_reward": rep_reward, "rep_penalty": rep_penalty,
		"fund_reward": fund_reward, "fund_penalty": fund_penalty,
		"exp_reward": exp_reward,
		"assigned_employee_id": assigned_employee_id,
		"progress": progress,
		"current_choice_node_id": current_choice_node_id,
		"choices_made": choices_made,
		"mid_choice_triggered": mid_choice_triggered,
		"is_special_team": is_special_team,
		"special_team_days": special_team_days,
	}

static func from_dict(d: Dictionary) -> Incident:
	var i := Incident.new()
	i.id = d.get("id", 0)
	i.type_id = d.get("type_id", "")
	i.name = d.get("name", "")
	i.description = d.get("description", "")
	i.severity = d.get("severity", Severity.LOW)
	i.status = d.get("status", Status.ACTIVE)
	i.required_skill = d.get("required_skill", "skill_detect")
	i.difficulty = d.get("difficulty", 20)
	i.days_remaining = d.get("days_remaining", 3)
	i.initial_days = d.get("initial_days", 3)
	i.rep_reward = d.get("rep_reward", 3)
	i.rep_penalty = d.get("rep_penalty", 5)
	i.fund_reward = d.get("fund_reward", 2000)
	i.fund_penalty = d.get("fund_penalty", 5000)
	i.exp_reward = d.get("exp_reward", 30)
	i.assigned_employee_id = d.get("assigned_employee_id", -1)
	i.progress = d.get("progress", 0.0)
	i.current_choice_node_id = d.get("current_choice_node_id", "")
	var cm = d.get("choices_made", [])
	i.choices_made.assign(cm)
	i.mid_choice_triggered = d.get("mid_choice_triggered", false)
	i.is_special_team = d.get("is_special_team", false)
	i.special_team_days = d.get("special_team_days", 0)
	return i
