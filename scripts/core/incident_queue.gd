extends Node
## IncidentQueue autoload：事件队列 + 处置逻辑 + 选择树

signal incident_spawned(inc: Incident)
signal incident_resolved(inc: Incident, success: bool)
signal incident_progressed(inc: Incident)
signal choice_required(inc: Incident, node: IncidentChoiceNode)

var active_incidents: Array[Incident] = []
var total_blocked: int = 0
var total_breached: int = 0

# 记录年度数据（奖项用）
var year_blocked: int = 0
var year_breached: int = 0
var year_response_time_sum: int = 0  # 累计消耗天数

func reset() -> void:
	active_incidents.clear()
	total_blocked = 0
	total_breached = 0
	reset_year_stats()

func reset_year_stats() -> void:
	year_blocked = 0
	year_breached = 0
	year_response_time_sum = 0

func spawn(inc: Incident) -> void:
	inc.initial_days = inc.days_remaining
	active_incidents.append(inc)
	incident_spawned.emit(inc)
	# 触发时暂停时间，弹独立窗口
	GameState.set_speed(0)
	GameState.alert_message.emit("🚨 新安全事件：%s" % inc.name, inc.get_severity_color())

func assign(inc: Incident, emp_id: int) -> void:
	# 专班任务不允许中途换人（除非已解决）
	if inc.is_special_team and inc.special_team_days > 0 and inc.assigned_employee_id != emp_id and inc.assigned_employee_id > 0:
		GameState.alert_message.emit("⚠️ 专班任务不可中途换人！", Color(1.0, 0.5, 0.5))
		return
	inc.assigned_employee_id = emp_id
	if inc.status == Incident.Status.ACTIVE:
		inc.status = Incident.Status.IN_PROGRESS

func tick_day() -> void:
	## 每日推进：进度、倒计时、培训
	var resolved: Array[Incident] = []
	for inc in active_incidents.duplicate():
		if inc.status == Incident.Status.AWAITING_CHOICE:
			continue
		if inc.status == Incident.Status.IN_PROGRESS and inc.assigned_employee_id >= 0:
			var emp := EmployeeRoster.get_by_id(inc.assigned_employee_id)
			if emp and not emp.is_training:
				var gain := _compute_progress_gain(emp, inc)
				inc.progress += gain
				var fatigue_cost := 6
				# 蓝队被动：疲劳减少
				var passive := emp.get_career_passive_bonus()
				if passive.has("fatigue_reduce"):
					fatigue_cost = int(fatigue_cost * (1.0 - passive["fatigue_reduce"]))
				emp.add_fatigue(fatigue_cost)
				if emp.add_exp(2):
					pass
				# 专班天数累计
				if inc.is_special_team:
					inc.special_team_days += 1
					# 专班 3 天额外奖励
					if inc.special_team_days == 3:
						GameState.add_rp(15)
						emp.add_exp(30)
						GameState.alert_message.emit("🔥 %s 连续处置 3 天，专班奖励 +15RP +30EXP" % emp.name, Color(1.0, 0.85, 0.3))
				incident_progressed.emit(inc)
				# 50% 进度时触发中段选择（如果有）
				if inc.progress >= 50.0 and not inc.mid_choice_triggered:
					var tree = GameData.CHOICE_TREES.get(inc.type_id)
					if tree and tree.has("mid"):
						inc.mid_choice_triggered = true
						inc.status = Incident.Status.AWAITING_CHOICE
						inc.current_choice_node_id = "mid"
						var node := _build_choice_node(inc.type_id, "mid")
						if node:
							choice_required.emit(inc, node)
							continue
		inc.days_remaining -= 1
		if inc.progress >= 100.0:
			# 完成时触发结束选择（如果有）
			var tree = GameData.CHOICE_TREES.get(inc.type_id)
			if tree and tree.has("final") and not inc.choices_made.has("final"):
				inc.status = Incident.Status.AWAITING_CHOICE
				inc.current_choice_node_id = "final"
				var node := _build_choice_node(inc.type_id, "final")
				if node:
					choice_required.emit(inc, node)
					continue
			resolved.append(inc)
			_resolve(inc, true)
		elif inc.days_remaining <= 0:
			resolved.append(inc)
			_resolve(inc, false)
	for inc in resolved:
		active_incidents.erase(inc)

func _build_choice_node(type_id: String, node_id: String) -> IncidentChoiceNode:
	var tree = GameData.CHOICE_TREES.get(type_id)
	if tree == null or not tree.has(node_id):
		return null
	return IncidentChoiceNode.from_dict(tree[node_id])

func apply_choice(inc: Incident, option: Dictionary) -> void:
	inc.choices_made.append(inc.current_choice_node_id)
	var effects: Dictionary = option.get("effects", {})
	if effects.has("funds"):
		GameState.add_funds(effects["funds"])
	if effects.has("rep"):
		GameState.add_rep(effects["rep"])
	if effects.has("progress"):
		inc.progress = clampf(inc.progress + effects["progress"], 0.0, 100.0)
	if effects.has("exp") and inc.assigned_employee_id >= 0:
		var emp := EmployeeRoster.get_by_id(inc.assigned_employee_id)
		if emp:
			emp.add_exp(effects["exp"])
	if effects.has("difficulty_delta"):
		inc.difficulty = max(5, inc.difficulty + effects["difficulty_delta"])
	if effects.has("days_delta"):
		inc.days_remaining = max(0, inc.days_remaining + effects["days_delta"])
	inc.current_choice_node_id = ""
	# 恢复到 IN_PROGRESS 或检查是否完成
	if inc.progress >= 100.0:
		active_incidents.erase(inc)
		_resolve(inc, true)
	else:
		inc.status = Incident.Status.IN_PROGRESS

func _resolve(inc: Incident, success: bool) -> void:
	var emp := EmployeeRoster.get_by_id(inc.assigned_employee_id)
	var days_used: int = inc.initial_days - inc.days_remaining
	if success:
		inc.status = Incident.Status.RESOLVED_SUCCESS
		total_blocked += 1
		year_blocked += 1
		year_response_time_sum += days_used
		if emp:
			emp.stat_blocked += 1
			var exp_gain := int(inc.exp_reward * GameState.get_combo_incident_exp_mult())
			# 红队被动：经验加成
			var passive := emp.get_career_passive_bonus()
			if passive.has("exp_mult"):
				exp_gain = int(exp_gain * passive["exp_mult"])
			emp.add_exp(exp_gain)
			# 紫队被动：额外 RP
			if passive.has("rp_per_incident"):
				GameState.add_rp(passive["rp_per_incident"])
		GameState.add_rep(inc.rep_reward)
		GameState.add_funds(inc.fund_reward)
		GameState.add_rp(1 + int(inc.difficulty / 25))
	else:
		inc.status = Incident.Status.RESOLVED_FAIL
		total_breached += 1
		year_breached += 1
		if emp:
			emp.stat_breached += 1
		var pr_reduction := GameState.get_pr_penalty_reduction()
		GameState.add_rep(-int(inc.rep_penalty * pr_reduction))
		GameState.add_funds(-inc.fund_penalty)
	incident_resolved.emit(inc, success)

func _compute_progress_gain(emp: Employee, inc: Incident) -> float:
	var skill_val: int = emp.get(inc.required_skill)
	var eff := emp.get_efficiency()
	var difficulty := inc.difficulty
	difficulty = int(difficulty * GameState.get_forensics_difficulty_reduction())
	difficulty = int(difficulty * GameState.get_combo_difficulty_mult())
	difficulty = int(difficulty * GameState.difficulty_modifier)
	# 红队被动：难度感知降低
	var passive := emp.get_career_passive_bonus()
	if passive.has("difficulty_perception"):
		difficulty = int(difficulty * (1.0 + passive["difficulty_perception"]))
	var ratio: float = float(skill_val) / max(1.0, float(difficulty))
	var gain: float = 20.0 + (ratio - 1.0) * 30.0
	gain *= eff
	# 蓝队被动：进度加成
	if passive.has("progress_mult"):
		gain *= passive["progress_mult"]
	return clampf(gain, 5.0, 80.0)

func get_year_avg_response_days() -> float:
	if year_blocked == 0:
		return 0.0
	return float(year_response_time_sum) / year_blocked

# ---------- 序列化 ----------

func to_dict() -> Dictionary:
	return {
		"total_blocked": total_blocked,
		"total_breached": total_breached,
		"year_blocked": year_blocked,
		"year_breached": year_breached,
		"year_response_time_sum": year_response_time_sum,
		"active_incidents": active_incidents.map(func(i): return i.to_dict()),
	}

func from_dict(d: Dictionary) -> void:
	total_blocked = d.get("total_blocked", 0)
	total_breached = d.get("total_breached", 0)
	year_blocked = d.get("year_blocked", 0)
	year_breached = d.get("year_breached", 0)
	year_response_time_sum = d.get("year_response_time_sum", 0)
	active_incidents.clear()
	for i_data in d.get("active_incidents", []):
		active_incidents.append(Incident.from_dict(i_data))
