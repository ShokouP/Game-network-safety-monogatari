extends Node
## AchievementMgr autoload：成就解锁 + 进度追踪 + Toast 通知

signal achievement_unlocked(achievement: Dictionary)
signal achievement_progress(ach_id: String, current: int, target: int)

var unlocked: Dictionary = {}  # ach_id -> unlock_timestamp
var progress: Dictionary = {}  # ach_id -> current_value

func _ready() -> void:
	# 监听游戏事件
	if EmployeeRoster:
		EmployeeRoster.employee_hired.connect(_on_employee_hired)
		EmployeeRoster.employee_leveled.connect(_on_employee_leveled)
		EmployeeRoster.training_completed.connect(_on_training_completed)
	if IncidentQueue:
		IncidentQueue.incident_resolved.connect(_on_incident_resolved)
	if GameState:
		GameState.dept_upgraded.connect(_on_dept_upgraded)
		GameState.year_ended.connect(_on_year_ended)

func reset() -> void:
	unlocked.clear()
	progress.clear()

func unlock(ach_id: String) -> void:
	if unlocked.has(ach_id):
		return
	var ach = GameData.ACHIEVEMENTS.get(ach_id)
	if ach == null:
		return
	unlocked[ach_id] = Time.get_unix_time_from_system()
	achievement_unlocked.emit(ach)
	GameState.alert_message.emit("🏆 成就解锁：%s" % ach["name"], Color(1.0, 0.85, 0.3))
	# 成就奖励
	if ach.has("reward_funds"):
		GameState.add_funds(ach["reward_funds"])
	if ach.has("reward_rep"):
		GameState.add_rep(ach["reward_rep"])
	if ach.has("reward_rp"):
		GameState.add_rp(ach["reward_rp"])

func set_progress(ach_id: String, value: int) -> void:
	if unlocked.has(ach_id):
		return
	var ach = GameData.ACHIEVEMENTS.get(ach_id)
	if ach == null:
		return
	var target: int = ach.get("target", 1)
	var old: int = progress.get(ach_id, 0)
	progress[ach_id] = value
	if value >= target:
		unlock(ach_id)
	elif value != old:
		achievement_progress.emit(ach_id, value, target)

func add_progress(ach_id: String, delta: int) -> void:
	set_progress(ach_id, progress.get(ach_id, 0) + delta)

func is_unlocked(ach_id: String) -> bool:
	return unlocked.has(ach_id)

func get_unlock_count() -> int:
	return unlocked.size()

func get_total_count() -> int:
	return GameData.ACHIEVEMENTS.size()

# ---------- 事件触发 ----------

func _on_employee_hired(_emp: Employee) -> void:
	add_progress("hire_1", 1)
	add_progress("hire_5", 1)
	add_progress("hire_12", 1)

func _on_employee_leveled(emp: Employee) -> void:
	if emp.level >= 10:
		unlock("emp_level_10")
	if emp.level >= 20:
		unlock("emp_level_20")
	if emp.level >= 30:
		unlock("emp_level_30")

func _on_training_completed(_emp: Employee, _course_id: String) -> void:
	add_progress("train_5", 1)
	add_progress("train_20", 1)

func _on_incident_resolved(inc: Incident, success: bool) -> void:
	if success:
		add_progress("block_10", 1)
		add_progress("block_50", 1)
		add_progress("block_100", 1)
		add_progress("block_500", 1)
		if inc.severity == Incident.Severity.CRITICAL:
			add_progress("block_critical_10", 1)
		if inc.days_remaining >= inc.initial_days - 1:
			add_progress("block_fast_5", 1)  # 1 天内解决
	else:
		add_progress("breach_5", 1)
		if inc.severity == Incident.Severity.CRITICAL:
			unlock("breach_critical_1")

func _on_dept_upgraded(_dept_id: String, _level: int) -> void:
	var total_levels := 0
	for d in GameState.departments.values():
		total_levels += d.level
	if total_levels >= 5:
		unlock("dept_total_5")
	if total_levels >= 15:
		unlock("dept_total_15")
	if GameState.departments.values().all(func(d): return d.level > 0):
		unlock("dept_all_built")
	if GameState.departments.values().all(func(d): return d.level >= 5):
		unlock("dept_all_max")

func _on_year_ended(_year: int) -> void:
	if IncidentQueue.year_breached == 0 and IncidentQueue.year_blocked >= 5:
		unlock("perfect_year")
	add_progress("survive_5y", 1)
	add_progress("survive_10y", 1)

# ---------- 序列化 ----------

func to_dict() -> Dictionary:
	return {
		"unlocked": unlocked,
		"progress": progress,
	}

func from_dict(d: Dictionary) -> void:
	unlocked = d.get("unlocked", {})
	progress = d.get("progress", {})
