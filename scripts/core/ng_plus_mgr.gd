extends Node
## NG+ 管理：二周目继承逻辑
## 继承：选 2 名员工（保留 50% 技能 + 等级减半）+ 称号 + 解锁高级课程 + 噩梦难度

signal ng_plus_started(count: int, veterans: Array[Employee])

const MIN_YEAR_FOR_NG := 5  # 至少存活 5 年才解锁 NG+
const VETERAN_COUNT := 2    # 可继承的员工数
const SKILL_KEEP_RATIO := 0.5
const LEVEL_KEEP_RATIO := 0.5

# 续作链：继承"隐形熟练度"（类型/题材等级，不继承员工/资金）
var genre_mastery: Dictionary = {}  # genre_id -> level (0-10)

func can_start_ng_plus() -> bool:
	return GameState.year >= MIN_YEAR_FOR_NG

func start_ng_plus(veteran_ids: Array[int]) -> void:
	## 进入二周目
	GameState.ng_plus_count += 1
	# 选出继承员工
	var veterans: Array[Employee] = []
	for vid in veteran_ids:
		for e in EmployeeRoster.employees:
			if e.id == vid:
				var v := _make_veteran(e)
				veterans.append(v)
				break
	# 重置游戏
	EmployeeRoster.reset()
	IncidentQueue.reset()
	GameState.reset_for_new_game()
	# 把继承员工放回
	for v in veterans:
		EmployeeRoster.employees.append(v)
	# 加起始资金奖励
	GameState.add_funds(20000)
	GameState.add_rp(50)
	AchievementMgr.unlock("ng_plus")
	ng_plus_started.emit(GameState.ng_plus_count, veterans)

func _make_veteran(source: Employee) -> Employee:
	var v := Employee.new()
	v.id = EmployeeRoster.generate_id()
	v.name = source.name + "★"
	v.specialty = source.specialty
	v.personality = source.personality
	v.skill_detect = int(source.skill_detect * SKILL_KEEP_RATIO)
	v.skill_analyze = int(source.skill_analyze * SKILL_KEEP_RATIO)
	v.skill_response = int(source.skill_response * SKILL_KEEP_RATIO)
	v.skill_training = int(source.skill_training * SKILL_KEEP_RATIO)
	v.skill_research = int(source.skill_research * SKILL_KEEP_RATIO)
	v.level = max(1, int(source.level * LEVEL_KEEP_RATIO))
	v.exp = 0
	v.fatigue = 0
	v.hire_cost = 0
	v.is_veteran = true
	return v

# ---------- 续作链：熟练度继承 ----------

func add_genre_mastery(genre_id: String, amount: int) -> void:
	## 增加类型熟练度（处置某类事件多了就熟练）
	genre_mastery[genre_id] = mini(10, genre_mastery.get(genre_id, 0) + amount)

func get_genre_mastery(genre_id: String) -> int:
	return genre_mastery.get(genre_id, 0)

func get_mastery_bonus(genre_id: String) -> float:
	## 熟练度加成：每级 +5% 效率
	return 1.0 + get_genre_mastery(genre_id) * 0.05

func to_dict() -> Dictionary:
	return {
		"genre_mastery": genre_mastery,
	}

func from_dict(d: Dictionary) -> void:
	genre_mastery = d.get("genre_mastery", {})
