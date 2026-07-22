extends Node
## ClientMgr autoload：客户系统

signal client_added(client: Client)
signal client_completed(client: Client, success: bool)

var clients: Array[Client] = []
var next_client_id: int = 1

const CLIENT_NAMES := ["腾讯", "阿里", "字节", "美团", "京东", "百度", "网易", "小米", "华为", "平安"]
const TASK_TYPES := ["pentest", "audit", "training", "incident_response"]

func _ready() -> void:
	# 每月 1 日生成新客户
	GameState.date_changed.connect(_on_date_changed)

func _on_date_changed(_y: int, _m: int, d: int) -> void:
	if d == 1:
		_generate_client()

func _generate_client() -> void:
	var rng := GameState.rng
	var c := Client.new()
	c.id = next_client_id
	next_client_id += 1
	c.name = CLIENT_NAMES[rng.randi_range(0, CLIENT_NAMES.size() - 1)]
	c.company = c.name + "科技"
	c.task_type = TASK_TYPES[rng.randi_range(0, TASK_TYPES.size() - 1)]
	c.difficulty = rng.randi_range(15, 50) + GameState.year * 5
	c.reward_funds = 3000 + c.difficulty * 100
	c.reward_rep = 1 + int(c.difficulty / 20)
	c.days_left = rng.randi_range(5, 10)
	clients.append(c)
	client_added.emit(c)
	GameState.alert_message.emit("📋 新客户委托：%s 的 %s（难度 %d）" % [c.company, c.get_type_name(), c.difficulty], Color(0.5, 0.9, 1.0))

func tick_day() -> void:
	for c in clients.duplicate():
		if c.is_done:
			continue
		if c.assigned_emp_id >= 0:
			var emp := EmployeeRoster.get_by_id(c.assigned_emp_id)
			if emp and not emp.is_training:
				var skill_val: int = emp.get("skill_detect")  # 简化：用威胁发现
				var ratio: float = float(skill_val) / max(1.0, float(c.difficulty))
				c.progress += clampf(20.0 + (ratio - 1.0) * 30.0, 5.0, 50.0)
				emp.add_fatigue(4)
				emp.add_exp(1)
		c.days_left -= 1
		if c.progress >= 100.0:
			_complete_client(c, true)
		elif c.days_left <= 0:
			_complete_client(c, false)

func _complete_client(c: Client, success: bool) -> void:
	c.is_done = true
	clients.erase(c)
	if success:
		GameState.add_funds(c.reward_funds)
		GameState.add_rep(c.reward_rep)
		GameState.alert_message.emit("✅ 完成客户委托：%s，获得 ¥%d +%d⭐" % [c.company, c.reward_funds, c.reward_rep], Color(0.5, 1.0, 0.7))
	else:
		GameState.add_rep(-2)
		GameState.alert_message.emit("❌ 客户委托失败：%s，声誉 -2" % c.company, Color(1.0, 0.5, 0.5))
	client_completed.emit(c, success)

func assign_emp(client_id: int, emp_id: int) -> void:
	for c in clients:
		if c.id == client_id:
			c.assigned_emp_id = emp_id
			return

func to_dict() -> Dictionary:
	return {"next_client_id": next_client_id, "clients": clients.map(func(c): return c.to_dict())}

func from_dict(d: Dictionary) -> void:
	next_client_id = d.get("next_client_id", 1)
	clients.clear()
	for c_data in d.get("clients", []):
		clients.append(Client.from_dict(c_data))
