extends Node
## CEOMgr：季度 CEO 评价 + 预算谈判

signal ceo_review_started(review: Dictionary)
signal budget_negotiation_started(offer: Dictionary)

# 季度评价（每 3 个月一次）
var last_review_quarter: int = -1

func _ready() -> void:
	GameState.date_changed.connect(_on_date_changed)

func _on_date_changed(y: int, m: int, _d: int) -> void:
	var quarter: int = (m - 1) / 3  # 0-3
	var quarter_abs: int = y * 4 + quarter
	# 每季度第 1 天触发
	if _d == 1 and quarter_abs != last_review_quarter:
		last_review_quarter = quarter_abs
		var review := evaluate_quarter()
		ceo_review_started.emit(review)
		# 预算谈判（仅好评时）
		if review["grade"] >= 2:  # B 级以上
			var offer := generate_budget_offer(review)
			budget_negotiation_started.emit(offer)

func evaluate_quarter() -> Dictionary:
	## 评估季度表现
	# 评分维度：拦截率（60%）+ 资金健康度（30%）+ 员工稳定（10%）
	var total := IncidentQueue.year_blocked + IncidentQueue.year_breached
	var block_rate := 1.0
	if total > 0:
		block_rate = float(IncidentQueue.year_blocked) / total
	var funds_score := clampf(GameState.funds / 100000.0, 0.0, 1.0)
	var emp_stability := clampf(EmployeeRoster.employees.size() / 12.0, 0.0, 1.0)
	var overall := block_rate * 0.6 + funds_score * 0.3 + emp_stability * 0.1
	# 评级：S A B C D
	var grade := 0
	var grade_name := "D"
	if overall >= 0.9:
		grade = 4; grade_name = "S"
	elif overall >= 0.75:
		grade = 3; grade_name = "A"
	elif overall >= 0.6:
		grade = 2; grade_name = "B"
	elif overall >= 0.4:
		grade = 1; grade_name = "C"
	var comment := _generate_comment(grade_name, overall)
	return {
		"grade": grade,
		"grade_name": grade_name,
		"overall": overall,
		"block_rate": block_rate,
		"funds_score": funds_score,
		"emp_stability": emp_stability,
		"comment": comment,
	}

func _generate_comment(grade_name: String, overall: float) -> String:
	match grade_name:
		"S": return "CEO 高度赞扬：安全部门是公司的定海神针！"
		"A": return "CEO 满意：本季度安全表现优异。"
		"B": return "CEO 认可：继续保持。"
		"C": return "CEO 提醒：安全形势严峻，需要加强。"
		"D": return "CEO 警告：再出事故就换人了！"
	return ""

func generate_budget_offer(review: Dictionary) -> Dictionary:
	## 根据评级生成预算谈判选项
	var grade: int = review["grade"]
	# 三选一：安全保守 / 中庸 / 激进
	var base := 5000 + grade * 3000
	return {
		"grade_name": review["grade_name"],
		"options": [
			{"name": "稳健型", "desc": "拿固定预算，无风险", "funds": base, "rep": 1},
			{"name": "平衡型", "desc": "预算 + 声誉", "funds": int(base * 0.7), "rep": 3},
			{"name": "激进型", "desc": "高预算，但下季度需证明价值（下季度拦截率需 ≥70%）", "funds": int(base * 1.5), "rep": 0, "risk": true},
		],
	}

func apply_budget_choice(option: Dictionary) -> void:
	GameState.add_funds(option.get("funds", 0))
	GameState.add_rep(option.get("rep", 0))
	if option.get("risk", false):
		# TODO: 下季度拦截率追踪（暂时只是提示）
		GameState.alert_message.emit("⚠️ 你承诺了下季度拦截率 ≥70%，CEO 会盯着", Color(1.0, 0.7, 0.3))
