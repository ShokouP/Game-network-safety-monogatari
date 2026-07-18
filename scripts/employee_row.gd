extends PanelContainer
## 员工列表行

signal train_requested(emp: Employee)
signal fire_requested(emp: Employee)
signal detail_requested(emp: Employee)

var emp: Employee

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_label: Label = %NameLabel
@onready var info_label: Label = %InfoLabel
@onready var fatigue_bar: ProgressBar = %FatigueBar
@onready var exp_bar: ProgressBar = %ExpBar
@onready var status_label: Label = %StatusLabel
@onready var train_btn: Button = %TrainButton
@onready var fire_btn: Button = %FireButton

func setup(e: Employee) -> void:
	emp = e
	if not is_node_ready():
		ready.connect(_refresh)
	else:
		_refresh()

func _specialty_key() -> String:
	match emp.specialty:
		Employee.Specialty.GENERAL: return "general"
		Employee.Specialty.PHISHING: return "phishing"
		Employee.Specialty.MALWARE: return "malware"
		Employee.Specialty.NETWORK: return "network"
		Employee.Specialty.FORENSICS: return "forensics"
		Employee.Specialty.COMPLIANCE: return "compliance"
	return "general"

func _refresh() -> void:
	var tex_path := "res://assets/sprites/employees/%s_64_transparent.png" % _specialty_key()
	if ResourceLoader.exists(tex_path):
		avatar_rect.texture = load(tex_path)
	avatar_rect.modulate = emp.get_appearance_modulate()
	name_label.text = "%s%s [%s] Lv.%d" % [
		emp.name,
		"·" + emp.get_career_name() if emp.career_path != Employee.CareerPath.NONE else "",
		emp.get_specialty_name(), emp.level
	]
	name_label.add_theme_color_override("font_color", emp.get_specialty_color())
	info_label.text = "发现%d 分析%d 响应%d 教学%d 研究%d" % [
		emp.skill_detect, emp.skill_analyze, emp.skill_response,
		emp.skill_training, emp.skill_research
	]
	info_label.add_theme_font_size_override("font_size", 11)
	fatigue_bar.value = emp.fatigue
	exp_bar.max_value = emp.get_exp_needed()
	exp_bar.value = emp.exp
	if emp.is_training:
		status_label.text = "📚培训中(%d天)" % emp.training_days_left
		status_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		train_btn.disabled = true
	elif emp.fatigue >= 80:
		status_label.text = "😫疲劳"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		train_btn.disabled = false
	else:
		status_label.text = "✓待命"
		status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		train_btn.disabled = false
	if not train_btn.pressed.is_connected(_on_train):
		train_btn.pressed.connect(_on_train)
	if not fire_btn.pressed.is_connected(_on_fire):
		fire_btn.pressed.connect(_on_fire)

func _on_train() -> void:
	train_requested.emit(emp)

func _on_fire() -> void:
	fire_requested.emit(emp)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 点击卡片空白处弹详情；按钮自身有 pressed 信号不会被这里拦截
		detail_requested.emit(emp)
