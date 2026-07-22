extends Node
## GameState 单例：日期/资金/声誉/研究点/情报/速度
## 员工、事件、成就、存档拆到各自 autoload

signal funds_changed(new_value: int)
signal rep_changed(new_value: int)
signal rp_changed(new_value: int)
signal intel_changed(new_value: int)
signal date_changed(year: int, month: int, day: int)
signal speed_changed(new_speed: int)
signal dept_upgraded(dept_id: String, new_level: int)
signal game_over(reason: String)
signal alert_message(text: String, color: Color)
signal year_ended(year: int)  # 用于年度奖项

const START_FUNDS := 80000   # 原 50000 → 80000，给新手喘息
const START_REP := 10
const MAX_REP := 100
const MIN_REP := 0
const MAX_RP := 9999
const MAX_INTEL := 100

# 软性破产保护
const BANKRUPT_THRESHOLD := 1000     # 资金低于此进入"危机"状态
const BANKRUPT_GRACE_MONTHS := 2     # 连续 2 个月资金 < 阈值才破产
const EMERGENCY_LOAN_AMOUNT := 30000 # CEO 紧急贷款额度
const EMERGENCY_LOAN_REP_COST := 5   # 贷款声誉代价

const DAY_SECONDS := [0.0, 2.0, 0.8, 0.3]

var year: int = 1
var month: int = 4
var day: int = 1
var speed: int = 1

var funds: int = START_FUNDS
var reputation: int = START_REP
var research_points: int = 0   # 研究点 - 用于解锁技术/课程
var threat_intel: int = 50     # 威胁情报 0-100，影响事件预警时间

# 季节（影响环境物加成）
enum Season { SPRING, SUMMER, AUTUMN, WINTER }
var current_season: Season = Season.SPRING

var departments: Dictionary = {}
var is_game_over: bool = false
var ng_plus_count: int = 0     # 二周目计数
var difficulty_modifier: float = 1.0  # NG+ 提升

# Fever 爆发机制
var fever_active: bool = false
var fever_days_left: int = 0
var fever_multiplier: float = 2.0  # 声誉 ×2
var fever_streak: int = 0  # 连续拦截计数

# 破产保护状态
var bankrupt_months_count: int = 0   # 连续低资金月数
var has_used_emergency_loan: bool = false  # 是否已用过紧急贷款

# CEO（玩家角色）
var ceo_name: String = "安全部长"
var ceo_avatar_id: int = 0  # 0-5 对应 6 个专长头像
var company_name: String = "安创科技"

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = hash(Time.get_unix_time_from_system() + randi())
	_init_departments()

func _init_departments() -> void:
	for dept_id in GameData.DEPARTMENTS.keys():
		var d := Department.new()
		d.id = dept_id
		d.level = 0
		departments[dept_id] = d

func reset_for_new_game() -> void:
	year = 1
	month = 4
	day = 1
	speed = 1
	funds = START_FUNDS
	reputation = START_REP
	research_points = 0
	threat_intel = 50
	is_game_over = false
	difficulty_modifier = 1.0 + ng_plus_count * 0.3
	bankrupt_months_count = 0
	has_used_emergency_loan = false
	_init_departments()
	date_changed.emit(year, month, day)
	funds_changed.emit(funds)
	rep_changed.emit(reputation)
	rp_changed.emit(research_points)
	intel_changed.emit(threat_intel)

# ---------- 资源操作 ----------

func add_funds(amount: int) -> void:
	funds = max(0, funds + amount)
	funds_changed.emit(funds)
	# 软性破产：不再立即破产，由 _on_month_end 累计月份判定

func can_afford(cost: int) -> bool:
	return funds >= cost

func spend_funds(cost: int) -> bool:
	if not can_afford(cost):
		alert_message.emit("资金不足！", Color(1.0, 0.5, 0.5))
		return false
	add_funds(-cost)
	return true

func add_rep(amount: int) -> void:
	# Fever 期间声誉 ×2
	if fever_active:
		amount = int(amount * fever_multiplier)
	reputation = clampi(reputation + amount, MIN_REP, MAX_REP)
	rep_changed.emit(reputation)
	if reputation <= 0 and not is_game_over:
		_trigger_game_over("声誉扫地！连续的安全事故让公司成为业界笑柄。")

func trigger_fever() -> void:
	## 连续拦截 10 次触发 Fever
	if fever_active:
		return
	fever_active = true
	fever_days_left = 7
	fever_streak = 0
	alert_message.emit("🔥 Fever！连续拦截 10 次，声誉 ×2，持续 7 天！", Color(1.0, 0.85, 0.3))

func _on_day_end() -> void:
	# Fever 倒计时
	if fever_active:
		fever_days_left -= 1
		if fever_days_left <= 0:
			fever_active = false
			alert_message.emit("Fever 结束", Color(0.7, 0.7, 0.7))
	# 员工疲劳恢复
	for emp in EmployeeRoster.employees:
		emp.recover_fatigue(2)
	# 部门被动产出
	var soc: Department = departments["soc"]
	if soc.level > 0 and rng.randf() < 0.05 * soc.level:
		var bonus := 500 * soc.level
		add_funds(bonus)
		alert_message.emit("SOC 自动拦截威胁，获得 ¥%d 保险返还" % bonus, Color(0.5, 1.0, 0.7))

func add_rp(amount: int) -> void:
	research_points = clampi(research_points + amount, 0, MAX_RP)
	rp_changed.emit(research_points)

func add_intel(amount: int) -> void:
	threat_intel = clampi(threat_intel + amount, 0, MAX_INTEL)
	intel_changed.emit(threat_intel)

func _trigger_game_over(reason: String) -> void:
	is_game_over = true
	game_over.emit(reason)

func set_speed(s: int) -> void:
	speed = clampi(s, 0, DAY_SECONDS.size() - 1)
	speed_changed.emit(speed)

# ---------- 时间推进 ----------

func advance_day() -> void:
	if is_game_over:
		return
	day += 1
	if day > 30:
		day = 1
		month += 1
		_on_month_end()
		if month > 12:
			month = 1
			year_ended.emit(year)  # 年底触发
			year += 1
	_on_day_end()
	date_changed.emit(year, month, day)

func _on_month_end() -> void:
	# 月薪
	var total_salary := 0
	for emp in EmployeeRoster.employees:
		total_salary += emp.get_salary()
	if total_salary > 0:
		add_funds(-total_salary)
		alert_message.emit("月度薪资支出 ¥%d" % total_salary, Color(1.0, 0.85, 0.4))
	# 部门维护
	for dept in departments.values():
		if dept.level > 0:
			add_funds(-GameData.get_dept_upkeep(dept.id, dept.level))
	# 合同收入（提高基数）
	var contract_income := reputation * 500  # 300 → 500
	add_funds(contract_income)
	alert_message.emit("月度安全服务合同收入 ¥%d（声誉 %d）" % [contract_income, reputation], Color(0.5, 0.9, 1.0))
	# 研究点被动产出（实验室 + combo + 季节加成）
	var lab: Department = departments["lab"]
	if lab.level > 0:
		var rp_gain: int = int(lab.level * 5 * get_combo_lab_rp_mult() * get_season_bonus()) + get_combo_monthly_rp_bonus()
		add_rp(rp_gain)
	# 季节更新（每 3 月换季节）
	_update_season()
	# 软性破产判定：连续 N 个月资金低于阈值
	if funds < BANKRUPT_THRESHOLD:
		bankrupt_months_count += 1
		if bankrupt_months_count >= BANKRUPT_GRACE_MONTHS:
			_trigger_game_over("连续 %d 个月资金枯竭，公司被迫解散安全部门。" % BANKRUPT_GRACE_MONTHS)
		else:
			alert_message.emit("⚠️ 资金危机！连续 %d/%d 个月低资金，再 %d 个月将破产" % [
				bankrupt_months_count, BANKRUPT_GRACE_MONTHS, BANKRUPT_GRACE_MONTHS - bankrupt_months_count
			], Color(1.0, 0.5, 0.5))
	else:
		bankrupt_months_count = 0

func _update_season() -> void:
	match month:
		3, 4, 5: current_season = Season.SPRING
		6, 7, 8: current_season = Season.SUMMER
		9, 10, 11: current_season = Season.AUTUMN
		12, 1, 2: current_season = Season.WINTER

func get_season_name() -> String:
	match current_season:
		Season.SPRING: return "春"
		Season.SUMMER: return "夏"
		Season.AUTUMN: return "秋"
		Season.WINTER: return "冬"
	return "?"

func get_season_bonus() -> float:
	## 季节对环境物/设施的效率加成
	match current_season:
		Season.SPRING: return 1.1   # 春 +10%
		Season.SUMMER: return 1.2   # 夏 +20%
		Season.AUTUMN: return 1.05  # 秋 +5%
		Season.WINTER: return 0.9   # 冬 -10%
	return 1.0

func take_emergency_loan() -> bool:
	## CEO 紧急贷款（一次性）
	if has_used_emergency_loan:
		alert_message.emit("紧急贷款已用过", Color(1.0, 0.7, 0.4))
		return false
	has_used_emergency_loan = true
	funds += EMERGENCY_LOAN_AMOUNT
	add_rep(-EMERGENCY_LOAN_REP_COST)
	funds_changed.emit(funds)
	alert_message.emit("💼 CEO 批了 ¥%d 紧急贷款（声誉 -%d）" % [EMERGENCY_LOAN_AMOUNT, EMERGENCY_LOAN_REP_COST], Color(0.5, 1.0, 0.7))
	return true

# ---------- 部门 ----------

func get_dept(dept_id: String) -> Department:
	return departments[dept_id]

func upgrade_dept(dept_id: String) -> bool:
	var dept: Department = departments[dept_id]
	if dept.level >= GameData.get_dept_max_level(dept_id):
		alert_message.emit("已达最高等级", Color(1.0, 0.85, 0.4))
		return false
	var cost := GameData.get_dept_upgrade_cost(dept_id, dept.level + 1)
	if not spend_funds(cost):
		return false
	dept.level += 1
	dept_upgraded.emit(dept_id, dept.level)
	alert_message.emit("%s 升级到 Lv.%d！" % [GameData.DEPARTMENTS[dept_id]["name"], dept.level], Color(0.5, 1.0, 0.7))
	return true

func get_lounge_recovery() -> int:
	## 休息区每日疲劳恢复加成
	var lounge: Department = departments["lounge"]
	return 2 + lounge.level * 2

func get_pr_penalty_reduction() -> float:
	## 公关办公室减少声誉损失比例
	var pr: Department = departments["pr_office"]
	return 1.0 - pr.level * 0.15  # 每级减 15%

func get_forensics_difficulty_reduction() -> float:
	var f: Department = departments["forensics"]
	return 1.0 - f.level * 0.08

func get_lab_exp_bonus() -> float:
	var lab: Department = departments["lab"]
	return 1.0 + lab.level * 0.15

func get_training_duration_modifier() -> float:
	var tr: Department = departments["training_room"]
	return max(0.5, 1.0 - tr.level * 0.1)

# ---------- 设施 combo ----------

func has_combo(dept_a: String, dept_b: String) -> bool:
	## 判定两部门是否同层且相邻（2 格内）且都已建成
	var floor_map = GameData.DEPT_FLOOR
	if not floor_map.has(dept_a) or not floor_map.has(dept_b):
		return false
	if floor_map[dept_a] != floor_map[dept_b]:
		return false
	var da: Department = departments.get(dept_a)
	var db: Department = departments.get(dept_b)
	if da == null or db == null or da.level == 0 or db.level == 0:
		return false
	# 相邻判定：简化版（同层即算相邻，后续可改具体坐标）
	return true

func get_active_combos() -> Array:
	## 返回当前激活的 combo 列表 [{combo_id, name, desc, effect}]
	var active := []
	for combo_id in GameData.DEPT_COMBOS.keys():
		var parts: PackedStringArray = combo_id.split("+")
		if parts.size() != 2:
			continue
		if has_combo(parts[0], parts[1]):
			var combo = GameData.DEPT_COMBOS[combo_id].duplicate()
			combo["combo_id"] = combo_id
			active.append(combo)
	return active

func get_combo_difficulty_mult() -> float:
	if has_combo("soc", "forensics"):
		return 0.95
	return 1.0

func get_combo_training_boost_mult() -> float:
	if has_combo("training_room", "lounge"):
		return 1.15
	return 1.0

func get_combo_monthly_rp_bonus() -> int:
	if has_combo("lab", "pr_office"):
		return 2
	return 0

func get_combo_incident_exp_mult() -> float:
	if has_combo("soc", "training_room"):
		return 1.2
	return 1.0

func get_combo_lab_rp_mult() -> float:
	if has_combo("forensics", "lab"):
		return 1.3
	return 1.0

# ---------- 序列化 ----------

func to_dict() -> Dictionary:
	return {
		"year": year, "month": month, "day": day, "speed": speed,
		"funds": funds, "reputation": reputation,
		"research_points": research_points, "threat_intel": threat_intel,
		"ng_plus_count": ng_plus_count,
		"difficulty_modifier": difficulty_modifier,
		"bankrupt_months_count": bankrupt_months_count,
		"has_used_emergency_loan": has_used_emergency_loan,
		"ceo_name": ceo_name,
		"ceo_avatar_id": ceo_avatar_id,
		"company_name": company_name,
		"departments": departments.values().map(func(d): return d.to_dict()),
	}

func from_dict(d: Dictionary) -> void:
	year = d.get("year", 1)
	month = d.get("month", 4)
	day = d.get("day", 1)
	speed = d.get("speed", 1)
	funds = d.get("funds", START_FUNDS)
	reputation = d.get("reputation", START_REP)
	research_points = d.get("research_points", 0)
	threat_intel = d.get("threat_intel", 50)
	ng_plus_count = d.get("ng_plus_count", 0)
	difficulty_modifier = d.get("difficulty_modifier", 1.0)
	bankrupt_months_count = d.get("bankrupt_months_count", 0)
	has_used_emergency_loan = d.get("has_used_emergency_loan", false)
	ceo_name = d.get("ceo_name", "安全部长")
	ceo_avatar_id = d.get("ceo_avatar_id", 0)
	company_name = d.get("company_name", "安创科技")
	departments.clear()
	for dd in d.get("departments", []):
		var dept := Department.from_dict(dd)
		departments[dept.id] = dept
	# 如果存档缺部门（版本升级），补齐
	for dept_id in GameData.DEPARTMENTS.keys():
		if not departments.has(dept_id):
			var nd := Department.new()
			nd.id = dept_id
			nd.level = 0
			departments[dept_id] = nd
	date_changed.emit(year, month, day)
	funds_changed.emit(funds)
	rep_changed.emit(reputation)
	rp_changed.emit(research_points)
	intel_changed.emit(threat_intel)
