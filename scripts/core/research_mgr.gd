extends Node
## ResearchMgr autoload：研究树管理

signal tech_unlocked(tech_id: String)

var unlocked_techs: Array[String] = []

func unlock(tech_id: String) -> bool:
	if tech_id in unlocked_techs:
		return false
	var tech: Dictionary = ResearchData.get_tech(tech_id)
	if tech.is_empty():
		return false
	if not ResearchData.can_unlock(tech_id, unlocked_techs):
		GameState.alert_message.emit("前置条件未满足", Color(1.0, 0.5, 0.5))
		return false
	if GameState.research_points < tech["cost"]:
		GameState.alert_message.emit("RP 不足", Color(1.0, 0.5, 0.5))
		return false
	GameState.add_rp(-tech["cost"])
	unlocked_techs.append(tech_id)
	GameState.alert_message.emit("🔬 解锁技术：%s" % tech["name"], Color(0.5, 1.0, 0.7))
	tech_unlocked.emit(tech_id)
	return true

func has_tech(tech_id: String) -> bool:
	return tech_id in unlocked_techs

func get_difficulty_mult() -> float:
	if has_tech("ai_detect"):
		return 0.9
	return 1.0

func get_penalty_mult() -> float:
	if has_tech("zero_trust"):
		return 0.8
	return 1.0

func should_auto_block_low() -> bool:
	return has_tech("soar")

func get_severity_reduce() -> float:
	if has_tech("threat_hunt"):
		return 0.3
	return 0.0

func get_apt_difficulty_mult() -> float:
	if has_tech("apt_intel"):
		return 0.7
	return 1.0

func to_dict() -> Dictionary:
	return {"unlocked_techs": unlocked_techs}

func from_dict(d: Dictionary) -> void:
	unlocked_techs = d.get("unlocked_techs", [])
