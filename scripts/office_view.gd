extends Node2D
## 俯视图办公室（A3 可扩张楼层）+ AI 美术资源 + 2.5D 适配

signal employee_clicked(emp: Employee)
signal facility_clicked(dept_id: String)

const TILE_SIZE := 32
const FLOOR_WIDTH := 24
const FLOOR_HEIGHT := 24

const FLOORS := {
	0: {"name": "F1 办公区", "unlocked_by": null, "depts": [], "floor_tex": "map_f1_office"},
	1: {"name": "F2 运营区", "unlocked_by": "soc", "depts": ["soc", "training_room", "lounge"], "floor_tex": "map_f2_operations"},
	2: {"name": "F3 研究区", "unlocked_by": "lab", "depts": ["lab", "forensics", "pr_office"], "floor_tex": "map_f3_research"},
}

# 办公室区域（每楼层内的功能分区）
const FLOOR_ZONES := {
	0: [  # F1 办公区
		{"name": "工位区", "rect": Rect2i(4, 3, 16, 18), "color": Color(0.2, 0.3, 0.4, 0.3)},
		{"name": "会议室", "rect": Rect2i(1, 1, 4, 4), "color": Color(0.3, 0.2, 0.4, 0.3)},
		{"name": "休息区", "rect": Rect2i(19, 1, 4, 4), "color": Color(0.2, 0.4, 0.3, 0.3)},
	],
	1: [  # F2 运营区
		{"name": "SOC 监控", "rect": Rect2i(2, 2, 8, 8), "color": Color(0.1, 0.3, 0.2, 0.3)},
		{"name": "培训室", "rect": Rect2i(12, 2, 8, 8), "color": Color(0.3, 0.3, 0.1, 0.3)},
		{"name": "休息区", "rect": Rect2i(2, 12, 8, 8), "color": Color(0.2, 0.4, 0.3, 0.3)},
	],
	2: [  # F3 研究区
		{"name": "实验室", "rect": Rect2i(2, 2, 8, 8), "color": Color(0.3, 0.1, 0.3, 0.3)},
		{"name": "取证室", "rect": Rect2i(12, 2, 8, 8), "color": Color(0.1, 0.3, 0.3, 0.3)},
		{"name": "公关室", "rect": Rect2i(2, 12, 8, 8), "color": Color(0.3, 0.2, 0.1, 0.3)},
	],
}

@onready var floor_container: Node2D = %FloorContainer
@onready var employee_container: Node2D = %EmployeeContainer

var current_floor: int = 0
var employee_agents: Dictionary = {}
var facility_tiles: Dictionary = {}

const OFFICE_EMPLOYEE_SCENE := preload("res://scenes/office_employee.tscn")

func _ready() -> void:
	_build_floor(0)
	_refresh_floor_tabs()
	GameState.dept_upgraded.connect(_on_dept_upgraded)
	EmployeeRoster.employee_hired.connect(_on_employee_hired)
	EmployeeRoster.employee_fired.connect(_on_employee_fired)
	# 自动缩放适配父容器
	call_deferred("_fit_to_parent")
	get_viewport().size_changed.connect(_fit_to_parent)

func _fit_to_parent() -> void:
	## 让楼层缩放填满父容器（OfficeViewContainer）
	var parent := get_parent()
	if parent == null or not (parent is Control):
		return
	var container := parent as Control
	var avail := container.size
	if avail.x <= 0 or avail.y <= 0:
		return
	var floor_w := float(FLOOR_WIDTH * TILE_SIZE)
	var floor_h := float(FLOOR_HEIGHT * TILE_SIZE)
	var scale_x := avail.x / floor_w
	var scale_y := avail.y / floor_h
	var scale := minf(scale_x, scale_y)
	scale = clampf(scale, 0.5, 3.0)
	self.scale = Vector2(scale, scale)
	# 居中
	var offset_x := (avail.x - floor_w * scale) / 2.0
	var offset_y := (avail.y - floor_h * scale) / 2.0
	self.position = Vector2(offset_x, offset_y)

# ---------- 2.5D 坐标转换 ----------

func grid_to_iso(grid_x: int, grid_y: int) -> Vector2:
	## 2D 网格坐标 → 2.5D 斜 45 度坐标（以地图中心为原点）
	# 地图尺寸 640x384，中心在 (320, 192)
	var center_x := float(FLOOR_WIDTH * TILE_SIZE) * 0.5
	var center_y := float(FLOOR_HEIGHT * TILE_SIZE) * 0.5
	var iso_x := float(grid_x - grid_y) * (TILE_SIZE * 0.5)
	var iso_y := float(grid_x + grid_y) * (TILE_SIZE * 0.25)
	return Vector2(center_x + iso_x, center_y + iso_y)

func get_desk_position(desk_id: int) -> Vector2:
	if desk_id < 0:
		return grid_to_iso(10, 6)
	var row: int = desk_id / 4
	var col: int = desk_id % 4
	# 工位在 2.5D 地图上的实际位置（按地图上的 12 个工位标定）
	# 地图上的工位分布：4 列 x 3 行，大致在地图中央偏下
	var grid_x := 3 + col * 4
	var grid_y := 3 + row * 3
	return grid_to_iso(grid_x, grid_y)

func get_facility_position(dept_id: String) -> Vector2:
	if not facility_tiles.has(dept_id):
		return grid_to_iso(10, 6)
	var rect: Rect2i = facility_tiles[dept_id]
	return grid_to_iso(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)

func get_employee_scale(y_pos: float) -> float:
	## 根据 y 坐标返回透视缩放（越靠下越大）
	# y 范围 0 ~ FLOOR_HEIGHT * TILE_SIZE * 0.5
	var max_y := float(FLOOR_HEIGHT * TILE_SIZE) * 0.5
	var t := clampf(y_pos / max_y, 0.0, 1.0)
	return lerpf(0.6, 1.2, t)  # 远 0.6x，近 1.2x

# ---------- 楼层构建 ----------

func _build_floor(floor_id: int) -> void:
	for c in floor_container.get_children():
		c.queue_free()
	facility_tiles.clear()
	var floor_node := Node2D.new()
	floor_node.name = "Floor%d" % floor_id
	floor_container.add_child(floor_node)
	# 用 AI 生成的 2.5D 地图作为背景
	var tex_key: String = FLOORS[floor_id]["floor_tex"]
	var tex_path := "res://assets/tiles/maps/%s.jpg" % tex_key
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = false
		# 缩放到楼层大小（24x24 格 = 768x768）
		spr.scale = Vector2(
			float(FLOOR_WIDTH * TILE_SIZE) / tex.get_width(),
			float(FLOOR_HEIGHT * TILE_SIZE) / tex.get_height()
		)
		floor_node.add_child(spr)
	else:
		var bg := ColorRect.new()
		bg.size = Vector2(FLOOR_WIDTH * TILE_SIZE, FLOOR_HEIGHT * TILE_SIZE)
		match floor_id:
			0: bg.color = Color(0.16, 0.19, 0.26)
			1: bg.color = Color(0.14, 0.22, 0.20)
			2: bg.color = Color(0.20, 0.16, 0.28)
		floor_node.add_child(bg)
	if floor_id == 0:
		_build_desks(floor_node)
	else:
		_build_facilities(floor_node, floor_id)
	# 区域标记（可选显示）
	for zone in FLOOR_ZONES.get(floor_id, []):
		var zone_rect := ColorRect.new()
		var rect: Rect2i = zone["rect"]
		zone_rect.position = Vector2(rect.position.x * TILE_SIZE, rect.position.y * TILE_SIZE)
		zone_rect.size = Vector2(rect.size.x * TILE_SIZE, rect.size.y * TILE_SIZE)
		zone_rect.color = zone["color"]
		floor_node.add_child(zone_rect)

func _build_desks(parent: Node2D) -> void:
	# 2.5D 地图上工位是斜的，用标记点表示（可选）
	# 实际员工位置由 get_desk_position 计算
	pass

func _build_facilities(parent: Node2D, floor_id: int) -> void:
	var depts: Array = FLOORS[floor_id]["depts"]
	var idx := 0
	for dept_id in depts:
		var dept := GameState.get_dept(dept_id)
		var grid_x := 3 + idx * 6
		var grid_y := 4
		var rect := Rect2i(grid_x, grid_y, 5, 4)
		facility_tiles[dept_id] = rect
		var center := grid_to_iso(grid_x + 2, grid_y + 2)
		# 背景框（透明，只用于点击区域）
		var panel := Panel.new()
		panel.position = center - Vector2(60, 40)
		panel.size = Vector2(120, 80)
		var style := StyleBoxFlat.new()
		if dept.level > 0:
			style.bg_color = Color(0.1, 0.15, 0.2, 0.5)
		else:
			style.bg_color = Color(0.2, 0.2, 0.25, 0.3)
		style.border_color = Color(0.4, 0.6, 0.7) if dept.level > 0 else Color(0.3, 0.3, 0.35)
		style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)
		panel.gui_input.connect(_on_facility_clicked.bind(dept_id))
		parent.add_child(panel)
		# 设施插画
		var tex_path := "res://assets/sprites/facilities/%s_96.png" % dept_id
		if dept.level > 0 and ResourceLoader.exists(tex_path):
			var tex: Texture2D = load(tex_path)
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.position = center
			spr.scale = Vector2(0.8, 0.8)
			parent.add_child(spr)
			var tween := spr.create_tween().set_loops()
			tween.tween_property(spr, "modulate:a", 0.7, 1.5).set_trans(Tween.TRANS_SINE)
			tween.tween_property(spr, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
		# 名称
		var name_lbl := Label.new()
		name_lbl.text = "%s %s Lv.%d" % [GameData.DEPARTMENTS[dept_id]["icon"], GameData.DEPARTMENTS[dept_id]["name"], dept.level]
		name_lbl.position = center + Vector2(-40, -50)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		parent.add_child(name_lbl)
		if dept.level == 0:
			var lock_lbl := Label.new()
			lock_lbl.text = "🔒"
			lock_lbl.position = center + Vector2(-10, -10)
			lock_lbl.add_theme_font_size_override("font_size", 20)
			parent.add_child(lock_lbl)
		idx += 1

# ---------- 楼层切换 ----------

func _refresh_floor_tabs() -> void:
	var tab_bar := _get_floor_tab_bar()
	if tab_bar == null:
		return
	for c in tab_bar.get_children():
		c.queue_free()
	for floor_id in FLOORS.keys():
		var b := Button.new()
		b.text = FLOORS[floor_id]["name"]
		var unlocked := _is_floor_unlocked(floor_id)
		b.disabled = not unlocked
		if not unlocked:
			var required_dept: String = FLOORS[floor_id]["unlocked_by"]
			b.text += " 🔒"
			b.tooltip_text = "需要建设「%s」" % GameData.DEPARTMENTS[required_dept]["name"]
		b.pressed.connect(_on_floor_tab.bind(floor_id))
		tab_bar.add_child(b)
		if floor_id == current_floor:
			b.modulate = Color(0.6, 1.0, 0.7)

func _get_floor_tab_bar() -> HBoxContainer:
	var main := get_tree().root.get_node_or_null("Main")
	if main == null:
		return null
	return main.get_node_or_null("RootVBox/MainHBox/CenterVBox/CenterTabs/OfficeTab/OfficeVBox/FloorTabBar") as HBoxContainer

func _is_floor_unlocked(floor_id: int) -> bool:
	var required = FLOORS[floor_id]["unlocked_by"]
	if required == null:
		return true
	return GameState.get_dept(required).level >= 1

func _on_floor_tab(floor_id: int) -> void:
	current_floor = floor_id
	_build_floor(floor_id)
	_refresh_floor_tabs()
	_reposition_employees()

func _on_dept_upgraded(dept_id: String, _level: int) -> void:
	_refresh_floor_tabs()
	if dept_id in FLOORS[current_floor].get("depts", []):
		_build_floor(current_floor)

# ---------- 员工管理 ----------

func _on_employee_hired(emp: Employee) -> void:
	_spawn_employee(emp)

func _on_employee_fired(emp: Employee) -> void:
	if employee_agents.has(emp.id):
		employee_agents[emp.id].queue_free()
		employee_agents.erase(emp.id)

func _spawn_employee(emp: Employee) -> void:
	if employee_agents.has(emp.id):
		return
	var agent := OFFICE_EMPLOYEE_SCENE.instantiate()
	employee_container.add_child(agent)
	agent.setup(emp, self)
	employee_agents[emp.id] = agent
	if emp.desk_id < 0:
		emp.desk_id = _find_free_desk()
		emp.floor_id = 0
	_reposition_employees()

func _find_free_desk() -> int:
	var used := {}
	for e in EmployeeRoster.employees:
		if e.desk_id >= 0:
			used[e.desk_id] = true
	for i in range(12):
		if not used.has(i):
			return i
	return -1

func _reposition_employees() -> void:
	for emp_id in employee_agents.keys():
		var agent = employee_agents[emp_id]
		var emp := EmployeeRoster.get_by_id(emp_id)
		if emp == null:
			continue
		agent.visible = (emp.floor_id == current_floor)

func _on_facility_clicked(event: InputEvent, dept_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		facility_clicked.emit(dept_id)

func refresh_all_employees() -> void:
	for emp in EmployeeRoster.employees:
		_spawn_employee(emp)
