extends PanelContainer
## 网安小助手 - 右下角常驻，前 3 月强制指引

signal task_completed(task_id: String)
signal month_completed(month: int)

@onready var avatar: TextureRect = %Avatar
@onready var name_label: Label = %NameLabel
@onready var dialog_label: Label = %DialogLabel
@onready var task_list: VBoxContainer = %TaskList
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var minimize_btn: Button = %MinimizeButton

var current_month: int = 4
var completed_tasks: Array[String] = []
var is_minimized: bool = false

func _ready() -> void:
	name_label.text = "小盾"
	# 加载小助手头像（用 general 头像代替）
	if ResourceLoader.exists("res://assets/sprites/employees/general_64_transparent.png"):
		avatar.texture = load("res://assets/sprites/employees/general_64_transparent.png")
	minimize_btn.pressed.connect(_on_minimize)
	# 监听游戏事件
	GameState.date_changed.connect(_on_date_changed)
	IncidentQueue.incident_resolved.connect(_on_incident_resolved)
	EmployeeRoster.employee_hired.connect(_on_employee_hired)
	EmployeeRoster.training_completed.connect(_on_training_completed)
	GameState.dept_upgraded.connect(_on_dept_upgraded)
	GameState.funds_changed.connect(_on_funds_changed)
	# 初始化
	_show_month_guide(GameState.month)

func _on_date_changed(y: int, m: int, _d: int) -> void:
	if y == 1 and m >= 4 and m <= 6:
		_show_month_guide(m)

func _show_month_guide(month: int) -> void:
	if not AssistantData.GUIDE_TASKS.has(month):
		visible = false
		return
	current_month = month
	visible = true
	var guide = AssistantData.GUIDE_TASKS[month]
	dialog_label.text = AssistantData.DIALOGS.get("intro_%d" % month, "")
	_build_task_list(guide)

func _build_task_list(guide: Dictionary) -> void:
	for c in task_list.get_children():
		c.queue_free()
	var tasks: Array = guide["tasks"]
	var done_count := 0
	for task in tasks:
		var row := HBoxContainer.new()
		var check := Label.new()
		var task_id: String = task["id"]
		var is_done := _check_task(task["check"])
		if is_done:
			done_count += 1
			check.text = "✅"
			check.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		else:
			check.text = "⬜"
			check.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(check)
		var desc := Label.new()
		desc.text = task["desc"]
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc)
		task_list.add_child(row)
		# 更新进度条
		progress_bar.max_value = tasks.size()
		progress_bar.value = done_count
		# 全部完成
		if done_count >= tasks.size():
			_on_month_completed()

func _check_task(check: String) -> bool:
	## 解析任务条件
	var parts := check.split(">=")
	if parts.size() != 2:
		return false
	var key := parts[0]
	var value := int(parts[1])
	match key:
		"emp_count": return EmployeeRoster.employees.size() >= value
		"blocked": return IncidentQueue.total_blocked >= value
		"dept_built":
			for d in GameState.departments.values():
				if d.level >= value: return true
			return false
		"dept_max_level":
			for d in GameState.departments.values():
				if d.level >= value: return true
			return false
		"emp_max_level":
			for e in EmployeeRoster.employees:
				if e.level >= value: return true
			return false
		"funds": return GameState.funds >= value
		"incident_assigned": return IncidentQueue.active_incidents.any(func(i): return i.assigned_employee_id >= 0)
		"training_done": return EmployeeRoster.employees.any(func(e): return e.stat_trainings_done >= 1)
		"combo_active": return GameState.get_active_combos().size() > 0
		"career_path": return EmployeeRoster.employees.any(func(e): return e.career_path != Employee.CareerPath.NONE)
	return false

func _on_employee_hired(_emp: Employee) -> void:
	_refresh_tasks()

func _on_incident_resolved(_inc: Incident, _success: bool) -> void:
	_refresh_tasks()

func _on_training_completed(_emp: Employee, _course_id: String) -> void:
	_refresh_tasks()

func _on_dept_upgraded(_dept_id: String, _level: int) -> void:
	_refresh_tasks()

func _on_funds_changed(_v: int) -> void:
	_refresh_tasks()

func _refresh_tasks() -> void:
	if not AssistantData.GUIDE_TASKS.has(current_month):
		return
	_build_task_list(AssistantData.GUIDE_TASKS[current_month])

func _on_month_completed() -> void:
	var guide = AssistantData.GUIDE_TASKS[current_month]
	var reward: Dictionary = guide["reward"]
	if reward.has("funds"): GameState.add_funds(reward["funds"])
	if reward.has("rp"): GameState.add_rp(reward["rp"])
	if reward.has("rep"): GameState.add_rep(reward["rep"])
	dialog_label.text = AssistantData.DIALOGS["month_done"]
	month_completed.emit(current_month)

func _on_minimize() -> void:
	is_minimized = not is_minimized
	task_list.visible = not is_minimized
	progress_bar.visible = not is_minimized
	minimize_btn.text = "▲" if is_minimized else "▼"
