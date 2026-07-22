extends Control
## 主场景控制器（瘦身版）：组装各面板，转发信号

const EMP_ROW_SCENE := preload("res://scenes/employee_row.tscn")
const INCIDENT_ROW_SCENE := preload("res://scenes/incident_row.tscn")

@onready var funds_label: Label = %FundsLabel
@onready var rep_label: Label = %RepLabel
@onready var rp_label: Label = %RpLabel
@onready var date_label: Label = %DateLabel
@onready var emp_count_label: Label = %EmpCountLabel
@onready var speed_buttons: HBoxContainer = %SpeedButtons
@onready var employee_list: VBoxContainer = %EmployeeList
@onready var incident_list: VBoxContainer = %IncidentList
@onready var dept_grid: GridContainer = %DeptGrid
@onready var alert_container: VBoxContainer = %AlertContainer
@onready var stats_label: Label = %StatsLabel
@onready var achievement_toast_container: VBoxContainer = %AchievementToastContainer

# 弹窗
@onready var hire_dialog: AcceptDialog = %HireDialog
@onready var hire_list: VBoxContainer = %HireList
@onready var train_dialog: AcceptDialog = %TrainDialog
@onready var train_list: VBoxContainer = %TrainList
@onready var gameover_dialog: AcceptDialog = %GameOverDialog
@onready var gameover_label: Label = %GameOverLabel
@onready var ng_plus_panel: PanelContainer = %NGPlusPanel
@onready var ng_plus_employee_list: VBoxContainer = %NGPlusEmployeeList
@onready var emp_detail_dialog: AcceptDialog = %EmpDetailDialog
@onready var emp_detail_vbox: VBoxContainer = %EmpDetailVBox
@onready var ranking_list: VBoxContainer = %RankingList
@onready var connection_list: VBoxContainer = %ConnectionList
@onready var shop_dialog: AcceptDialog = %ShopDialog
@onready var ceo_review_dialog: AcceptDialog = %CEOReviewDialog
@onready var ceo_review_vbox: VBoxContainer = %CEOReviewVBox
@onready var budget_dialog: AcceptDialog = %BudgetDialog
@onready var budget_vbox: VBoxContainer = %BudgetVBox
@onready var tutorial_overlay: CanvasLayer = %TutorialOverlay
@onready var ceo_label: Label = %CEOLabel
@onready var save_slot_dialog: AcceptDialog = %SaveSlotDialog
@onready var save_slot_list: VBoxContainer = %SaveSlotList
@onready var choice_dialog: AcceptDialog = %ChoiceDialog
@onready var choice_title: Label = %ChoiceTitle
@onready var choice_desc: Label = %ChoiceDesc
@onready var choice_options: VBoxContainer = %ChoiceOptions
@onready var achievement_dialog: AcceptDialog = %AchievementDialog
@onready var achievement_list: VBoxContainer = %AchievementList
@onready var award_dialog: AcceptDialog = %AwardDialog
@onready var award_content: VBoxContainer = %AwardContent
@onready var office_view: Node2D = %OfficeView

var candidates: Array[Employee] = []
var training_emp: Employee = null
var pending_choice_incident: Incident = null

func _ready() -> void:
	GameState.funds_changed.connect(_on_funds_changed)
	GameState.rep_changed.connect(_on_rep_changed)
	GameState.rp_changed.connect(_on_rp_changed)
	GameState.date_changed.connect(_on_date_changed)
	GameState.dept_upgraded.connect(_on_dept_upgraded)
	GameState.game_over.connect(_on_game_over)
	GameState.alert_message.connect(_on_alert)
	GameState.year_ended.connect(_on_year_ended)

	EmployeeRoster.employee_hired.connect(_on_employee_changed)
	EmployeeRoster.employee_fired.connect(_on_employee_changed)
	EmployeeRoster.employee_leveled.connect(_on_employee_leveled)
	EmployeeRoster.training_completed.connect(_on_training_completed)

	IncidentQueue.incident_spawned.connect(_on_incident_spawned)
	IncidentQueue.incident_resolved.connect(_on_incident_resolved)
	IncidentQueue.choice_required.connect(_on_choice_required)

	AchievementMgr.achievement_unlocked.connect(_on_achievement_unlocked)
	AwardMgr.award_ceremony_started.connect(_on_award_ceremony)
	CEOMgr.ceo_review_started.connect(_on_ceo_review)
	CEOMgr.budget_negotiation_started.connect(_on_budget_offer)

	_build_speed_buttons()
	_build_dept_grid()
	_refresh_all()
	_refresh_combo_display()
	_refresh_connections()
	# 加载 logo
	var logo_rect := get_node_or_null("RootVBox/TopBar/TopMargin/TopHBox/LogoRect")
	if logo_rect and ResourceLoader.exists("res://assets/illustrations/game_logo.jpg"):
		logo_rect.texture = load("res://assets/illustrations/game_logo.jpg")
	# CEO 名 + 公司名
	if ceo_label:
		ceo_label.text = "👔 %s @ %s" % [GameState.ceo_name, GameState.company_name]

	# 开局赠 2 名员工（如果无存档）
	if EmployeeRoster.employees.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for i in range(2):
			var emp := GameData.generate_candidate(EmployeeRoster.generate_id(), rng, GameState.reputation)
			emp.hire_cost = 0
			emp.join_year = GameState.year
			emp.join_month = GameState.month
			EmployeeRoster.employees.append(emp)
		EmployeeRoster.employee_hired.emit(EmployeeRoster.employees[0])
		_on_alert("欢迎就任安全部长！先招募员工开始工作吧", Color(0.5, 1.0, 0.7))

	# 为所有员工生成俯视图 agent
	if office_view:
		office_view.refresh_all_employees()

	# 首次启动新手教程（未看过教程标记）
	if tutorial_overlay and not _has_seen_tutorial():
		call_deferred("_start_tutorial")

const TUTORIAL_SEEN_PATH := "user://tutorial_seen.flag"

func _has_seen_tutorial() -> bool:
	return FileAccess.file_exists(TUTORIAL_SEEN_PATH)

func _mark_tutorial_seen() -> void:
	var f := FileAccess.open(TUTORIAL_SEEN_PATH, FileAccess.WRITE)
	if f:
		f.store_string("1")
		f.close()

func _refresh_all() -> void:
	_on_funds_changed(GameState.funds)
	_on_rep_changed(GameState.reputation)
	_on_rp_changed(GameState.research_points)
	_on_date_changed(GameState.year, GameState.month, GameState.day)
	_refresh_employees()
	_refresh_incidents()
	_refresh_stats()

# ---------- 顶部资源 ----------

func _on_funds_changed(v: int) -> void:
	funds_label.text = "💰 ¥%s" % _format_num(v)
	funds_label.modulate = Color(1.0, 0.4, 0.4) if v < 5000 else Color(1.0, 0.95, 0.6)
	_check_funds_achievements(v)
	# 低资金且未用过贷款：在资金标签旁弹"紧急贷款"按钮
	_update_emergency_loan_button(v)

var emergency_loan_btn: Button = null

func _update_emergency_loan_button(funds: int) -> void:
	var should_show: bool = funds < GameState.BANKRUPT_THRESHOLD and not GameState.has_used_emergency_loan
	if should_show and emergency_loan_btn == null:
		emergency_loan_btn = Button.new()
		emergency_loan_btn.text = "💼 紧急贷款"
		emergency_loan_btn.modulate = Color(1.0, 0.85, 0.4)
		emergency_loan_btn.tooltip_text = "CEO 特批 ¥%d（声誉 -%d），一次性" % [GameState.EMERGENCY_LOAN_AMOUNT, GameState.EMERGENCY_LOAN_REP_COST]
		emergency_loan_btn.pressed.connect(_on_emergency_loan)
		var top_hbox := funds_label.get_parent() as HBoxContainer
		if top_hbox:
			top_hbox.add_child(emergency_loan_btn)
			top_hbox.move_child(emergency_loan_btn, funds_label.get_index() + 1)
	elif not should_show and emergency_loan_btn != null:
		emergency_loan_btn.queue_free()
		emergency_loan_btn = null

func _on_emergency_loan() -> void:
	GameState.take_emergency_loan()
	_update_emergency_loan_button(GameState.funds)

func _on_rep_changed(v: int) -> void:
	rep_label.text = "⭐ %d/100" % v
	if v < 20: rep_label.modulate = Color(1.0, 0.4, 0.4)
	elif v >= 70: rep_label.modulate = Color(0.5, 1.0, 0.7)
	else: rep_label.modulate = Color.WHITE
	if v >= 50: AchievementMgr.unlock("rep_50")
	if v >= 100: AchievementMgr.unlock("rep_100")

func _on_rp_changed(v: int) -> void:
	rp_label.text = "🔬 %d RP" % v

func _on_date_changed(y: int, m: int, d: int) -> void:
	date_label.text = "📅 第%d年 %02d月 %02d日" % [y, m, d]
	_refresh_employees()
	_refresh_incidents()
	_refresh_stats()
	_refresh_rankings()

func _refresh_rankings() -> void:
	for c in ranking_list.get_children():
		c.queue_free()
	if AwardMgr.monthly_rankings.is_empty():
		AwardMgr.refresh_monthly_rankings()
	for i in range(AwardMgr.monthly_rankings.size()):
		var e: Dictionary = AwardMgr.monthly_rankings[i]
		var lbl := Label.new()
		var medal := ""
		match i:
			0: medal = "🥇"
			1: medal = "🥈"
			2: medal = "🥉"
			_: medal = "  %d." % (i+1)
		lbl.text = "%s %s  %.0f" % [medal, e["name"], e["score"]]
		lbl.add_theme_font_size_override("font_size", 11)
		if e["is_player"]:
			lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		ranking_list.add_child(lbl)

func _refresh_connections() -> void:
	for c in connection_list.get_children():
		c.queue_free()
	for conn in ConnectionMgr.connections:
		var row := HBoxContainer.new()
		var icon := Label.new()
		match conn.type:
			Connection.ConnectionType.HEADHUNTER: icon.text = "👔"
			Connection.ConnectionType.EXPERT: icon.text = "🎓"
			Connection.ConnectionType.VENDOR: icon.text = "🏢"
			Connection.ConnectionType.COMMUNITY: icon.text = "👥"
			Connection.ConnectionType.REGULATOR: icon.text = "🏛️"
		row.add_child(icon)
		var info := Label.new()
		info.text = "%s (%s)" % [conn.name, conn.get_relation_level()]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 11)
		row.add_child(info)
		connection_list.add_child(row)

func _check_funds_achievements(v: int) -> void:
	if v >= 100000: AchievementMgr.unlock("funds_100k")
	if v >= 1000000: AchievementMgr.unlock("funds_1m")

func _format_num(n: int) -> String:
	if n >= 1000000: return "%.2fM" % (n / 1000000.0)
	elif n >= 10000: return "%.1f万" % (n / 10000.0)
	return str(n)

func _refresh_stats() -> void:
	stats_label.text = "拦截 %d | 失守 %d | 员工 %d 人 | 成就 %d/%d" % [
		IncidentQueue.total_blocked, IncidentQueue.total_breached,
		EmployeeRoster.employees.size(),
		AchievementMgr.get_unlock_count(), AchievementMgr.get_total_count()
	]

# ---------- 速度控制 ----------

func _build_speed_buttons() -> void:
	for c in speed_buttons.get_children():
		c.queue_free()
	var labels := ["⏸", "▶", "▶▶", "▶▶▶"]
	for i in range(labels.size()):
		var b := Button.new()
		b.text = labels[i]
		b.custom_minimum_size = Vector2(48, 32)
		b.pressed.connect(_on_speed_pressed.bind(i))
		if i == GameState.speed:
			b.modulate = Color(0.6, 1.0, 0.7)
		speed_buttons.add_child(b)

func _on_speed_pressed(idx: int) -> void:
	GameState.set_speed(idx)
	for c in speed_buttons.get_children():
		c.modulate = Color.WHITE
	speed_buttons.get_child(idx).modulate = Color(0.6, 1.0, 0.7)

# ---------- 员工 ----------

func _on_employee_changed(_emp: Employee) -> void:
	_refresh_employees()
	_refresh_stats()

func _on_employee_leveled(emp: Employee) -> void:
	_on_alert("🎉 %s 升到 Lv.%d！" % [emp.name, emp.level], Color(1.0, 0.85, 0.4))

func _refresh_employees() -> void:
	for c in employee_list.get_children():
		c.queue_free()
	emp_count_label.text = "👥 %d/%d" % [EmployeeRoster.employees.size(), EmployeeRoster.MAX_EMPLOYEES]
	for emp in EmployeeRoster.employees:
		var row := EMP_ROW_SCENE.instantiate()
		employee_list.add_child(row)
		row.setup(emp)
		row.train_requested.connect(_on_emp_train)
		row.fire_requested.connect(_on_emp_fire)
		row.detail_requested.connect(_on_emp_detail)

func _on_emp_detail(emp: Employee) -> void:
	for c in emp_detail_vbox.get_children():
		c.queue_free()
	emp_detail_dialog.title = "%s Lv.%d" % [emp.name, emp.level]
	# 头部
	var head := HBoxContainer.new()
	emp_detail_vbox.add_child(head)
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(96, 96)
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_path := "res://assets/sprites/employees/%s_64_transparent.png" % _specialty_key_of(emp)
	if ResourceLoader.exists(tex_path):
		avatar.texture = load(tex_path)
	head.add_child(avatar)
	var head_info := VBoxContainer.new()
	head.add_child(head_info)
	_add_detail_label(head_info, "%s [%s]" % [emp.name, emp.get_specialty_name()], 18, emp.get_specialty_color())
	_add_detail_label(head_info, "性格：%s" % emp.get_personality_name(), 13)
	_add_detail_label(head_info, "在职 %d 天（%d 年 %d 月入职）" % [emp.stat_days_employed, emp.join_year, emp.join_month], 12, Color(0.7, 0.7, 0.7))
	if emp.is_veteran:
		_add_detail_label(head_info, "⭐ 二周目老兵", 12, Color(1.0, 0.85, 0.3))
	# 技能条
	emp_detail_vbox.add_child(HSeparator.new())
	_add_detail_label(emp_detail_vbox, "—— 能力 ——", 14, Color(0.8, 0.9, 1.0))
	_add_skill_bar(emp_detail_vbox, "威胁发现", emp.skill_detect, Color(1.0, 0.7, 0.3))
	_add_skill_bar(emp_detail_vbox, "事件分析", emp.skill_analyze, Color(0.9, 0.4, 0.5))
	_add_skill_bar(emp_detail_vbox, "应急响应", emp.skill_response, Color(0.4, 0.8, 1.0))
	_add_skill_bar(emp_detail_vbox, "培训教学", emp.skill_training, Color(0.5, 0.9, 0.6))
	_add_skill_bar(emp_detail_vbox, "技术研究", emp.skill_research, Color(0.8, 0.5, 1.0))
	# 战绩
	emp_detail_vbox.add_child(HSeparator.new())
	_add_detail_label(emp_detail_vbox, "—— 战绩 ——", 14, Color(0.8, 0.9, 1.0))
	_add_detail_label(emp_detail_vbox, "拦截 %d 次 | 失守 %d 次 | 完成培训 %d 次 | 累计经验 %d" % [
		emp.stat_blocked, emp.stat_breached, emp.stat_trainings_done, emp.stat_exp_gained
	], 12)
	_add_detail_label(emp_detail_vbox, "月薪 ¥%d | 疲劳 %d/100" % [emp.get_salary(), emp.fatigue], 12, Color(0.7, 0.7, 0.7))
	# 转职
	emp_detail_vbox.add_child(HSeparator.new())
	_add_detail_label(emp_detail_vbox, "—— 职业发展 ——", 14, Color(0.8, 0.9, 1.0))
	if emp.career_path == Employee.CareerPath.NONE:
		if emp.can_promote_career():
			_add_detail_label(emp_detail_vbox, "可选择转职方向（5 级解锁）：", 12)
			_add_career_button(emp_detail_vbox, emp, Employee.CareerPath.RED_TEAM, "🔴 红队（进攻）", "难度感知 -5%/级 | 经验 +10%/级")
			_add_career_button(emp_detail_vbox, emp, Employee.CareerPath.BLUE_TEAM, "🔵 蓝队（防御）", "进度 +8%/级 | 疲劳 -5%/级")
			_add_career_button(emp_detail_vbox, emp, Employee.CareerPath.PURPLE_TEAM, "🟣 紫队（研究）", "事件 +1RP/级 | 培训 +10%/级")
		else:
			_add_detail_label(emp_detail_vbox, "5 级后开放转职（当前 Lv.%d）" % emp.level, 12, Color(0.6, 0.6, 0.6))
	else:
		_add_detail_label(emp_detail_vbox, "已转职：%s" % emp.get_career_name(), 13, Color(1.0, 0.85, 0.3))
		var passive := emp.get_career_passive_bonus()
		for k in passive.keys():
			_add_detail_label(emp_detail_vbox, "  · %s %s" % [k, passive[k]], 11, Color(0.7, 0.9, 1.0))
		# 晋升
		if emp.career_tier < 3 and emp.can_promote_career():
			var upgrade_btn := Button.new()
			upgrade_btn.text = "晋升到 T%d（需 Lv.%d）" % [emp.career_tier + 1, emp.get_career_promote_level_req()]
			upgrade_btn.pressed.connect(_on_career_promote.bind(emp))
			emp_detail_vbox.add_child(upgrade_btn)
		elif emp.career_tier < 3:
			_add_detail_label(emp_detail_vbox, "晋升 T%d 需要 Lv.%d" % [emp.career_tier + 1, emp.get_career_promote_level_req()], 11, Color(0.6, 0.6, 0.6))
	emp_detail_dialog.popup_centered()

func _add_career_button(parent: Control, emp: Employee, path: Employee.CareerPath, title: String, desc: String) -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc_lbl)
	var btn := Button.new()
	btn.text = "选择这条路"
	btn.pressed.connect(_on_career_selected.bind(emp, path))
	vbox.add_child(btn)
	parent.add_child(panel)

func _on_career_selected(emp: Employee, path: Employee.CareerPath) -> void:
	emp.career_path = path
	emp.career_tier = 1
	_on_alert("🎖️ %s 转职为 %s！" % [emp.name, emp.get_career_name()], Color(1.0, 0.85, 0.3))
	emp_detail_dialog.hide()
	_on_emp_detail(emp)  # 重新打开刷新

func _on_career_promote(emp: Employee) -> void:
	emp.career_tier += 1
	_on_alert("⬆️ %s 晋升到 T%d！" % [emp.name, emp.career_tier], Color(0.5, 1.0, 0.7))
	emp_detail_dialog.hide()
	_on_emp_detail(emp)

func _add_detail_label(parent: Control, text: String, size: int, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

func _add_skill_bar(parent: Control, skill_name: String, value: int, color: Color) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = skill_name
	lbl.custom_minimum_size.x = 80
	hbox.add_child(lbl)
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value = value
	bar.custom_minimum_size = Vector2(0, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = true
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	hbox.add_child(bar)

func _on_emp_train(emp: Employee) -> void:
	training_emp = emp
	_show_train_dialog(emp)

func _on_emp_fire(emp: Employee) -> void:
	EmployeeRoster.fire(emp)
	_on_alert("已解雇 %s" % emp.name, Color(1.0, 0.7, 0.5))

# ---------- 招聘 ----------

func _on_hire_button_pressed() -> void:
	if EmployeeRoster.employees.size() >= EmployeeRoster.MAX_EMPLOYEES:
		_on_alert("员工已满（%d 上限）" % EmployeeRoster.MAX_EMPLOYEES, Color(1.0, 0.7, 0.4))
		return
	_refresh_candidates()
	hire_dialog.popup_centered()

func _refresh_candidates() -> void:
	candidates.clear()
	for c in hire_list.get_children():
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(3):
		var emp := GameData.generate_candidate(EmployeeRoster.generate_id(), rng, GameState.reputation)
		candidates.append(emp)
		var panel := PanelContainer.new()
		var hbox := HBoxContainer.new()
		panel.add_child(hbox)
		# 头像
		var avatar := TextureRect.new()
		avatar.custom_minimum_size = Vector2(64, 64)
		avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex_path := "res://assets/sprites/employees/%s_64_transparent.png" % _specialty_key_of(emp)
		if ResourceLoader.exists(tex_path):
			avatar.texture = load(tex_path)
		avatar.modulate = emp.get_appearance_modulate()
		hbox.add_child(avatar)
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		var name_label := Label.new()
		name_label.text = "%s [%s·%s] Lv.%d" % [emp.name, emp.get_specialty_name(), emp.get_personality_name(), emp.level]
		name_label.add_theme_color_override("font_color", emp.get_specialty_color())
		vbox.add_child(name_label)
		var skills_label := Label.new()
		skills_label.text = "发现%d 分析%d 响应%d 教学%d 研究%d | 平均 %.0f | 月薪 ¥%d" % [
			emp.skill_detect, emp.skill_analyze, emp.skill_response,
			emp.skill_training, emp.skill_research, emp.get_overall_skill(), emp.get_salary()
		]
		skills_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(skills_label)
		var hire_btn := Button.new()
		hire_btn.text = "录用 ¥%d" % emp.hire_cost
		hire_btn.pressed.connect(_on_hire_candidate.bind(emp, panel))
		if not GameState.can_afford(emp.hire_cost):
			hire_btn.disabled = true
		vbox.add_child(hire_btn)
		hire_list.add_child(panel)

func _specialty_key_of(emp: Employee) -> String:
	match emp.specialty:
		Employee.Specialty.GENERAL: return "general"
		Employee.Specialty.PHISHING: return "phishing"
		Employee.Specialty.MALWARE: return "malware"
		Employee.Specialty.NETWORK: return "network"
		Employee.Specialty.FORENSICS: return "forensics"
		Employee.Specialty.COMPLIANCE: return "compliance"
	return "general"

func _on_hire_candidate(emp: Employee, panel: PanelContainer) -> void:
	if EmployeeRoster.hire(emp):
		_on_alert("欢迎 %s 加入安全部！" % emp.name, Color(0.5, 1.0, 0.7))
		panel.queue_free()
		if EmployeeRoster.employees.size() >= EmployeeRoster.MAX_EMPLOYEES:
			hire_dialog.hide()

# ---------- 培训 ----------

func _show_train_dialog(emp: Employee) -> void:
	for c in train_list.get_children():
		c.queue_free()
	train_dialog.title = "培训 - %s (Lv.%d)" % [emp.name, emp.level]
	for course_id in GameData.COURSES.keys():
		var c = GameData.COURSES[course_id]
		# NG+ 课程过滤
		if c.get("ng_plus_only", false) and GameState.ng_plus_count == 0:
			continue
		var hbox := HBoxContainer.new()
		var info := Label.new()
		var duration := _get_course_duration(course_id)
		info.text = "%s %s | %d天 ¥%d | %s +%d (需 Lv.%d)" % [
			c["icon"], c["name"], duration, c["cost"],
			_skill_short(c["skill"]), c["boost"], c["level_req"]
		]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(info)
		var btn := Button.new()
		btn.text = "报名"
		if emp.level < c["level_req"]:
			btn.disabled = true
			btn.text = "Lv%d" % c["level_req"]
		elif not GameState.can_afford(c["cost"]):
			btn.disabled = true
		elif emp.is_training:
			btn.disabled = true
		else:
			btn.pressed.connect(_on_enroll_course.bind(emp, course_id))
		hbox.add_child(btn)
		train_list.add_child(hbox)
	train_dialog.popup_centered()

func _get_course_duration(course_id: String) -> int:
	var base: int = GameData.COURSES[course_id]["duration"]
	return max(1, int(base * GameState.get_training_duration_modifier()))

func _on_enroll_course(emp: Employee, course_id: String) -> void:
	var c = GameData.COURSES[course_id]
	if not GameState.spend_funds(c["cost"]):
		return
	var duration := _get_course_duration(course_id)
	emp.start_training(course_id, duration)
	_on_alert("%s 开始《%s》培训（%d天）" % [emp.name, c["name"], duration], Color(0.6, 0.9, 1.0))
	train_dialog.hide()
	_refresh_employees()

func _on_training_completed(_emp: Employee, _course_id: String) -> void:
	_refresh_employees()

func _skill_short(s: String) -> String:
	match s:
		"skill_detect": return "发现"
		"skill_analyze": return "分析"
		"skill_response": return "响应"
		"skill_training": return "教学"
		"skill_research": return "研究"
	return s

# ---------- 事件 ----------

func _on_incident_spawned(inc: Incident) -> void:
	_on_alert("🚨 %s - %s" % [inc.get_severity_name(), inc.name], inc.get_severity_color())
	_refresh_incidents()
	# 弹独立事件窗口（时间已暂停）
	_show_incident_dialog(inc)

func _on_incident_resolved(inc: Incident, success: bool) -> void:
	if success:
		_on_alert("✅ 成功处置 %s！+¥%d +%d⭐" % [inc.name, inc.fund_reward, inc.rep_reward], Color(0.5, 1.0, 0.7))
	else:
		_on_alert("💥 %s 处置失败！-¥%d -%d⭐" % [inc.name, inc.fund_penalty, inc.rep_penalty], Color(1.0, 0.4, 0.4))
	_refresh_incidents()
	_refresh_stats()

func _refresh_incidents() -> void:
	for c in incident_list.get_children():
		c.queue_free()
	if IncidentQueue.active_incidents.is_empty():
		var empty := Label.new()
		empty.text = "暂无安全事件 · 一切安好 ☕"
		empty.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		incident_list.add_child(empty)
		return
	for inc in IncidentQueue.active_incidents:
		var row := INCIDENT_ROW_SCENE.instantiate()
		incident_list.add_child(row)
		row.setup(inc)
		row.assign_requested.connect(_on_incident_assign)

func _on_incident_assign(inc: Incident, emp_id: int) -> void:
	IncidentQueue.assign(inc, emp_id)
	_refresh_incidents()

func _show_incident_dialog(inc: Incident) -> void:
	## 独立事件窗口：显示事件详情 + 分配员工
	var dialog := AcceptDialog.new()
	dialog.title = "🚨 安全事件"
	dialog.size = Vector2i(480, 400)
	dialog.transient = true
	dialog.exclusive = true
	var vbox := VBoxContainer.new()
	vbox.theme_override_constants.separation = 12
	dialog.add_child(vbox)
	# 标题
	var title := Label.new()
	title.text = "%s %s" % [inc.get_severity_name(), inc.name]
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", inc.get_severity_color())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	# 描述
	var desc := Label.new()
	desc.text = inc.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	# 属性
	var info := Label.new()
	info.text = "难度: %d  |  时限: %d 天  |  需要: %s" % [
		inc.difficulty, inc.days_remaining, _skill_short(inc.required_skill)
	]
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info)
	# 分配员工
	var assign_label := Label.new()
	assign_label.text = "选择处置员工："
	vbox.add_child(assign_label)
	var option := OptionButton.new()
	option.add_item("暂不分配（稍后处理）", -1)
	for emp in EmployeeRoster.employees:
		var label := "%s (%s%d)" % [emp.name, _skill_short(inc.required_skill), emp.get(inc.required_skill)]
		option.add_item(label, emp.id)
	vbox.add_child(option)
	# 按钮
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ok_btn := Button.new()
	ok_btn.text = "确认"
	ok_btn.custom_minimum_size = Vector2(120, 36)
	ok_btn.pressed.connect(func():
		var emp_id := option.get_selected_id()
		if emp_id >= 0:
			IncidentQueue.assign(inc, emp_id)
		dialog.queue_free()
		GameState.set_speed(1)  # 恢复时间
	)
	btn_row.add_child(ok_btn)
	var later_btn := Button.new()
	later_btn.text = "稍后处理"
	later_btn.custom_minimum_size = Vector2(120, 36)
	later_btn.pressed.connect(func():
		dialog.queue_free()
		GameState.set_speed(1)  # 恢复时间
	)
	btn_row.add_child(later_btn)
	vbox.add_child(btn_row)
	add_child(dialog)
	dialog.popup_centered()

# ---------- 事件选择树 ----------

func _on_choice_required(inc: Incident, node: IncidentChoiceNode) -> void:
	pending_choice_incident = inc
	choice_title.text = node.title
	choice_desc.text = node.description
	for c in choice_options.get_children():
		c.queue_free()
	var emp := EmployeeRoster.get_by_id(inc.assigned_employee_id)
	for opt in node.options:
		var btn := Button.new()
		var disabled := false
		var label_text: String = opt["text"]
		if opt.has("requirements") and emp:
			var req: Dictionary = opt["requirements"]
			var skill_name: String = req.get("skill", "")
			var min_val: int = req.get("min_value", 0)
			var emp_skill: int = emp.get(skill_name)
			if emp_skill < min_val:
				disabled = true
				label_text += " [需 %s %d]" % [_skill_short(skill_name), min_val]
		btn.text = label_text
		btn.disabled = disabled
		if opt.has("hint"):
			btn.tooltip_text = opt["hint"]
		btn.pressed.connect(_on_choice_selected.bind(opt))
		choice_options.add_child(btn)
	choice_dialog.popup_centered()

func _on_choice_selected(opt: Dictionary) -> void:
	if pending_choice_incident:
		IncidentQueue.apply_choice(pending_choice_incident, opt)
		pending_choice_incident = null
	choice_dialog.hide()
	_refresh_incidents()

# ---------- 部门 ----------

func _build_dept_grid() -> void:
	for c in dept_grid.get_children():
		c.queue_free()
	for dept_id in GameData.DEPARTMENTS.keys():
		var d = GameData.DEPARTMENTS[dept_id]
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)
		var header := HBoxContainer.new()
		var icon := Label.new()
		icon.text = d["icon"]
		icon.add_theme_font_size_override("font_size", 24)
		header.add_child(icon)
		var name_lbl := Label.new()
		name_lbl.text = d["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(name_lbl)
		vbox.add_child(header)
		var level_lbl := Label.new()
		level_lbl.name = "LevelLabel"
		vbox.add_child(level_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = d["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)
		var upgrade_btn := Button.new()
		upgrade_btn.name = "UpgradeButton"
		upgrade_btn.pressed.connect(_on_upgrade_dept.bind(dept_id))
		vbox.add_child(upgrade_btn)
		panel.set_meta("dept_id", dept_id)
		dept_grid.add_child(panel)
		_refresh_dept_panel(dept_id)

func _refresh_dept_panel(dept_id: String) -> void:
	for panel in dept_grid.get_children():
		if panel.get_meta("dept_id") != dept_id:
			continue
		var dept := GameState.get_dept(dept_id)
		var level_lbl: Label = panel.find_child("LevelLabel", true, false)
		var upgrade_btn: Button = panel.find_child("UpgradeButton", true, false)
		var max_lv: int = GameData.DEPARTMENTS[dept_id]["max_level"]
		var stars := ""
		for i in range(max_lv):
			stars += "★" if i < dept.level else "☆"
		level_lbl.text = "Lv.%d %s" % [dept.level, stars]
		level_lbl.add_theme_font_size_override("font_size", 12)
		if dept.level >= max_lv:
			upgrade_btn.text = "已满级"
			upgrade_btn.disabled = true
		else:
			var cost := GameData.get_dept_upgrade_cost(dept_id, dept.level + 1)
			upgrade_btn.text = ("建设 ¥%d" % cost) if dept.level == 0 else ("升级 ¥%d" % cost)
			upgrade_btn.disabled = not GameState.can_afford(cost)

func _on_upgrade_dept(dept_id: String) -> void:
	GameState.upgrade_dept(dept_id)

func _on_dept_upgraded(dept_id: String, _level: int) -> void:
	_refresh_dept_panel(dept_id)
	_refresh_combo_display()

func _refresh_combo_display() -> void:
	var active := GameState.get_active_combos()
	var combo_label := get_node_or_null("%ComboLabel")
	if combo_label == null:
		return
	if active.is_empty():
		combo_label.text = "💡 设施 combo：同层相邻建成即激活"
		combo_label.modulate = Color(0.6, 0.6, 0.6)
	else:
		var names: Array = []
		for c in active:
			names.append("【%s】" % c["name"])
		combo_label.text = "✨ 激活 combo：" + " ".join(names)
		combo_label.modulate = Color(1.0, 0.85, 0.3)

# ---------- 警报 ----------

func _on_alert(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	alert_container.add_child(lbl)
	while alert_container.get_child_count() > 8:
		alert_container.get_child(0).queue_free()
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tween.tween_callback(lbl.queue_free)

# ---------- 成就 Toast ----------

func _on_achievement_unlocked(ach: Dictionary) -> void:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	panel.add_child(hbox)
	# 成就徽章图（如果存在）
	var badge_path := "res://assets/illustrations/achievement_badge.jpg"
	if ResourceLoader.exists(badge_path):
		var badge := TextureRect.new()
		badge.texture = load(badge_path)
		badge.custom_minimum_size = Vector2(48, 48)
		badge.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(badge)
	else:
		var icon := Label.new()
		icon.text = ach.get("icon", "🏆")
		icon.add_theme_font_size_override("font_size", 28)
		hbox.add_child(icon)
	var vbox := VBoxContainer.new()
	hbox.add_child(vbox)
	var title := Label.new()
	title.text = "成就解锁！"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title)
	var name_lbl := Label.new()
	name_lbl.text = "%s %s" % [ach.get("icon", "🏆"), ach["name"]]
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)
	achievement_toast_container.add_child(panel)
	var tween := create_tween()
	tween.tween_interval(3.5)
	tween.tween_property(panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(panel.queue_free)
	_refresh_stats()

# ---------- 成就列表 ----------

func _on_achievement_button_pressed() -> void:
	for c in achievement_list.get_children():
		c.queue_free()
	var categories := ["经营", "养成", "防御", "建设", "彩蛋"]
	for cat in categories:
		var cat_label := Label.new()
		cat_label.text = "—— %s ——" % cat
		cat_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
		achievement_list.add_child(cat_label)
		for ach_id in GameData.ACHIEVEMENTS.keys():
			var ach = GameData.ACHIEVEMENTS[ach_id]
			if ach.get("category") != cat:
				continue
			var row := HBoxContainer.new()
			var icon := Label.new()
			var unlocked := AchievementMgr.is_unlocked(ach_id)
			icon.text = ach.get("icon", "🏆") if unlocked else "🔒"
			icon.custom_minimum_size.x = 32
			row.add_child(icon)
			var info := Label.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var text := "%s  %s" % [ach["name"], ach["desc"]]
			if ach.has("target") and ach["target"] > 1 and not unlocked:
				var prog: int = AchievementMgr.progress.get(ach_id, 0)
				text += "  (%d/%d)" % [prog, ach["target"]]
			info.text = text
			if not unlocked:
				info.modulate = Color(0.5, 0.5, 0.5)
			row.add_child(info)
			achievement_list.add_child(row)
	achievement_dialog.popup_centered()

# ---------- 年度奖项 ----------

func _on_year_ended(_y: int) -> void:
	pass  # 由 AwardMgr 处理并发 award_ceremony_started

func _on_award_ceremony(year: int, results: Dictionary) -> void:
	for c in award_content.get_children():
		c.queue_free()
	# 颁奖典礼背景插画
	var bg_path := "res://assets/illustrations/award_ceremony_bg.jpg"
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.custom_minimum_size = Vector2(0, 180)
		bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		award_content.add_child(bg)
	var title := Label.new()
	title.text = "第 %d 年度安全大奖" % year
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	award_content.add_child(title)
	var categories := [
		{"key": "defense", "name": "最佳防御"},
		{"key": "training", "name": "最佳培训"},
		{"key": "response", "name": "最佳响应"},
		{"key": "research", "name": "最佳研究"},
	]
	for cat in categories:
		var sep := HSeparator.new()
		award_content.add_child(sep)
		var cat_label := Label.new()
		cat_label.text = "【%s】" % cat["name"]
		cat_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		award_content.add_child(cat_label)
		var entries: Array = results["rankings"][cat["key"]]
		for i in range(entries.size()):
			var e = entries[i]
			var row := Label.new()
			var medal := ""
			match i:
				0: medal = "🥇"
				1: medal = "🥈"
				2: medal = "🥉"
				_: medal = "  %d." % (i+1)
			row.text = "%s %s  %.1f 分" % [medal, e["name"], e["score"]]
			if e["is_player"]:
				row.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
			award_content.add_child(row)
	# 总评
	var sep2 := HSeparator.new()
	award_content.add_child(sep2)
	var overall := Label.new()
	var overall_rank := AwardMgr.get_overall_rank(results)
	overall.text = "年度总评：第 %d 名 / 总分 %.1f" % [overall_rank, results["player_total_score"]]
	overall.add_theme_font_size_override("font_size", 16)
	overall.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if overall_rank == 1:
		overall.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		AchievementMgr.unlock("award_grand")
	award_content.add_child(overall)
	award_dialog.popup_centered()

# ---------- 游戏结束 ----------

var ng_plus_selected_veterans: Array[int] = []

func _on_game_over(reason: String) -> void:
	gameover_label.text = reason + "\n\n最终战绩：\n拦截 %d 次攻击\n失守 %d 次\n存活 %d 年 %d 月 %d 日\n成就 %d/%d" % [
		IncidentQueue.total_blocked, IncidentQueue.total_breached,
		GameState.year, GameState.month, GameState.day,
		AchievementMgr.get_unlock_count(), AchievementMgr.get_total_count()
	]
	# NG+ 解锁条件
	if NGPlusMgr.can_start_ng_plus():
		ng_plus_panel.visible = true
		_build_ng_plus_employee_list()
	else:
		ng_plus_panel.visible = false
	gameover_dialog.popup_centered()

func _build_ng_plus_employee_list() -> void:
	for c in ng_plus_employee_list.get_children():
		c.queue_free()
	ng_plus_selected_veterans.clear()
	for emp in EmployeeRoster.employees:
		var cb := CheckBox.new()
		cb.text = "%s Lv.%d (总技 %.0f)" % [emp.name, emp.level, emp.get_overall_skill()]
		cb.toggled.connect(_on_veteran_toggled.bind(emp.id, cb))
		ng_plus_employee_list.add_child(cb)

func _on_veteran_toggled(pressed: bool, emp_id: int, cb: CheckBox) -> void:
	if pressed:
		if ng_plus_selected_veterans.size() >= NGPlusMgr.VETERAN_COUNT:
			cb.set_pressed_no_signal(false)
			return
		ng_plus_selected_veterans.append(emp_id)
	else:
		ng_plus_selected_veterans.erase(emp_id)

func _on_restart() -> void:
	# 普通重开
	EmployeeRoster.reset()
	IncidentQueue.reset()
	GameState.is_game_over = false
	GameState.reset_for_new_game()
	get_tree().reload_current_scene()

func _on_ng_plus_start() -> void:
	# NG+ 重开
	if ng_plus_selected_veterans.is_empty():
		# 没选员工就退化为普通重开
		_on_restart()
		return
	var veteran_ids := ng_plus_selected_veterans.duplicate()
	NGPlusMgr.start_ng_plus(veteran_ids)
	gameover_dialog.hide()
	_refresh_all()
	if office_view:
		office_view.refresh_all_employees()

# ---------- 多存档槽 ----------

func _on_save_button_pressed() -> void:
	for c in save_slot_list.get_children():
		c.queue_free()
	# 自动槽
	_add_slot_button(SaveMgr.AUTO_SLOT, "自动存档")
	for i in range(1, SaveMgr.SLOT_COUNT + 1):
		_add_slot_button(i, "槽位 %d" % i)
	save_slot_dialog.popup_centered()

func _add_slot_button(slot: int, label: String) -> void:
	var hbox := HBoxContainer.new()
	var info := SaveMgr.get_slot_info(slot)
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if info.is_empty():
		lbl.text = "%s  [空]" % label
	else:
		var ng_text := " (NG+%d)" % info["ng_plus_count"] if info["ng_plus_count"] > 0 else ""
		lbl.text = "%s  第%d年%d月%d日  ¥%d  ⭐%d  👥%d%s" % [
			label, info["year"], info["month"], info["day"],
			info["funds"], info["reputation"], info["employee_count"], ng_text
		]
	hbox.add_child(lbl)
	var save_btn := Button.new()
	save_btn.text = "存入"
	save_btn.pressed.connect(_on_save_to_slot.bind(slot))
	hbox.add_child(save_btn)
	if not info.is_empty():
		var load_btn := Button.new()
		load_btn.text = "读取"
		load_btn.pressed.connect(_on_load_from_slot.bind(slot))
		hbox.add_child(load_btn)
	save_slot_list.add_child(hbox)

func _on_save_to_slot(slot: int) -> void:
	if SaveMgr.save(slot) == OK:
		_on_alert("已保存到槽位 %d" % slot, Color(0.5, 1.0, 0.7))
	else:
		_on_alert("保存失败", Color(1.0, 0.4, 0.4))
	save_slot_dialog.hide()

func _on_load_from_slot(slot: int) -> void:
	if SaveMgr.load(slot) == OK:
		_on_alert("已读取槽位 %d" % slot, Color(0.5, 1.0, 0.7))
		_refresh_all()
	else:
		_on_alert("读取失败", Color(1.0, 0.4, 0.4))
	save_slot_dialog.hide()

func _on_help_button_pressed() -> void:
	if tutorial_overlay:
		tutorial_overlay.start(self)
	else:
		_on_alert("💡 招募员工 → 派单处置事件 → 赚钱升级部门 → 抵御更强攻击", Color(0.8, 0.9, 1.0))

func _on_shop_button_pressed() -> void:
	shop_dialog.popup_centered()

func _start_tutorial() -> void:
	if tutorial_overlay:
		if not tutorial_overlay.tutorial_finished.is_connected(_on_tutorial_finished):
			tutorial_overlay.tutorial_finished.connect(_on_tutorial_finished)
		tutorial_overlay.start(self)

func _on_tutorial_finished() -> void:
	_mark_tutorial_seen()
	_on_alert("教程完成！开始你的安全部长生涯", Color(0.5, 1.0, 0.7))

# ---------- CEO 评价 + 预算谈判 ----------

func _on_ceo_review(review: Dictionary) -> void:
	if review.is_empty():
		return
	for c in ceo_review_vbox.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "CEO 季度评价"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ceo_review_vbox.add_child(title)
	var grade_lbl := Label.new()
	grade_lbl.text = "评级：%s" % review["grade_name"]
	grade_lbl.add_theme_font_size_override("font_size", 36)
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match review["grade_name"]:
		"S": grade_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		"A": grade_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		"B": grade_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		"C": grade_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		"D": grade_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	ceo_review_vbox.add_child(grade_lbl)
	var comment := Label.new()
	comment.text = review["comment"]
	comment.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ceo_review_vbox.add_child(comment)
	var stats := Label.new()
	stats.text = "拦截率 %.0f%%  ·  资金健康 %.0f%%  ·  团队稳定 %.0f%%" % [
		review["block_rate"] * 100, review["funds_score"] * 100, review["emp_stability"] * 100
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	ceo_review_vbox.add_child(stats)
	ceo_review_dialog.popup_centered()

func _on_budget_offer(offer: Dictionary) -> void:
	if offer.is_empty() or not offer.has("options"):
		return
	for c in budget_vbox.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "下季度预算谈判（CEO 评级 %s）" % offer["grade_name"]
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	budget_vbox.add_child(title)
	var hint := Label.new()
	hint.text = "选择一种预算方案："
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	budget_vbox.add_child(hint)
	for opt in offer["options"]:
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)
		var name_lbl := Label.new()
		name_lbl.text = "%s  +¥%d  +⭐%d" % [opt["name"], opt.get("funds", 0), opt.get("rep", 0)]
		name_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = opt["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)
		var btn := Button.new()
		btn.text = "选这个"
		btn.pressed.connect(_on_budget_chosen.bind(opt))
		vbox.add_child(btn)
		budget_vbox.add_child(panel)
	budget_dialog.popup_centered()

func _on_budget_chosen(opt: Dictionary) -> void:
	CEOMgr.apply_budget_choice(opt)
	_on_alert("💰 获得预算 ¥%d（%s）" % [opt.get("funds", 0), opt["name"]], Color(0.5, 1.0, 0.7))
	budget_dialog.hide()
