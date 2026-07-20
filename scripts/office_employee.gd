extends CharacterBody2D
## 员工 agent：状态机驱动（Idle/Walk/Work/HandleIncident/Rest）
## 2.5D 适配：透视缩放 + 斜线行走

enum State { IDLE, WALK_TO_DESK, WORK_AT_DESK, WALK_TO_FACILITY, AT_FACILITY, HANDLE_INCIDENT, REST }

const SPEED := 80.0
const ARRIVE_THRESHOLD := 4.0

var emp: Employee
var office_view: Node2D
var current_state: State = State.IDLE
var target_position: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var idle_duration: float = 2.0

@onready var sprite: Sprite2D = %Sprite
@onready var name_label: Label = %NameLabel
@onready var bubble: PanelContainer = %Bubble
@onready var bubble_label: Label = %BubbleLabel
@onready var alert_icon: Label = %AlertIcon

var dialog_timer: float = 0.0
var dialog_cooldown: float = 8.0
var rng := RandomNumberGenerator.new()

func setup(e: Employee, ov: Node2D) -> void:
	emp = e
	office_view = ov
	if not is_node_ready():
		ready.connect(_on_ready)
	else:
		_on_ready()

func _on_ready() -> void:
	name_label.text = emp.name.substr(0, 3)
	var texture_path := "res://assets/sprites/employees/%s_64_transparent.png" % _specialty_key()
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		sprite.texture = load("res://assets/sprites/employees/general_64_transparent.png")
	sprite.modulate = emp.get_appearance_modulate()
	position = office_view.get_desk_position(emp.desk_id)
	_change_state(State.IDLE)
	var refresh_timer := Timer.new()
	refresh_timer.wait_time = 0.5
	refresh_timer.timeout.connect(_refresh_visual)
	refresh_timer.autostart = true
	add_child(refresh_timer)

func _specialty_key() -> String:
	match emp.specialty:
		Employee.Specialty.GENERAL: return "general"
		Employee.Specialty.PHISHING: return "phishing"
		Employee.Specialty.MALWARE: return "malware"
		Employee.Specialty.NETWORK: return "network"
		Employee.Specialty.FORENSICS: return "forensics"
		Employee.Specialty.COMPLIANCE: return "compliance"
	return "general"

func _physics_process(delta: float) -> void:
	state_timer += delta
	dialog_timer += delta
	match current_state:
		State.IDLE:
			if state_timer >= idle_duration:
				_pick_next_state()
		State.WALK_TO_DESK, State.WALK_TO_FACILITY, State.HANDLE_INCIDENT, State.REST:
			_move_toward_target(delta)
		State.WORK_AT_DESK, State.AT_FACILITY:
			if state_timer >= 3.0:
				_change_state(State.IDLE)

func _move_toward_target(delta: float) -> void:
	var dir := (target_position - position)
	if dir.length() < ARRIVE_THRESHOLD:
		velocity = Vector2.ZERO
		_on_arrive()
		return
	dir = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()
	# 2.5D 透视缩放：根据 y 坐标调整大小
	_update_iso_scale()
	# 行走时轻微上下摆动模拟步伐
	sprite.position.y = -2.0 if int(Time.get_ticks_msec() / 200) % 2 == 0 else 0.0

func _update_iso_scale() -> void:
	## 根据 y 坐标返回透视缩放（越靠下越大）
	if office_view == null:
		return
	var scale_factor: float = office_view.get_employee_scale(position.y)
	sprite.scale = Vector2(scale_factor, scale_factor)
	# 名字标签也缩放，但保持可读性
	name_label.scale = Vector2(lerpf(0.8, 1.2, scale_factor / 1.2), lerpf(0.8, 1.2, scale_factor / 1.2))

func _on_arrive() -> void:
	match current_state:
		State.WALK_TO_DESK:
			_change_state(State.WORK_AT_DESK)
		State.WALK_TO_FACILITY:
			_change_state(State.AT_FACILITY)
		State.HANDLE_INCIDENT:
			_change_state(State.WORK_AT_DESK)
		State.REST:
			_change_state(State.AT_FACILITY)
		_:
			_change_state(State.IDLE)

func _change_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	idle_duration = randf_range(2.0, 5.0)
	_refresh_visual()

func _pick_next_state() -> void:
	if emp.is_training:
		_walk_to_facility("training_room", State.WALK_TO_FACILITY)
		return
	if emp.fatigue >= 60:
		_walk_to_facility("lounge", State.REST)
		return
	for inc in IncidentQueue.active_incidents:
		if inc.assigned_employee_id == emp.id:
			if GameState.get_dept("soc").level > 0:
				_walk_to_facility("soc", State.HANDLE_INCIDENT)
			else:
				_change_state(State.WALK_TO_DESK)
				target_position = office_view.get_desk_position(emp.desk_id)
			return
	target_position = office_view.get_desk_position(emp.desk_id)
	_change_state(State.WALK_TO_DESK)

func _walk_to_facility(dept_id: String, state: State) -> void:
	var dept := GameState.get_dept(dept_id)
	if dept.level == 0:
		target_position = office_view.get_desk_position(emp.desk_id)
		_change_state(State.WALK_TO_DESK)
		return
	var facility_floor := _get_dept_floor(dept_id)
	if facility_floor != emp.floor_id:
		emp.floor_id = facility_floor
		position = office_view.get_facility_position(dept_id)
		_change_state(State.AT_FACILITY)
		return
	target_position = office_view.get_facility_position(dept_id)
	_change_state(state)

func _get_dept_floor(dept_id: String) -> int:
	match dept_id:
		"soc", "training_room", "lounge": return 1
		"lab", "forensics", "pr_office": return 2
		_: return 0

func _pick_dialog_category() -> String:
	if emp.is_training:
		return "training"
	if emp.fatigue >= 70:
		return "tired"
	for inc in IncidentQueue.active_incidents:
		if inc.assigned_employee_id == emp.id:
			if inc.severity >= Incident.Severity.HIGH:
				return "incident_high"
			return "working"
	if current_state == State.WORK_AT_DESK or current_state == State.AT_FACILITY:
		return "working"
	return "idle"

func _refresh_visual() -> void:
	if not is_node_ready():
		return
	if emp.is_training:
		bubble_label.text = "📚 %d天" % emp.training_days_left
		bubble.visible = true
	elif emp.fatigue >= 80:
		bubble_label.text = "😫"
		bubble.visible = true
	elif dialog_timer >= dialog_cooldown:
		dialog_timer = 0.0
		dialog_cooldown = randf_range(8.0, 15.0)
		if rng.randf() < 0.7:
			var cat := _pick_dialog_category()
			bubble_label.text = BubbleDialogData.pick(rng, cat)
			bubble.visible = true
			await get_tree().create_timer(3.0).timeout
			if is_instance_valid(self) and not emp.is_training and emp.fatigue < 80:
				bubble.visible = false
	else:
		bubble.visible = false
	var has_incident := false
	for inc in IncidentQueue.active_incidents:
		if inc.assigned_employee_id == emp.id and inc.severity >= Incident.Severity.HIGH:
			has_incident = true
			break
	alert_icon.visible = has_incident
	if emp.fatigue >= 80:
		sprite.modulate = Color(0.6, 0.6, 0.6)
	else:
		sprite.modulate = Color.WHITE
