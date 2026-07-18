extends PanelContainer
## 员工列表行 - 紧凑版：头像 + 名字 + 状态 + 2 按钮

signal train_requested(emp: Employee)
signal fire_requested(emp: Employee)
signal detail_requested(emp: Employee)

var emp: Employee

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var train_btn: Button = %TrainButton
@onready var fire_btn: Button = %FireButton
@onready var detail_btn: Button = %DetailButton

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
	# 名字（含转职/专长）
	name_label.text = "%s%s [%s] Lv.%d" % [
		emp.name,
		"·" + emp.get_career_name() if emp.career_path != Employee.CareerPath.NONE else "",
		emp.get_specialty_name(), emp.level
	]
	name_label.add_theme_color_override("font_color", emp.get_specialty_color())
	# 状态
	if emp.is_training:
		status_label.text = "📚%d天" % emp.training_days_left
		status_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		train_btn.disabled = true
	elif emp.fatigue >= 80:
		status_label.text = "😫"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		train_btn.disabled = false
	else:
		status_label.text = "✓"
		status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		train_btn.disabled = false
	if not train_btn.pressed.is_connected(_on_train):
		train_btn.pressed.connect(_on_train)
	if not fire_btn.pressed.is_connected(_on_fire):
		fire_btn.pressed.connect(_on_fire)
	if not detail_btn.pressed.is_connected(_on_detail):
		detail_btn.pressed.connect(_on_detail)

func _on_train() -> void:
	train_requested.emit(emp)

func _on_fire() -> void:
	fire_requested.emit(emp)

func _on_detail() -> void:
	detail_requested.emit(emp)
