extends Control
## 开始页主菜单：logo + 3 按钮（新游戏/读取存档/退出）

@onready var new_game_btn: Button = %NewGameButton
@onready var load_game_btn: Button = %LoadGameButton
@onready var quit_btn: Button = %QuitButton
@onready var logo_rect: TextureRect = %LogoRect
@onready var bg_rect: TextureRect = %BgRect
@onready var version_label: Label = %VersionLabel

# CEO 创建子面板
@onready var ceo_create_panel: PanelContainer = %CEOCreatePanel
@onready var ceo_name_input: LineEdit = %CEONameInput
@onready var company_name_input: LineEdit = %CompanyNameInput
@onready var avatar_grid: GridContainer = %AvatarGrid
@onready var start_btn: Button = %StartButton
@onready var back_btn: Button = %BackButton

# 存档选择子面板
@onready var save_list_panel: PanelContainer = %SaveListPanel
@onready var save_list: VBoxContainer = %SaveList
@onready var save_back_btn: Button = %SaveBackButton

var selected_avatar_id: int = 0
const AVATAR_KEYS := ["general", "phishing", "malware", "network", "forensics", "compliance"]

func _ready() -> void:
	# 加载背景
	if ResourceLoader.exists("res://assets/illustrations/menu_bg.jpg"):
		bg_rect.texture = load("res://assets/illustrations/menu_bg.jpg")
	if ResourceLoader.exists("res://assets/illustrations/game_logo.jpg"):
		logo_rect.texture = load("res://assets/illustrations/game_logo.jpg")
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	quit_btn.pressed.connect(_on_quit)
	start_btn.pressed.connect(_on_start_game)
	back_btn.pressed.connect(_on_back)
	save_back_btn.pressed.connect(_on_back)
	_build_avatar_grid()
	# 默认显示主按钮
	ceo_create_panel.visible = false
	save_list_panel.visible = false

func _build_avatar_grid() -> void:
	for c in avatar_grid.get_children():
		c.queue_free()
	for i in range(AVATAR_KEYS.size()):
		var key: String = AVATAR_KEYS[i]
		# 容器：TextureRect 显示头像，Button 透明覆盖处理点击
		var container := PanelContainer.new()
		container.custom_minimum_size = Vector2(72, 72)
		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex_path := "res://assets/sprites/employees/%s_64_transparent.png" % key
		if ResourceLoader.exists(tex_path):
			tex.texture = load(tex_path)
		container.add_child(tex)
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.toggle_mode = true
		btn.pressed.connect(_on_avatar_selected.bind(i, container))
		container.add_child(btn)
		container.set_meta("avatar_id", i)
		avatar_grid.add_child(container)
		if i == 0:
			btn.button_pressed = true
			_highlight_avatar(container, true)

func _highlight_avatar(container: PanelContainer, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(0.3, 0.6, 0.9, 0.4)
		style.border_color = Color(0.5, 0.85, 1.0)
		style.set_border_width_all(3)
	else:
		style.bg_color = Color(0.2, 0.25, 0.32, 0.5)
		style.border_color = Color(0.3, 0.35, 0.45)
		style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	container.add_theme_stylebox_override("panel", style)

func _on_avatar_selected(id: int, container: PanelContainer) -> void:
	selected_avatar_id = id
	for c in avatar_grid.get_children():
		_highlight_avatar(c, c == container)

func _on_new_game() -> void:
	ceo_create_panel.visible = true
	save_list_panel.visible = false

func _on_load_game() -> void:
	_build_save_list()
	save_list_panel.visible = true
	ceo_create_panel.visible = false

func _on_back() -> void:
	ceo_create_panel.visible = false
	save_list_panel.visible = false

func _build_save_list() -> void:
	for c in save_list.get_children():
		c.queue_free()
	# 自动槽
	_add_slot_row(SaveMgr.AUTO_SLOT, "自动存档")
	for i in range(1, SaveMgr.SLOT_COUNT + 1):
		_add_slot_row(i, "槽位 %d" % i)

func _add_slot_row(slot: int, label: String) -> void:
	var hbox := HBoxContainer.new()
	var info := SaveMgr.get_slot_info(slot)
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if info.is_empty():
		lbl.text = "%s  [空]" % label
		lbl.modulate = Color(0.5, 0.5, 0.5)
	else:
		var ng_text := " (NG+%d)" % info["ng_plus_count"] if info["ng_plus_count"] > 0 else ""
		lbl.text = "%s  第%d年%d月%d日  ¥%d  ⭐%d  👥%d%s" % [
			label, info["year"], info["month"], info["day"],
			info["funds"], info["reputation"], info["employee_count"], ng_text
		]
	hbox.add_child(lbl)
	if not info.is_empty():
		var load_btn := Button.new()
		load_btn.text = "读取"
		load_btn.custom_minimum_size = Vector2(80, 32)
		load_btn.pressed.connect(_on_load_slot.bind(slot))
		hbox.add_child(load_btn)
	save_list.add_child(hbox)

func _on_load_slot(slot: int) -> void:
	if SaveMgr.load(slot) == OK:
		_go_to_main()
	else:
		# 提示失败
		pass

func _on_start_game() -> void:
	var ceo_name := ceo_name_input.text.strip_edges()
	if ceo_name.is_empty():
		ceo_name = "安全部长"
	var company_name := company_name_input.text.strip_edges()
	if company_name.is_empty():
		company_name = "安创科技"
	# 重置并设置 CEO
	EmployeeRoster.reset()
	IncidentQueue.reset()
	GameState.reset_for_new_game()
	GameState.ceo_name = ceo_name
	GameState.company_name = company_name
	GameState.ceo_avatar_id = selected_avatar_id
	_go_to_main()

func _go_to_main() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit() -> void:
	get_tree().quit()
