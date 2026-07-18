extends Node
## EmployeeRoster autoload：员工花名册

signal employee_hired(emp: Employee)
signal employee_fired(emp: Employee)
signal employee_leveled(emp: Employee)
signal training_completed(emp: Employee, course_id: String)

const MAX_EMPLOYEES := 12

var employees: Array[Employee] = []
var next_emp_id: int = 1

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

# ---------- 序列化 ----------

func to_dict() -> Dictionary:
	return {
		"next_emp_id": next_emp_id,
		"employees": employees.map(func(e): return e.to_dict()),
	}

func from_dict(d: Dictionary) -> void:
	employees.clear()
	next_emp_id = d.get("next_emp_id", 1)
	for e_data in d.get("employees", []):
		var emp := Employee.from_dict(e_data)
		employees.append(emp)
		emp.leveled_up.connect(_on_emp_leveled)
