extends Node2D
## 俯视图办公室（A3 可扩张楼层）+ AI 美术资源

signal employee_clicked(emp: Employee)
signal facility_clicked(dept_id: String)

const TILE_SIZE := 32
const FLOOR_WIDTH := 20
const FLOOR_HEIGHT := 12

const FLOORS := {
	0: {"name": "F1 办公区", "unlocked_by": null, "depts": [], "floor_tex": "floor_f1"},
	1: {"name": "F2 运营区", "unlocked_by": "soc", "depts": ["soc", "training_room", "lounge"], "floor_tex": "floor_f2"},
	2: {"name": "F3 研究区", "unlocked_by": "lab", "depts": ["lab", "forensics", "pr_office"], "floor_tex": "floor_f3"},
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

func _build_floor(floor_id: int) -> void:
	for c in floor_container.get_children():
		c.queue_free()
	facility_tiles.clear()
	var floor_node := Node2D.new()
	floor_node.name = "Floor%d" % floor_id
	floor_container.add_child(floor_node)
	# 用 AI 生成的 tile 铺满
	var tex_key: String = FLOORS[floor_id]["floor_tex"]
	var tex_path := "res://assets/tiles/%s_32.png" % tex_key
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		for x in range(FLOOR_WIDTH):
			for y in range(FLOOR_HEIGHT):
				var spr := Sprite2D.new()
				spr.texture = tex
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				spr.centered = false
				spr.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				floor_node.add_child(spr)
	else:
		var bg := ColorRect.new()
		bg.size = Vector2(FLOOR_WIDTH * TILE_SIZE, FLOOR_HEIGHT * TILE_SIZE)
		match floor_id:
			0: bg.color = Color(0.16, 0.19, 0.26)
			1: bg.color = Color(0.14, 0.22, 0.20)
			2: bg.color = Color(0.20, 0.16, 0.28)
		floor_node.add_child(bg)
	# 网格线
	for x in range(FLOOR_WIDTH + 1):
		var line := ColorRect.new()
		line.size = Vector2(1, FLOOR_HEIGHT * TILE_SIZE)
		line.position = Vector2(x * TILE_SIZE, 0)
		line.color = Color(0, 0, 0, 0.08)
		floor_node.add_child(line)
	for y in range(FLOOR_HEIGHT + 1):
		var line := ColorRect.new()
		line.size = Vector2(FLOOR_WIDTH * TILE_SIZE, 1)
		line.position = Vector2(0, y * TILE_SIZE)
		line.color = Color(0, 0, 0, 0.08)
		floor_node.add_child(line)
	if floor_id == 0:
		_build_desks(floor_node)
	else:
		_build_facilities(floor_node, floor_id)

func _build_desks(parent: Node2D) -> void:
	var desk_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/tiles/desk_32x64_transparent.png"):
		desk_tex = load("res://assets/tiles/desk_32x64_transparent.png")
	for row in range(3):
		for col in range(4):
			var x: int = 3 + col * 4
			var y: int = 2 + row * 3
			if desk_tex:
				var spr := Sprite2D.new()
				spr.texture = desk_tex
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				spr.centered = false
				spr.scale = Vector2(2, 1)
				spr.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				parent.add_child(spr)
			else:
				var desk := ColorRect.new()
				desk.size = Vector2(TILE_SIZE * 2, TILE_SIZE)
				desk.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				desk.color = Color(0.35, 0.28, 0.18)
				parent.add_child(desk)
			# 显示器（带闪烁）
			var monitor := ColorRect.new()
			monitor.size = Vector2(10, 6)
			monitor.position = Vector2((x + 0.6) * TILE_SIZE, y * TILE_SIZE + 4)
			monitor.color = Color(0.3, 0.8, 1.0, 0.9)
			parent.add_child(monitor)
			var tween := monitor.create_tween().set_loops()
			tween.tween_property(monitor, "color:a", 0.3, randf_range(0.8, 2.0)).set_trans(Tween.TRANS_SINE)
			tween.tween_property(monitor, "color:a", 0.9, randf_range(0.8, 2.0)).set_trans(Tween.TRANS_SINE)

func _build_facilities(parent: Node2D, floor_id: int) -> void:
	var depts: Array = FLOORS[floor_id]["depts"]
	var idx := 0
	for dept_id in depts:
		var dept := GameState.get_dept(dept_id)
		var x: int = 2 + idx * 6
		var y: int = 3
		var rect := Rect2i(x, y, 5, 4)
		facility_tiles[dept_id] = rect
		# 背景框
		var panel := Panel.new()
		panel.position = Vector2(rect.position.x * TILE_SIZE, rect.position.y * TILE_SIZE)
		panel.size = Vector2(rect.size.x * TILE_SIZE, rect.size.y * TILE_SIZE)
		var style := StyleBoxFlat.new()
		if dept.level > 0:
			style.bg_color = Color(0.1, 0.15, 0.2, 0.7)
		else:
			style.bg_color = Color(0.2, 0.2, 0.25, 0.4)
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
			spr.position = Vector2(rect.size.x * TILE_SIZE / 2.0, rect.size.y * TILE_SIZE / 2.0)
			spr.scale = Vector2(1.2, 1.2)
			panel.add_child(spr)
			# 呼吸灯动画（透明度起伏）
			var tween := spr.create_tween().set_loops()
			tween.tween_property(spr, "modulate:a", 0.7, 1.5).set_trans(Tween.TRANS_SINE)
			tween.tween_property(spr, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
			# SOC 特殊：扫描线
			if dept_id == "soc":
				_add_soc_scanline(panel, rect)
		# 名称
		var name_lbl := Label.new()
		name_lbl.text = "%s %s Lv.%d" % [GameData.DEPARTMENTS[dept_id]["icon"], GameData.DEPARTMENTS[dept_id]["name"], dept.level]
		name_lbl.position = Vector2(6, 4)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		panel.add_child(name_lbl)
		# 未建成遮罩
		if dept.level == 0:
			var lock_lbl := Label.new()
			lock_lbl.text = "🔒 未建设"
			lock_lbl.position = Vector2(rect.size.x * TILE_SIZE / 2.0 - 30, rect.size.y * TILE_SIZE / 2.0 - 10)
			lock_lbl.add_theme_font_size_override("font_size", 12)
			panel.add_child(lock_lbl)
		idx += 1

func _add_soc_scanline(panel: Panel, rect: Rect2i) -> void:
	## SOC 大屏幕绿色扫描线
	var scan := ColorRect.new()
	scan.color = Color(0.2, 1.0, 0.5, 0.4)
	scan.size = Vector2(rect.size.x * TILE_SIZE - 20, 3)
	scan.position = Vector2(10, 10)
	panel.add_child(scan)
	var tween := scan.create_tween().set_loops()
	tween.tween_property(scan, "position:y", rect.size.y * TILE_SIZE - 20, 3.0).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(scan, "position:y", 10, 0.0)

func _refresh_floor_tabs() -> void:
	# 优先用外层 TabContainer 旁的 FloorTabBar（如果存在）
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
	## 从外层 main 场景拿 FloorTabBar 节点
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

func get_desk_position(desk_id: int) -> Vector2:
	if desk_id < 0:
		return Vector2(5, 5) * TILE_SIZE
	var row: int = desk_id / 4
	var col: int = desk_id % 4
	return Vector2((3 + col * 4 + 1) * TILE_SIZE, (2 + row * 3 + 1) * TILE_SIZE)

func get_facility_position(dept_id: String) -> Vector2:
	if not facility_tiles.has(dept_id):
		return Vector2(10, 6) * TILE_SIZE
	var rect: Rect2i = facility_tiles[dept_id]
	return Vector2((rect.position.x + rect.size.x / 2.0) * TILE_SIZE, (rect.position.y + rect.size.y / 2.0) * TILE_SIZE)

func _on_facility_clicked(event: InputEvent, dept_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		facility_clicked.emit(dept_id)

func refresh_all_employees() -> void:
	for emp in EmployeeRoster.employees:
		_spawn_employee(emp)
