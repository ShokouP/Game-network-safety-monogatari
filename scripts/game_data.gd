class_name GameData
extends RefCounted
## GameData 静态数据库

const DEPARTMENTS := {
	"training_room": {
		"name": "培训教室", "icon": "📚",
		"desc": "每级缩短培训周期 10%",
		"max_level": 5, "base_cost": 8000, "cost_growth": 1.8, "upkeep_per_level": 300,
	},
	"soc": {
		"name": "SOC 监控中心", "icon": "🖥️",
		"desc": "提升威胁发现率，每日小概率自动拦截",
		"max_level": 5, "base_cost": 15000, "cost_growth": 2.0, "upkeep_per_level": 600,
	},
	"lab": {
		"name": "研究实验室", "icon": "🔬",
		"desc": "每月产出研究点；提升培训效果 15%/级",
		"max_level": 5, "base_cost": 12000, "cost_growth": 1.9, "upkeep_per_level": 500,
	},
	"forensics": {
		"name": "取证分析室", "icon": "🔍",
		"desc": "降低事件难度 8%/级",
		"max_level": 5, "base_cost": 10000, "cost_growth": 1.85, "upkeep_per_level": 400,
	},
	"pr_office": {
		"name": "公关办公室", "icon": "📢",
		"desc": "事件失败时声誉损失降低 15%/级",
		"max_level": 5, "base_cost": 9000, "cost_growth": 1.7, "upkeep_per_level": 350,
	},
	"lounge": {
		"name": "员工休息区", "icon": "☕",
		"desc": "每日疲劳恢复 +2/级",
		"max_level": 5, "base_cost": 6000, "cost_growth": 1.6, "upkeep_per_level": 200,
	},
}

const COURSES := {
	"phish_basic":    {"name": "钓鱼识别基础", "icon": "🎣", "desc": "识别常见钓鱼邮件手法", "duration": 3, "cost": 1500, "skill": "skill_detect", "boost": 8, "level_req": 1},
	"phish_adv":      {"name": "高级钓鱼对抗", "icon": "🐟", "desc": "鱼叉式钓鱼进阶", "duration": 5, "cost": 5000, "skill": "skill_detect", "boost": 15, "level_req": 5},
	"malware_analysis": {"name": "恶意软件分析", "icon": "🦠", "desc": "静态与动态样本分析", "duration": 7, "cost": 8000, "skill": "skill_analyze", "boost": 18, "level_req": 3},
	"ir_bootcamp":    {"name": "应急响应集训", "icon": "🚨", "desc": "红蓝对抗演练", "duration": 5, "cost": 6000, "skill": "skill_response", "boost": 15, "level_req": 2},
	"forensics_cert": {"name": "数字取证认证", "icon": "🔎", "desc": "取证流程与证据链", "duration": 8, "cost": 12000, "skill": "skill_analyze", "boost": 22, "level_req": 8},
	"teach_skill":    {"name": "内训师养成", "icon": "👨‍🏫", "desc": "面向全员的安全讲师", "duration": 4, "cost": 4000, "skill": "skill_training", "boost": 14, "level_req": 2},
	"research_method": {"name": "威胁情报研究", "icon": "📊", "desc": "追踪 APT 组织", "duration": 6, "cost": 9000, "skill": "skill_research", "boost": 18, "level_req": 5},
	"zero_day_hunt":  {"name": "0day 狩猎研修", "icon": "🎯", "desc": "顶尖漏洞挖掘", "duration": 10, "cost": 25000, "skill": "skill_research", "boost": 30, "level_req": 12},
	# NG+ 解锁
	"red_team_ops":   {"name": "红队作战艺术", "icon": "⚔️", "desc": "进攻性安全专家", "duration": 12, "cost": 40000, "skill": "skill_research", "boost": 40, "level_req": 15, "ng_plus_only": true},
	"apt_hunting":    {"name": "APT 追踪猎杀", "icon": "🏹", "desc": "国家级威胁狩猎", "duration": 15, "cost": 60000, "skill": "skill_research", "boost": 50, "level_req": 18, "ng_plus_only": true},
	"cyber_psych":    {"name": "网络心理战", "icon": "🧠", "desc": "对抗社工的心理学", "duration": 10, "cost": 35000, "skill": "skill_detect", "boost": 35, "level_req": 15, "ng_plus_only": true},
}

const INCIDENT_TYPES := {
	"phishing":     {"name": "钓鱼邮件攻击", "desc": "财务收到伪造CEO的转账请求邮件", "required_skill": "skill_detect", "base_difficulty": 15, "severity": 0, "weight": 30},
	"malware":      {"name": "恶意软件感染", "desc": "员工电脑检测到可疑进程外联", "required_skill": "skill_analyze", "base_difficulty": 25, "severity": 1, "weight": 25},
	"ransomware":   {"name": "勒索软件爆发", "desc": "文件服务器大量文件被加密", "required_skill": "skill_response", "base_difficulty": 50, "severity": 3, "weight": 10},
	"ddos":         {"name": "DDoS 攻击", "desc": "官网遭受大流量攻击，业务中断", "required_skill": "skill_response", "base_difficulty": 35, "severity": 2, "weight": 15},
	"insider":      {"name": "内部数据泄露", "desc": "敏感客户数据出现在暗网出售", "required_skill": "skill_analyze", "base_difficulty": 45, "severity": 3, "weight": 8},
	"supply_chain": {"name": "供应链攻击", "desc": "第三方软件更新包被植入后门", "required_skill": "skill_research", "base_difficulty": 60, "severity": 3, "weight": 5},
	"social_eng":   {"name": "社会工程入侵", "desc": "攻击者伪装IT人员骗取员工账号", "required_skill": "skill_detect", "base_difficulty": 30, "severity": 1, "weight": 18},
	"zero_day":     {"name": "0day 漏洞利用", "desc": "核心业务系统发现未公开漏洞被利用", "required_skill": "skill_research", "base_difficulty": 70, "severity": 3, "weight": 3},
	"web_attack":   {"name": "Web 应用入侵", "desc": "官网检测到 SQL 注入尝试", "required_skill": "skill_response", "base_difficulty": 28, "severity": 1, "weight": 20},
	"apt":          {"name": "APT 持续渗透", "desc": "发现长期潜伏的高级威胁组织", "required_skill": "skill_research", "base_difficulty": 80, "severity": 3, "weight": 2},
}

# 设施相性 combo（同层相邻自动触发）
const DEPT_COMBOS := {
	"soc+forensics": {
		"name": "快速溯源",
		"desc": "SOC + 取证室同层：事件难度 -5%",
		"effect": {"difficulty_mult": 0.95},
	},
	"training_room+lounge": {
		"name": "寓教于乐",
		"desc": "培训室 + 休息区同层：培训效果 +15%",
		"effect": {"training_boost_mult": 1.15},
	},
	"lab+pr_office": {
		"name": "成果转化",
		"desc": "实验室 + 公关同层：每月 RP +2",
		"effect": {"monthly_rp_bonus": 2},
	},
	"soc+training_room": {
		"name": "实战教学",
		"desc": "SOC + 培训室同层：事件经验 +20%",
		"effect": {"incident_exp_mult": 1.2},
	},
	"forensics+lab": {
		"name": "深度研究",
		"desc": "取证室 + 实验室同层：实验室 RP 产出 +30%",
		"effect": {"lab_rp_mult": 1.3},
	},
}

# 楼层映射（用于 combo 判定）
const DEPT_FLOOR := {
	"training_room": 1, "soc": 1, "lounge": 1,
	"lab": 2, "forensics": 2, "pr_office": 2,
}

# 彩蛋随机事件池（月度触发，参考真实安全圈梗）
const FLAVOR_EVENTS := [
	{"id": "log4j", "name": "Log4j 核弹级漏洞爆发",
	 "desc": "全网应急！所有 Java 应用都要排查",
	 "effect": {"funds": -3000, "rep": 5, "rp": 10}, "weight": 3, "min_year": 1},
	{"id": "password_on_screen", "name": "员工把密码贴在显示器上",
	 "desc": "巡检发现某员工显示器边框贴着便利贴：admin123",
	 "effect": {"rep": -2, "funds": -500}, "weight": 8, "min_year": 1},
	{"id": "ceo_phished", "name": "老板被钓鱼",
	 "desc": "CEO 点开『年度分红通知』邮件，账号被盗",
	 "effect": {"funds": -5000, "rep": -3}, "weight": 5, "min_year": 2},
	{"id": "bug_bounty", "name": "白帽子提交漏洞",
	 "desc": "外部研究员在 SRC 提交了一个高危漏洞",
	 "effect": {"funds": -2000, "rep": 8, "rp": 5}, "weight": 6, "min_year": 1},
	{"id": "compliance_audit", "name": "等保年度审核",
	 "desc": "监管机构来做等保合规检查",
	 "effect": {"rep": 3, "rp": 3}, "weight": 7, "min_year": 1},
	{"id": "vendor_notice", "name": "供应商漏洞通告",
	 "desc": "某核心供应商发布紧急补丁，需立刻跟进",
	 "effect": {"rp": 5}, "weight": 8, "min_year": 1},
	{"id": "screen_leak", "name": "员工直播泄露屏幕",
	 "desc": "某员工直播游戏时不慎露出公司内部系统",
	 "effect": {"rep": -5, "funds": -2000}, "weight": 3, "min_year": 2},
	{"id": "pentest_win", "name": "红队演练大胜",
	 "desc": "内部红蓝对抗，蓝队成功守住所有关键资产",
	 "effect": {"rep": 5, "rp": 8}, "weight": 6, "min_year": 2},
	{"id": "cert_pass", "name": "员工通过 CISSP",
	 "desc": "团队又有 1 人拿下国际认证",
	 "effect": {"rep": 3}, "weight": 8, "min_year": 1},
	{"id": "ai_attack", "name": "AI 换脸诈骗",
	 "desc": "财务收到『老板』视频通话要求转账，所幸被识破",
	 "effect": {"rep": 4, "rp": 5}, "weight": 4, "min_year": 3},
	{"id": "open_source_scare", "name": "开源组件投毒",
	 "desc": "某流行 npm 包被植入恶意代码，紧急排查",
	 "effect": {"funds": -1500, "rp": 3}, "weight": 6, "min_year": 2},
	{"id": "media_interview", "name": "媒体专访",
	 "desc": "安全团队上了行业杂志封面",
	 "effect": {"rep": 8}, "weight": 3, "min_year": 3},
	{"id": "wifi_pineapple", "name": "楼下车库发现 WiFi 菠萝",
	 "desc": "巡检发现可疑无线设备，已清除",
	 "effect": {"rep": 2, "rp": 2}, "weight": 5, "min_year": 1},
	{"id": "backup_hero", "name": "备份立功",
	 "desc": "测试环境勒索演练中，备份系统 5 分钟完成恢复",
	 "effect": {"rep": 4}, "weight": 6, "min_year": 1},
	{"id": "intern_mistake", "name": "实习生误删数据库",
	 "desc": "幸好是测试环境，但敲响了警钟",
	 "effect": {"funds": -800, "rep": -1}, "weight": 5, "min_year": 1},
	{"id": "security_month", "name": "安全意识月",
	 "desc": "全员参与度爆表，钓鱼点击率降至 0.1%",
	 "effect": {"rep": 5, "rp": 3}, "weight": 7, "min_year": 1},
]

const CANDIDATE_NAMES := [
	"林小盾", "王加密", "张防火", "李漏洞", "赵蜜罐",
	"陈入侵", "周逆向", "吴安全", "郑审计", "孙补丁",
	"钱密码", "冯沙箱", "朱隔离", "秦取证", "许权限",
	"何基线", "吕等保", "施渗透", "张韧性", "孔指纹",
	"曹威胁", "严嗅探", "华令牌", "金密钥", "魏流量",
	"陶态势", "姜预警", "戚溯源", "谢备份", "邹红队",
]

# 成就（50+，5 类）
const ACHIEVEMENTS := {
	# 经营
	"hire_1":        {"name": "初建团队", "desc": "招募第 1 名员工", "icon": "👤", "category": "经营", "target": 1},
	"hire_5":        {"name": "兵强马壮", "desc": "累计招募 5 名员工", "icon": "👥", "category": "经营", "target": 5},
	"hire_12":       {"name": "满编作战", "desc": "员工满编 12 人", "icon": "🎖️", "category": "经营", "target": 12},
	"funds_100k":    {"name": "小有积蓄", "desc": "账上现金达到 10 万", "icon": "💰", "category": "经营", "target": 1, "check": "funds>=100000"},
	"funds_1m":      {"name": "资金雄厚", "desc": "账上现金达到 100 万", "icon": "💎", "category": "经营", "target": 1, "check": "funds>=1000000"},
	"rep_50":        {"name": "崭露头角", "desc": "声誉达到 50", "icon": "⭐", "category": "经营", "target": 1, "check": "rep>=50"},
	"rep_100":       {"name": "业界传奇", "desc": "声誉达到 100", "icon": "🌟", "category": "经营", "target": 1, "check": "rep>=100", "reward_rp": 50},
	# 养成
	"emp_level_10":  {"name": "中坚力量", "desc": "任一名员工达到 Lv.10", "icon": "🔥", "category": "养成", "target": 1},
	"emp_level_20":  {"name": "安全专家", "desc": "任一名员工达到 Lv.20", "icon": "👑", "category": "养成", "target": 1},
	"emp_level_30":  {"name": "传说黑客", "desc": "任一名员工达到 Lv.30", "icon": "⚡", "category": "养成", "target": 1, "reward_rp": 100},
	"train_5":       {"name": "学以致用", "desc": "完成 5 次培训", "icon": "📚", "category": "养成", "target": 5},
	"train_20":      {"name": "学无止境", "desc": "完成 20 次培训", "icon": "🎓", "category": "养成", "target": 20},
	"skill_max":     {"name": "登峰造极", "desc": "任一员工单项技能达到 100", "icon": "🏔️", "category": "养成", "target": 1},
	# 防御
	"block_10":      {"name": "初次亮剑", "desc": "累计拦截 10 次攻击", "icon": "🛡️", "category": "防御", "target": 10},
	"block_50":      {"name": "固若金汤", "desc": "累计拦截 50 次攻击", "icon": "🏰", "category": "防御", "target": 50},
	"block_100":     {"name": "铜墙铁壁", "desc": "累计拦截 100 次攻击", "icon": "🗼", "category": "防御", "target": 100, "reward_funds": 20000},
	"block_500":     {"name": "千里之堤", "desc": "累计拦截 500 次攻击", "icon": "🌊", "category": "防御", "target": 500, "reward_rp": 200},
	"block_critical_10": {"name": "危机终结者", "desc": "成功处置 10 起严重事件", "icon": "🚨", "category": "防御", "target": 10, "reward_rep": 10},
	"block_fast_5":  {"name": "闪电处置", "desc": "1 天内解决 5 起事件", "icon": "⚡", "category": "防御", "target": 5},
	"perfect_year":  {"name": "无懈可击", "desc": "一年内 0 失守（至少拦截 5 次）", "icon": "🏆", "category": "防御", "target": 1, "reward_funds": 50000, "reward_rep": 20},
	"breach_5":      {"name": "从失败中学习", "desc": "累计 5 次失守", "icon": "💔", "category": "防御", "target": 5},
	"breach_critical_1": {"name": "血的教训", "desc": "失守 1 起严重事件", "icon": "🩸", "category": "防御", "target": 1},
	# 建设
	"dept_total_5":  {"name": "初具规模", "desc": "部门总等级达到 5", "icon": "🏢", "category": "建设", "target": 1},
	"dept_total_15": {"name": "体系完备", "desc": "部门总等级达到 15", "icon": "🏬", "category": "建设", "target": 1},
	"dept_all_built": {"name": "六大部门", "desc": "所有部门都建成", "icon": "🏗️", "category": "建设", "target": 1},
	"dept_all_max":  {"name": "尽善尽美", "desc": "所有部门都满级", "icon": "🌆", "category": "建设", "target": 1, "reward_rp": 500},
	# 彩蛋
	"survive_5y":    {"name": "五载守望", "desc": "存活 5 年", "icon": "📅", "category": "彩蛋", "target": 5},
	"survive_10y":   {"name": "十年磨剑", "desc": "存活 10 年", "icon": "🗡️", "category": "彩蛋", "target": 10, "reward_rp": 300},
	"award_first":   {"name": "首次封王", "desc": "获得任意年度奖项第一", "icon": "🥇", "category": "彩蛋", "target": 1},
	"award_grand":   {"name": "年度总冠军", "desc": "年度总评第一", "icon": "👑", "category": "彩蛋", "target": 1, "reward_funds": 100000},
	"ng_plus":       {"name": "新的征程", "desc": "开始二周目", "icon": "🔄", "category": "彩蛋", "target": 1},
}

# 事件选择树（每个事件 2-3 个节点：mid 50% 进度时 + final 完成时）
const CHOICE_TREES := {
	"phishing": {
		"mid": {
			"id": "phishing_mid", "title": "钓鱼邮件溯源",
			"description": "你追踪到攻击者的 C2 服务器位于境外。选择处置方式：",
			"options": [
				{"text": "立即阻断（保险）", "hint": "直接封锁 IP，无风险", "effects": {"progress": 30}},
				{"text": "蜜罐诱捕（需 40+ 分析）", "hint": "部署蜜罐，可能抓到更多情报", "requirements": {"skill": "skill_analyze", "min_value": 40}, "effects": {"progress": 10, "rep": 3, "exp": 20}},
				{"text": "联系执法机关", "hint": "上报公安，可能提升声誉但延长处置时间", "effects": {"days_delta": -1, "rep": 5, "funds": -1000}},
			],
		},
		"final": {
			"id": "phishing_final", "title": "善后处置",
			"description": "钓鱼邮件已清除。如何防止类似事件再次发生？",
			"options": [
				{"text": "全员通报", "hint": "提高全员警觉，小幅提升声誉", "effects": {"rep": 2}},
				{"text": "开展钓鱼演练", "hint": "消耗经费进行全员演练", "effects": {"funds": -2000, "exp": 30}},
				{"text": "算了，继续工作", "hint": "无额外效果", "effects": {}},
			],
		},
	},
	"ransomware": {
		"mid": {
			"id": "ransomware_mid", "title": "勒索信交涉",
			"description": "攻击者发来勒索信：支付 5 万赎金换回密钥。你的选择：",
			"options": [
				{"text": "拒绝支付，从备份恢复", "hint": "需要完善备份，扣经费", "effects": {"funds": -3000, "progress": 20}},
				{"text": "尝试解密（需 60+ 响应）", "hint": "寻找已知解密工具", "requirements": {"skill": "skill_response", "min_value": 60}, "effects": {"progress": 50, "exp": 40}},
				{"text": "谈判周旋", "hint": "拖延时间争取恢复，风险：可能升级", "effects": {"days_delta": 1, "difficulty_delta": 20}},
			],
		},
	},
	"insider": {
		"final": {
			"id": "insider_final", "title": "内鬼处置",
			"description": "确认是市场部张某泄露了数据。如何处置？",
			"options": [
				{"text": "移交司法", "hint": "追责到底，提升声誉", "effects": {"rep": 8, "funds": -5000}},
				{"text": "内部处理", "hint": "低调开除，保住颜面", "effects": {"rep": -2, "funds": 0}},
				{"text": "教育挽留", "hint": "给对方一次机会，可能埋下隐患", "effects": {"rep": 3, "difficulty_delta": 10}},
			],
		},
	},
	"apt": {
		"mid": {
			"id": "apt_mid", "title": "APT 追踪",
			"description": "发现攻击者使用了 0day，对方是专业团队。需要战略选择：",
			"options": [
				{"text": "全面撤离受影响系统", "hint": "保守但安全", "effects": {"funds": -10000, "progress": 30}},
				{"text": "反制追踪（需 70+ 研究）", "hint": "尝试锁定对方身份", "requirements": {"skill": "skill_research", "min_value": 70}, "effects": {"rep": 15, "exp": 50}},
				{"text": "引入外部专家", "hint": "请国家队协助，高价", "effects": {"funds": -20000, "progress": 80}},
			],
		},
	},
}

# ---------- 静态函数 ----------

static func get_dept_upgrade_cost(dept_id: String, target_level: int) -> int:
	var d = DEPARTMENTS[dept_id]
	return int(d["base_cost"] * pow(d["cost_growth"], target_level - 1))

static func get_dept_upkeep(dept_id: String, level: int) -> int:
	return DEPARTMENTS[dept_id]["upkeep_per_level"] * level

static func get_dept_max_level(dept_id: String) -> int:
	return DEPARTMENTS[dept_id]["max_level"]

static func make_incident(type_id: String, year: int, month: int, rng: RandomNumberGenerator) -> Incident:
	var t = INCIDENT_TYPES[type_id]
	var inc := Incident.new()
	inc.id = randi()
	inc.type_id = type_id
	inc.name = t["name"]
	inc.description = t["desc"]
	inc.required_skill = t["required_skill"]
	var time_scale := 1.0 + (year - 1) * 0.15 + (month - 1) * 0.02
	inc.difficulty = int(t["base_difficulty"] * time_scale * GameState.difficulty_modifier)
	inc.severity = t["severity"] as Incident.Severity
	match inc.severity:
		Incident.Severity.LOW: inc.days_remaining = rng.randi_range(4, 6)
		Incident.Severity.MEDIUM: inc.days_remaining = rng.randi_range(3, 5)
		Incident.Severity.HIGH: inc.days_remaining = rng.randi_range(2, 3)
		Incident.Severity.CRITICAL: inc.days_remaining = rng.randi_range(1, 2)
	inc.fund_reward = 1000 + inc.difficulty * 50
	inc.rep_reward = 1 + int(inc.difficulty / 20)
	inc.exp_reward = 15 + int(inc.difficulty / 2)
	# 失败惩罚降低 30%（新手友好）
	inc.fund_penalty = int((2000 + inc.difficulty * 80) * 0.7)
	inc.rep_penalty = 2 + int(inc.difficulty / 15)
	# 严重事件 50% 概率标记为专班任务
	if inc.severity >= Incident.Severity.HIGH and rng.randf() < 0.5:
		inc.is_special_team = true
		inc.rep_reward += 3
		inc.fund_reward += 5000
	return inc

static func pick_random_incident_type(rng: RandomNumberGenerator, reputation: int) -> String:
	var total_weight := 0
	var weights := {}
	for tid in INCIDENT_TYPES.keys():
		var base_w: int = INCIDENT_TYPES[tid]["weight"]
		var sev: int = INCIDENT_TYPES[tid]["severity"]
		var w := base_w
		if sev >= 2:
			w = int(base_w * (0.3 + reputation / 50.0))
		weights[tid] = w
		total_weight += w
	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for tid in weights.keys():
		cumulative += weights[tid]
		if roll <= cumulative:
			return tid
	return "phishing"

static func generate_candidate(emp_id: int, rng: RandomNumberGenerator, player_rep: int) -> Employee:
	var e := Employee.new()
	e.id = emp_id
	e.name = CANDIDATE_NAMES[rng.randi_range(0, CANDIDATE_NAMES.size() - 1)] + str(rng.randi_range(10, 99))
	e.specialty = rng.randi_range(0, Employee.Specialty.size() - 1) as Employee.Specialty
	e.personality = rng.randi_range(0, Employee.Personality.size() - 1) as Employee.Personality
	e.appearance_variant = rng.randi_range(0, 2)
	var base := 8 + int(player_rep * 0.4)
	e.skill_detect = clampi(base + rng.randi_range(-3, 10), 5, 60)
	e.skill_analyze = clampi(base + rng.randi_range(-3, 10), 5, 60)
	e.skill_response = clampi(base + rng.randi_range(-3, 10), 5, 60)
	e.skill_training = clampi(base + rng.randi_range(-3, 10), 5, 60)
	e.skill_research = clampi(base + rng.randi_range(-3, 10), 5, 60)
	match e.specialty:
		Employee.Specialty.PHISHING: e.skill_detect += 8
		Employee.Specialty.MALWARE: e.skill_analyze += 8
		Employee.Specialty.NETWORK: e.skill_response += 8
		Employee.Specialty.FORENSICS: e.skill_analyze += 5; e.skill_research += 5
		Employee.Specialty.COMPLIANCE: e.skill_training += 8
		Employee.Specialty.GENERAL: pass
	var avg := e.get_overall_skill()
	e.hire_cost = int(2000 + avg * 200 + rng.randi_range(0, 2000))
	return e
