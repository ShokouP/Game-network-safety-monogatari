extends Node
## ConnectionMgr autoload：人脉系统管理

signal connection_added(conn: Connection)
signal connection_updated(conn: Connection)

var connections: Array[Connection] = []
var next_conn_id: int = 1

func _ready() -> void:
	# 初始人脉
	_add_initial_connections()

func _add_initial_connections() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var initial := [
		{"name": "王猎头", "type": Connection.ConnectionType.HEADHUNTER, "specialty": "general"},
		{"name": "李教授", "type": Connection.ConnectionType.EXPERT, "specialty": "malware"},
		{"name": "安恒信息", "type": Connection.ConnectionType.VENDOR, "specialty": "network"},
	]
	for data in initial:
		var c := Connection.new()
		c.id = next_conn_id
		next_conn_id += 1
		c.name = data["name"]
		c.type = data["type"]
		c.specialty_bonus = data["specialty"]
		c.relation = rng.randi_range(10, 30)
		connections.append(c)

func add_relation(conn_id: int, amount: int) -> void:
	for c in connections:
		if c.id == conn_id:
			c.relation = clampi(c.relation + amount, 0, 100)
			connection_updated.emit(c)
			return

func get_hire_quality_bonus() -> float:
	## 猎头关系越好，招聘质量越高
	var bonus := 0.0
	for c in connections:
		if c.type == Connection.ConnectionType.HEADHUNTER:
			bonus += c.relation * 0.005  # 每点关系 +0.5% 质量
	return minf(bonus, 0.5)  # 上限 50%

func get_training_discount() -> float:
	## 专家关系越好，培训费用越低
	var discount := 0.0
	for c in connections:
		if c.type == Connection.ConnectionType.EXPERT:
			discount += c.relation * 0.003
	return minf(discount, 0.3)

func get_vendor_discount() -> float:
	## 供应商关系越好，部门建设费用越低
	var discount := 0.0
	for c in connections:
		if c.type == Connection.ConnectionType.VENDOR:
			discount += c.relation * 0.003
	return minf(discount, 0.3)

func to_dict() -> Dictionary:
	return {
		"next_conn_id": next_conn_id,
		"connections": connections.map(func(c): return c.to_dict()),
	}

func from_dict(d: Dictionary) -> void:
	next_conn_id = d.get("next_conn_id", 1)
	connections.clear()
	for c_data in d.get("connections", []):
		connections.append(Connection.from_dict(c_data))
