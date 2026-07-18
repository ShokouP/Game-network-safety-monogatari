extends PanelContainer
## 事件列表行

signal assign_requested(inc: Incident, emp_id: int)

var inc: Incident

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var time_label: Label = %TimeLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var assign_option: OptionButton = %AssignOption
@onready var status_label: Label = %StatusLabel

func setup(i: Incident) -> void:
	inc = i
	if not is_node_ready():
		ready.connect(_refresh)
	else:
		_refresh()

func _refresh() -> void:
	# 加载事件图标
	var tex_path := "res://assets/incidents/%s_64.png" % inc.type_id
	if ResourceLoader.exists(tex_path):
		icon_rect.texture = load(tex_path)
	name_label.text = "%s%s %s [难度%d]" % [
		"🔥专班 " if inc.is_special_team else "",
		inc.get_severity_name(), inc.name, inc.difficulty
	]
	name_label.add_theme_color_override("font_color", inc.get_severity_color())
	desc_label.text = inc.description
	desc_label.add_theme_font_size_override("font_size", 11)
	time_label.text = "⏱ %d 天" % inc.days_remaining
	if inc.days_remaining <= 1:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	progress_bar.value = inc.progress
	status_label.text = inc.get_status_name()
	match inc.status:
		Incident.Status.AWAITING_CHOICE:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
		Incident.Status.IN_PROGRESS:
			status_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
		_:
			status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	assign_option.clear()
	assign_option.add_item("未分配", -1)
	var selected_idx := 0
	for j in range(EmployeeRoster.employees.size()):
		var e := EmployeeRoster.employees[j]
		var label := "%s(%s%d)" % [e.name, _skill_short(inc.required_skill), e.get(inc.required_skill)]
		if e.is_training:
			label += "📚"
		assign_option.add_item(label, e.id)
		if e.id == inc.assigned_employee_id:
			selected_idx = j + 1
	assign_option.selected = selected_idx
	if not assign_option.item_selected.is_connected(_on_assign):
		assign_option.item_selected.connect(_on_assign)

func _skill_short(s: String) -> String:
	match s:
		"skill_detect": return "发现"
		"skill_analyze": return "分析"
		"skill_response": return "响应"
		"skill_training": return "教学"
		"skill_research": return "研究"
	return s

func _on_assign(idx: int) -> void:
	var emp_id := assign_option.get_item_id(idx)
	assign_requested.emit(inc, emp_id)
