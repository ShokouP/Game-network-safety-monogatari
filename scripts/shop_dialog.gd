extends AcceptDialog
## 商店对话框

@onready var shop_list: VBoxContainer = %ShopList

func _ready() -> void:
	_build_shop()

func _build_shop() -> void:
	for c in shop_list.get_children():
		c.queue_free()
	for item in ShopData.ITEMS:
		var panel := PanelContainer.new()
		var hbox := HBoxContainer.new()
		panel.add_child(hbox)
		var icon := Label.new()
		icon.text = item["icon"]
		icon.add_theme_font_size_override("font_size", 24)
		hbox.add_child(icon)
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		var name_lbl := Label.new()
		name_lbl.text = item["name"]
		vbox.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = item["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(desc_lbl)
		var buy_btn := Button.new()
		buy_btn.text = "¥%d" % item["price"]
		buy_btn.disabled = not GameState.can_afford(item["price"])
		buy_btn.pressed.connect(_on_buy.bind(item))
		hbox.add_child(buy_btn)
		shop_list.add_child(panel)

func _on_buy(item: Dictionary) -> void:
	if not GameState.spend_funds(item["price"]):
		return
	_apply_item(item)
	GameState.alert_message.emit("🛒 购买了 %s" % item["name"], Color(0.5, 1.0, 0.7))
	_build_shop()  # 刷新按钮状态

func _apply_item(item: Dictionary) -> void:
	var effect: Dictionary = item["effect"]
	if effect.has("fatigue"):
		for emp in EmployeeRoster.employees:
			emp.add_fatigue(effect["fatigue"])
	if effect.has("fatigue_clear"):
		# 指定员工疲劳清零（简化：给最低疲劳员工用）
		var min_emp: Employee = null
		for emp in EmployeeRoster.employees:
			if min_emp == null or emp.fatigue < min_emp.fatigue:
				min_emp = emp
		if min_emp:
			min_emp.fatigue = 0
	if effect.has("rep"):
		GameState.add_rep(effect["rep"])
	if effect.has("rp"):
		GameState.add_rp(effect["rp"])
