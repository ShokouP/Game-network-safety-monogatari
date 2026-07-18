extends Node
## 主游戏循环：按速度推进日期，分发 tick 给 IncidentQueue 等
## 挂在主场景下

var day_timer: float = 0.0
var next_incident_check_day: int = 2

func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
	if GameState.speed == 0:
		return
	var day_seconds: float = GameState.DAY_SECONDS[GameState.speed]
	day_timer += delta
	if day_timer >= day_seconds:
		day_timer -= day_seconds
		_tick_one_day()

func _tick_one_day() -> void:
	# 1. 推进员工培训
	for emp in EmployeeRoster.employees:
		if emp.is_training:
			var done := emp.advance_training()
			if done:
				_apply_training_result(emp)
			else:
				pass
	# 2. 推进事件（进度 + 倒计时 + 触发选择）
	IncidentQueue.tick_day()
	# 3. 员工疲劳恢复 + 在职天数累计
	var lounge_recovery := GameState.get_lounge_recovery()
	for emp in EmployeeRoster.employees:
		emp.recover_fatigue(lounge_recovery)
		emp.stat_days_employed += 1
	# 4. 推进日期
	GameState.advance_day()
	# 5. 事件生成判定
	_maybe_spawn_incident()
	# 5.5 彩蛋事件判定（每月 1-2 条）
	_maybe_spawn_flavor_event()
	# 6. 月初自动保存
	if GameState.day == 1:
		SaveMgr.auto_save()

var last_flavor_month: int = 0
var flavor_count_this_month: int = 0

func _maybe_spawn_flavor_event() -> void:
	## 每月随机 1-2 条彩蛋事件
	var current_month_abs: int = GameState.year * 12 + GameState.month
	if current_month_abs != last_flavor_month:
		last_flavor_month = current_month_abs
		flavor_count_this_month = 0
	if flavor_count_this_month >= 2:
		return
	if GameState.day < 5:
		return  # 月初缓一缓
	# 每天 4% 概率触发
	if GameState.rng.randf() > 0.04:
		return
	# 按权重选
	var candidates: Array = []
	var total_weight := 0
	for ev in GameData.FLAVOR_EVENTS:
		if GameState.year >= ev.get("min_year", 1):
			candidates.append(ev)
			total_weight += ev.get("weight", 5)
	if candidates.is_empty():
		return
	var roll := GameState.rng.randi_range(1, total_weight)
	var cumulative := 0
	var chosen: Dictionary = candidates[0]
	for ev in candidates:
		cumulative += ev.get("weight", 5)
		if roll <= cumulative:
			chosen = ev
			break
	_apply_flavor_event(chosen)
	flavor_count_this_month += 1

func _apply_flavor_event(ev: Dictionary) -> void:
	var effect: Dictionary = ev.get("effect", {})
	var color := Color(0.8, 0.9, 1.0)
	if effect.get("funds", 0) < 0 or effect.get("rep", 0) < 0:
		color = Color(1.0, 0.6, 0.4)
	elif effect.get("rep", 0) > 0 or effect.get("rp", 0) > 0:
		color = Color(0.5, 1.0, 0.7)
	GameState.alert_message.emit("📰 %s — %s" % [ev["name"], ev["desc"]], color)
	if effect.has("funds"):
		GameState.add_funds(effect["funds"])
	if effect.has("rep"):
		GameState.add_rep(effect["rep"])
	if effect.has("rp"):
		GameState.add_rp(effect["rp"])

func _apply_training_result(emp: Employee) -> void:
	var course = GameData.COURSES[emp.training_course_id]
	var boost: int = course["boost"]
	boost = int(boost * GameState.get_lab_exp_bonus())
	boost = int(boost * GameState.get_combo_training_boost_mult())
	# 紫队被动：培训加成
	var passive := emp.get_career_passive_bonus()
	if passive.has("training_mult"):
		boost = int(boost * passive["training_mult"])
	match course["skill"]:
		"skill_detect": emp.skill_detect = mini(100, emp.skill_detect + boost)
		"skill_analyze": emp.skill_analyze = mini(100, emp.skill_analyze + boost)
		"skill_response": emp.skill_response = mini(100, emp.skill_response + boost)
		"skill_training": emp.skill_training = mini(100, emp.skill_training + boost)
		"skill_research": emp.skill_research = mini(100, emp.skill_research + boost)
	emp.stat_trainings_done += 1
	emp.add_exp(20)
	EmployeeRoster.training_completed.emit(emp, emp.training_course_id)
	GameState.alert_message.emit("%s 完成《%s》，%s +%d！" % [emp.name, course["name"], _skill_name(course["skill"]), boost], Color(0.5, 1.0, 0.7))
	# 检查技能满级成就
	if emp.skill_detect >= 100 or emp.skill_analyze >= 100 or emp.skill_response >= 100 or emp.skill_training >= 100 or emp.skill_research >= 100:
		AchievementMgr.unlock("skill_max")

func _skill_name(s: String) -> String:
	match s:
		"skill_detect": return "威胁发现"
		"skill_analyze": return "事件分析"
		"skill_response": return "应急响应"
		"skill_training": return "培训教学"
		"skill_research": return "技术研究"
	return s

func _maybe_spawn_incident() -> void:
	if EmployeeRoster.employees.is_empty():
		return
	var today_abs: int = GameState.year * 360 + GameState.month * 30 + GameState.day
	if today_abs < next_incident_check_day:
		return
	var soc_level := GameState.get_dept("soc").level
	var base_chance := 0.35
	var chance: float = (base_chance + GameState.reputation * 0.004 - soc_level * 0.03) * GameState.difficulty_modifier
	if GameState.rng.randf() < chance:
		var type_id := GameData.pick_random_incident_type(GameState.rng, GameState.reputation)
		var inc := GameData.make_incident(type_id, GameState.year, GameState.month, GameState.rng)
		IncidentQueue.spawn(inc)
	next_incident_check_day = today_abs + GameState.rng.randi_range(1, 2)
