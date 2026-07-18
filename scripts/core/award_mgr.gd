extends Node
## AwardMgr autoload：年度奖项评比 + 颁奖典礼数据

signal award_ceremony_started(year: int, results: Dictionary)
signal award_ceremony_finished(year: int)

# 4 个奖项维度
const AWARD_DEFENSE := "defense"     # 防御 - 拦截率
const AWARD_TRAINING := "training"   # 培训 - 人均技能增长
const AWARD_RESPONSE := "response"   # 响应 - 平均处置天数
const AWARD_RESEARCH := "research"   # 研究 - 累计研究点

# 5 家虚拟对手公司
const RIVAL_COMPANIES := [
	{"name": "盾安科技", "skill": 0.6},
	{"name": "防泄漏实验室", "skill": 0.7},
	{"name": "零信任防务", "skill": 0.8},
	{"name": "哨兵安全", "skill": 0.9},
	{"name": "堡垒网络", "skill": 1.0},
]

# 历史
var award_history: Array = []
var monthly_rankings: Array = []  # 本月排名（每月刷新）

func _ready() -> void:
	if GameState:
		GameState.year_ended.connect(_on_year_ended)
		GameState.date_changed.connect(_on_date_changed)

func _on_date_changed(_y: int, _m: int, d: int) -> void:
	# 每月 1 号刷新月度排名
	if d == 1:
		refresh_monthly_rankings()

func refresh_monthly_rankings() -> void:
	## 简化版月度评分：基于玩家声誉 + 随机扰动
	monthly_rankings.clear()
	var player_score := float(GameState.reputation) + GameState.rng.randf_range(-5, 5)
	monthly_rankings.append({"name": "我们公司", "score": player_score, "is_player": true})
	for rival in RIVAL_COMPANIES:
		var base: float = rival["skill"] * 80.0
		monthly_rankings.append({
			"name": rival["name"],
			"score": clampf(base + GameState.rng.randf_range(-15, 15), 0, 100),
			"is_player": false,
		})
	monthly_rankings.sort_custom(func(a, b): return a["score"] > b["score"])

func reset() -> void:
	award_history.clear()

func _on_year_ended(year: int) -> void:
	var results := evaluate_year(year)
	award_history.append(results)
	award_ceremony_started.emit(year, results)
	# 发奖
	var total_score: float = results["player_total_score"]
	if total_score >= 80.0:
		GameState.add_funds(20000)
		GameState.add_rep(15)
	elif total_score >= 60.0:
		GameState.add_funds(10000)
		GameState.add_rep(8)
	elif total_score >= 40.0:
		GameState.add_funds(5000)
		GameState.add_rep(3)
	award_ceremony_finished.emit(year)

func evaluate_year(year: int) -> Dictionary:
	## 评估玩家本年度表现 + 与对手比较
	var player := _evaluate_player()
	var rivals := []
	for rival in RIVAL_COMPANIES:
		rivals.append(_evaluate_rival(rival))
	# 4 个维度排名
	var rankings := {}
	for cat in [AWARD_DEFENSE, AWARD_TRAINING, AWARD_RESPONSE, AWARD_RESEARCH]:
		var entries := [{"name": "我们公司", "score": player[cat], "is_player": true}]
		for r in rivals:
			entries.append({"name": r["name"], "score": r[cat], "is_player": false})
		entries.sort_custom(func(a, b): return a["score"] > b["score"])
		rankings[cat] = entries
	# 总分
	var player_total: float = player["defense"] + player["training"] + player["response"] + player["research"]
	var rival_totals := []
	for r in rivals:
		rival_totals.append({"name": r["name"], "total": r["defense"] + r["training"] + r["response"] + r["research"]})
	return {
		"year": year,
		"player": player,
		"player_total_score": player_total,
		"rivals": rivals,
		"rival_totals": rival_totals,
		"rankings": rankings,
	}

func _evaluate_player() -> Dictionary:
	# 防御：拦截率（0-100）
	var total := IncidentQueue.year_blocked + IncidentQueue.year_breached
	var defense := 50.0
	if total > 0:
		defense = 100.0 * IncidentQueue.year_blocked / total
	# 培训：人均技能增长（0-100，粗略按培训次数 + 员工平均等级）
	var emp_count: int = max(1, EmployeeRoster.employees.size())
	var avg_level := 0.0
	var total_trains := 0
	for e in EmployeeRoster.employees:
		avg_level += e.level
		total_trains += e.stat_trainings_done
	avg_level /= emp_count
	var training: float = clampf(avg_level * 3.0 + total_trains * 2.0, 0.0, 100.0)
	# 响应：平均处置天数越短越好（>5天 0 分，0天 100 分）
	var avg_days := IncidentQueue.get_year_avg_response_days()
	var response: float = clampf(100.0 - avg_days * 15.0, 0.0, 100.0)
	# 研究：研究点累计
	var research: float = clampf(GameState.research_points * 2.0, 0.0, 100.0)
	return {
		"defense": defense,
		"training": training,
		"response": response,
		"research": research,
	}

func _evaluate_rival(rival: Dictionary) -> Dictionary:
	## 根据对手 skill 生成合理分数
	var base: float = rival["skill"] * 100.0
	var noise := GameState.rng.randf_range(-15.0, 15.0)
	return {
		"name": rival["name"],
		"defense": clampf(base + GameState.rng.randf_range(-10, 10), 0, 100),
		"training": clampf(base + GameState.rng.randf_range(-10, 10), 0, 100),
		"response": clampf(base + GameState.rng.randf_range(-10, 10), 0, 100),
		"research": clampf(base + GameState.rng.randf_range(-10, 10), 0, 100),
	}

func get_player_rank_in_category(results: Dictionary, cat: String) -> int:
	var entries: Array = results["rankings"][cat]
	for i in range(entries.size()):
		if entries[i]["is_player"]:
			return i + 1
	return 6

func get_overall_rank(results: Dictionary) -> int:
	## 总排名
	var totals := [{"name": "我们公司", "total": results["player_total_score"], "is_player": true}]
	for r in results["rival_totals"]:
		totals.append({"name": r["name"], "total": r["total"], "is_player": false})
	totals.sort_custom(func(a, b): return a["total"] > b["total"])
	for i in range(totals.size()):
		if totals[i]["is_player"]:
			return i + 1
	return 6

# ---------- 序列化 ----------

func to_dict() -> Dictionary:
	return {"award_history": award_history, "monthly_rankings": monthly_rankings}

func from_dict(d: Dictionary) -> void:
	award_history = d.get("award_history", [])
	monthly_rankings = d.get("monthly_rankings", [])
