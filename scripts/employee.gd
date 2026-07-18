class_name Employee
extends RefCounted

## 员工 - 安全团队成员（v2：含战绩、工位、培训状态序列化、性格）

enum Specialty { GENERAL, PHISHING, MALWARE, NETWORK, FORENSICS, COMPLIANCE }
enum Personality { STEADY, HOT_HEAD, PERFECTIONIST, CURIOUS, LAID_BACK }
enum CareerPath { NONE, RED_TEAM, BLUE_TEAM, PURPLE_TEAM }  # 转职路径

var id: int
var name: String
var specialty: Specialty = Specialty.GENERAL
var personality: Personality = Personality.STEADY

# 五项能力（0-100）
var skill_detect: int = 10
var skill_analyze: int = 10
var skill_response: int = 10
var skill_training: int = 10
var skill_research: int = 10

var level: int = 1
var exp: int = 0
var fatigue: int = 0
var hire_cost: int = 0

# 培训状态
var is_training: bool = false
var training_course_id: String = ""
var training_days_left: int = 0

# 工位（俯视图用）
var desk_id: int = -1
var floor_id: int = 0  # 0=F1 1=F2 2=F3

# 个人战绩（年度奖项前置）
var stat_blocked: int = 0        # 累计拦截
var stat_breached: int = 0       # 累计失守（TA 是负责人时）
var stat_trainings_done: int = 0 # 完成培训次数
var stat_exp_gained: int = 0     # 累计获得经验
var stat_days_employed: int = 0  # 在职天数
var join_year: int = 1
var join_month: int = 4

# NG+ 继承标记
var is_veteran: bool = false  # 二周目继承的老兵

# 外貌变体（0-2，影响头像 modulate 色调）
var appearance_variant: int = 0

# 转职
var career_path: CareerPath = CareerPath.NONE
var career_tier: int = 0  # 0=未转职, 1-3=转职等级

const EXP_PER_LEVEL := 100
const MAX_FATIGUE := 100

signal leveled_up(emp: Employee)

func get_overall_skill() -> float:
	return (skill_detect + skill_analyze + skill_response + skill_training + skill_research) / 5.0

func get_specialty_name() -> String:
	match specialty:
		Specialty.GENERAL: return "综合"
		Specialty.PHISHING: return "钓鱼识别"
		Specialty.MALWARE: return "恶意软件"
		Specialty.NETWORK: return "网络安全"
		Specialty.FORENSICS: return "数字取证"
		Specialty.COMPLIANCE: return "合规审计"
	return "?"

func get_specialty_color() -> Color:
	match specialty:
		Specialty.GENERAL: return Color(0.7, 0.7, 0.7)
		Specialty.PHISHING: return Color(1.0, 0.7, 0.3)
		Specialty.MALWARE: return Color(0.9, 0.3, 0.4)
		Specialty.NETWORK: return Color(0.3, 0.7, 1.0)
		Specialty.FORENSICS: return Color(0.7, 0.4, 1.0)
		Specialty.COMPLIANCE: return Color(0.4, 0.9, 0.6)
	return Color.WHITE

func get_personality_name() -> String:
	match personality:
		Personality.STEADY: return "稳重"
		Personality.HOT_HEAD: return "急性子"
		Personality.PERFECTIONIST: return "完美主义"
		Personality.CURIOUS: return "好奇宝宝"
		Personality.LAID_BACK: return "佛系"
	return "?"

func get_appearance_modulate() -> Color:
	## 头像色调变体
	match appearance_variant:
		0: return Color(1.0, 1.0, 1.0)        # 原色
		1: return Color(1.0, 0.85, 0.85)      # 偏暖红
		2: return Color(0.85, 0.95, 1.0)      # 偏冷蓝
	return Color.WHITE

func get_career_name() -> String:
	if career_path == CareerPath.NONE:
		return ""
	match career_path:
		CareerPath.RED_TEAM: return "红队 T%d" % career_tier
		CareerPath.BLUE_TEAM: return "蓝队 T%d" % career_tier
		CareerPath.PURPLE_TEAM: return "紫队 T%d" % career_tier
	return ""

func can_promote_career() -> bool:
	## 是否可以转职/晋升
	if career_path == CareerPath.NONE:
		return level >= 5
	match career_tier:
		0: return level >= 5
		1: return level >= 10
		2: return level >= 18
	return false

func get_career_promote_level_req() -> int:
	if career_path == CareerPath.NONE or career_tier == 0:
		return 5
	match career_tier:
		1: return 10
		2: return 18
	return 999

func get_career_passive_bonus() -> Dictionary:
	## 转职被动加成
	if career_path == CareerPath.NONE or career_tier == 0:
		return {}
	match career_path:
		CareerPath.RED_TEAM:
			# 红队：攻击性强，事件难度感知 -5%/级
			return {"difficulty_perception": -0.05 * career_tier, "exp_mult": 1.0 + 0.1 * career_tier}
		CareerPath.BLUE_TEAM:
			# 蓝队：防御强，进度 +5%/级
			return {"progress_mult": 1.0 + 0.08 * career_tier, "fatigue_reduce": 0.05 * career_tier}
		CareerPath.PURPLE_TEAM:
			# 紫队：研究强，RP 事件 +1/级，培训效果 +10%/级
			return {"rp_per_incident": career_tier, "training_mult": 1.0 + 0.1 * career_tier}
	return {}

func get_personality_efficiency_modifier() -> float:
	## 性格带来的效率波动（每日随机 +/-）
	match personality:
		Personality.STEADY: return 1.0
		Personality.HOT_HEAD: return randf_range(0.85, 1.2)
		Personality.PERFECTIONIST: return 1.0  # 完美主义处理事件慢但质量高
		Personality.CURIOUS: return randf_range(0.9, 1.15)
		Personality.LAID_BACK: return 0.92
	return 1.0

func get_salary() -> int:
	return 800 + level * level * 150

func get_exp_needed() -> int:
	return EXP_PER_LEVEL * level

func add_exp(amount: int) -> bool:
	exp += amount
	stat_exp_gained += amount
	if exp >= get_exp_needed():
		exp -= get_exp_needed()
		level += 1
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var boost := rng.randi_range(2, 4)
		match rng.randi_range(0, 4):
			0: skill_detect = mini(100, skill_detect + boost)
			1: skill_analyze = mini(100, skill_analyze + boost)
			2: skill_response = mini(100, skill_response + boost)
			3: skill_training = mini(100, skill_training + boost)
			4: skill_research = mini(100, skill_research + boost)
		leveled_up.emit(self)
		return true
	return false

func add_fatigue(amount: int) -> void:
	fatigue = clampi(fatigue + amount, 0, MAX_FATIGUE)

func recover_fatigue(amount: int) -> void:
	fatigue = clampi(fatigue - amount, 0, MAX_FATIGUE)

func get_efficiency() -> float:
	var base := 1.0
	if fatigue >= 80: base = 0.4
	elif fatigue >= 60: base = 0.7
	elif fatigue >= 40: base = 0.9
	return base * get_personality_efficiency_modifier()

func start_training(course_id: String, days: int) -> void:
	is_training = true
	training_course_id = course_id
	training_days_left = days

func advance_training() -> bool:
	if not is_training:
		return false
	training_days_left -= 1
	if training_days_left <= 0:
		is_training = false
		return true
	return false

func to_dict() -> Dictionary:
	return {
		"id": id, "name": name, "specialty": specialty, "personality": personality,
		"skill_detect": skill_detect, "skill_analyze": skill_analyze,
		"skill_response": skill_response, "skill_training": skill_training,
		"skill_research": skill_research,
		"level": level, "exp": exp, "fatigue": fatigue,
		"hire_cost": hire_cost,
		"is_training": is_training, "training_course_id": training_course_id,
		"training_days_left": training_days_left,
		"desk_id": desk_id, "floor_id": floor_id,
		"stat_blocked": stat_blocked, "stat_breached": stat_breached,
		"stat_trainings_done": stat_trainings_done,
		"stat_exp_gained": stat_exp_gained,
		"stat_days_employed": stat_days_employed,
		"join_year": join_year, "join_month": join_month,
		"is_veteran": is_veteran,
		"appearance_variant": appearance_variant,
		"career_path": career_path,
		"career_tier": career_tier,
	}

static func from_dict(d: Dictionary) -> Employee:
	var e := Employee.new()
	e.id = d.get("id", 0)
	e.name = d.get("name", "")
	e.specialty = d.get("specialty", Specialty.GENERAL)
	e.personality = d.get("personality", Personality.STEADY)
	e.skill_detect = d.get("skill_detect", 10)
	e.skill_analyze = d.get("skill_analyze", 10)
	e.skill_response = d.get("skill_response", 10)
	e.skill_training = d.get("skill_training", 10)
	e.skill_research = d.get("skill_research", 10)
	e.level = d.get("level", 1)
	e.exp = d.get("exp", 0)
	e.fatigue = d.get("fatigue", 0)
	e.hire_cost = d.get("hire_cost", 0)
	e.is_training = d.get("is_training", false)
	e.training_course_id = d.get("training_course_id", "")
	e.training_days_left = d.get("training_days_left", 0)
	e.desk_id = d.get("desk_id", -1)
	e.floor_id = d.get("floor_id", 0)
	e.stat_blocked = d.get("stat_blocked", 0)
	e.stat_breached = d.get("stat_breached", 0)
	e.stat_trainings_done = d.get("stat_trainings_done", 0)
	e.stat_exp_gained = d.get("stat_exp_gained", 0)
	e.stat_days_employed = d.get("stat_days_employed", 0)
	e.join_year = d.get("join_year", 1)
	e.join_month = d.get("join_month", 4)
	e.is_veteran = d.get("is_veteran", false)
	e.appearance_variant = d.get("appearance_variant", 0)
	e.career_path = d.get("career_path", CareerPath.NONE)
	e.career_tier = d.get("career_tier", 0)
	return e
