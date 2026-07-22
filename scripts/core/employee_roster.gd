extends Node
## EmployeeRoster autoload：员工花名册 + 隐藏员工寄信

signal employee_hired(emp: Employee)
signal employee_fired(emp: Employee)
signal employee_leveled(emp: Employee)
signal training_completed(emp: Employee, course_id: String)
signal hidden_employee_letter(hidden_id: String)  # 隐藏员工寄信

const MAX_EMPLOYEES := 12

var employees: Array[Employee] = []
var next_emp_id: int = 1
var unlocked_hidden: Array[String] = []  # 已解锁的隐藏员工

func _ready() -> void:
	pass

func reset() -> void:
	employees.clear()
	next_emp_id = 1

func generate_id() -> int:
	var id := next_emp_id
	next_emp_id += 1
	return id

func hire(emp: Employee) -> bool:
	if employees.size() >= MAX_EMPLOYEES:
		GameState.alert_message.emit("员工已满（%d 上限）" % MAX_EMPLOYEES, Color(1.0, 0.7, 0.4))
		return false
	if not GameState.spend_funds(emp.hire_cost):
		return false
	if emp.id == 0:
		emp.id = generate_id()
	emp.join_year = GameState.year
	emp.join_month = GameState.month
	employees.append(emp)
	emp.leveled_up.connect(_on_emp_leveled)
	employee_hired.emit(emp)
	return true

func fire(emp: Employee) -> void:
	employees.erase(emp)
	# 清理该员工被分配的事件
	for inc in IncidentQueue.active_incidents:
		if inc.assigned_employee_id == emp.id:
			inc.assigned_employee_id = -1
	employee_fired.emit(emp)

func _on_emp_leveled(emp: Employee) -> void:
	employee_leveled.emit(emp)
	# Lv.30 后退休
	if emp.level >= 30 and not emp.is_retired:
		emp.is_retired = true
		GameState.alert_message.emit("👴 %s 到了退休年龄，光荣退休！" % emp.name, Color(1.0, 0.85, 0.3))
		# 退休奖励：选 1 名新员工继承 50% 技能
		_offer_retirement_inherit(emp)

func _offer_retirement_inherit(retired_emp: Employee) -> void:
	## 退休传承：选 1 名新员工继承 50% 技能
	# 简化：自动选最低等级的员工继承
	var candidates: Array[Employee] = []
	for e in employees:
		if e.id != retired_emp.id and not e.is_retired:
			candidates.append(e)
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a, b): return a.level < b.level)
	var heir := candidates[0]
	heir.skill_detect = mini(100, heir.skill_detect + int(retired_emp.skill_detect * 0.5))
	heir.skill_analyze = mini(100, heir.skill_analyze + int(retired_emp.skill_analyze * 0.5))
	heir.skill_response = mini(100, heir.skill_response + int(retired_emp.skill_response * 0.5))
	heir.skill_training = mini(100, heir.skill_training + int(retired_emp.skill_training * 0.5))
	heir.skill_research = mini(100, heir.skill_research + int(retired_emp.skill_research * 0.5))
	GameState.alert_message.emit("📜 %s 继承了 %s 的衣钵（技能 +50%%）" % [heir.name, retired_emp.name], Color(0.5, 1.0, 0.7))
	# 移除退休员工
	employees.erase(retired_emp)
	employee_fired.emit(retired_emp)

func get_by_id(id: int) -> Employee:
	for e in employees:
		if e.id == id:
			return e
	return null

func get_avg_skill() -> float:
	if employees.is_empty():
		return 0.0
	var sum := 0.0
	for e in employees:
		sum += e.get_overall_skill()
	return sum / employees.size()

func get_total_salary() -> int:
	var sum := 0
	for e in employees:
		sum += e.get_salary()
	return sum

# ---------- 隐藏员工 ----------

func check_hidden_unlock(condition: String) -> void:
	## 检查是否解锁隐藏员工
	if condition in unlocked_hidden:
		return
	for data in GameData.HIDDEN_EMPLOYEES:
		if data["unlock_condition"] == condition:
			unlocked_hidden.append(condition)
			hidden_employee_letter.emit(data["id"])
			GameState.alert_message.emit("📩 收到神秘来信：%s 想加入你的团队！" % data["name"], Color(1.0, 0.85, 0.3))
			return

func hire_hidden(hidden_id: String) -> bool:
	## 雇佣隐藏员工
	var emp := GameData.generate_hidden_employee(hidden_id, generate_id())
	if emp == null:
		return false
	if employees.size() >= MAX_EMPLOYEES:
		GameState.alert_message.emit("员工已满", Color(1.0, 0.7, 0.4))
		return false
	emp.join_year = GameState.year
	emp.join_month = GameState.month
	employees.append(emp)
	emp.leveled_up.connect(_on_emp_leveled)
	employee_hired.emit(emp)
	GameState.alert_message.emit("🎉 %s 加入了团队！" % emp.name, Color(0.5, 1.0, 0.7))
	return true

# ---------- 序列化 ----------

func to_dict() -> Dictionary:
	return {
		"next_emp_id": next_emp_id,
		"employees": employees.map(func(e): return e.to_dict()),
		"unlocked_hidden": unlocked_hidden,
	}

func from_dict(d: Dictionary) -> void:
	employees.clear()
	next_emp_id = d.get("next_emp_id", 1)
	for e_data in d.get("employees", []):
		var emp := Employee.from_dict(e_data)
		employees.append(emp)
		emp.leveled_up.connect(_on_emp_leveled)
	unlocked_hidden = d.get("unlocked_hidden", [])
