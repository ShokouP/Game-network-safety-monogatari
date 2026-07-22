class_name ResearchData
extends RefCounted
## 研究树

const TECHS := {
	"ai_detect": {
		"name": "AI 威胁检测",
		"desc": "事件难度 -10%",
		"cost": 50,
		"prereq": [],
		"effect": {"difficulty_mult": 0.9},
	},
	"zero_trust": {
		"name": "零信任架构",
		"desc": "事件失败惩罚 -20%",
		"cost": 80,
		"prereq": ["ai_detect"],
		"effect": {"penalty_mult": 0.8},
	},
	"soar": {
		"name": "SOAR 自动化",
		"desc": "每日自动拦截 1 起低危事件",
		"cost": 120,
		"prereq": ["zero_trust"],
		"effect": {"auto_block_low": true},
	},
	"threat_hunt": {
		"name": "威胁狩猎",
		"desc": "严重事件概率 -30%",
		"cost": 100,
		"prereq": ["ai_detect"],
		"effect": {"severity_reduce": 0.3},
	},
	"apt_intel": {
		"name": "APT 情报网",
		"desc": "APT 事件难度 -30%",
		"cost": 150,
		"prereq": ["threat_hunt"],
		"effect": {"apt_difficulty_mult": 0.7},
	},
}

static func get_tech(tech_id: String) -> Dictionary:
	return TECHS.get(tech_id, {})

static func can_unlock(tech_id: String, unlocked: Array) -> bool:
	var tech: Dictionary = TECHS.get(tech_id, {})
	if tech.is_empty():
		return false
	for prereq in tech.get("prereq", []):
		if prereq not in unlocked:
			return false
	return true
