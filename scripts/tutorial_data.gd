class_name TutorialData
extends RefCounted
## 新手教程步骤定义

const STEPS := [
	{
		"id": "welcome",
		"title": "👋 欢迎就任安全部长",
		"content": "你是公司新任的安全部长。你的任务：\n· 招聘安全团队\n· 抵御网络攻击\n· 培训员工成长\n· 让公司活下去\n\n点 [下一条] 继续。",
		"highlight": "",
	},
	{
		"id": "office_view",
		"title": "🏢 你的办公室",
		"content": "中央是办公室俯视图：\n· 像素小人就是你的员工\n· 他们会走动、工作、休息\n· 升级部门可解锁 F2/F3 楼层\n\n切换到 [事件] Tab 可查看攻击事件。",
		"highlight": "CenterTabs",
	},
	{
		"id": "resources",
		"title": "💰 三大资源",
		"content": "顶栏显示三种资源：\n· 💰 资金：用于招聘/培训/升级\n· ⭐ 声誉：吸引更好员工和事件\n· 🔬 RP（研究点）：用于解锁成就\n\n资金清零 = 破产，声誉清零 = 解散。",
		"highlight": "TopBar",
	},
	{
		"id": "hire",
		"title": "👥 第一步：招募员工",
		"content": "点左侧 [+ 招聘] 按钮：\n· 从 3 名候选人中选 1\n· 候选人随机生成（专长/性格/外貌）\n· 价格越高潜力越好\n\n试试招聘一名员工！",
		"highlight": "HireButton",
		"auto_next_on": "employee_hired",
	},
	{
		"id": "incident",
		"title": "🚨 处置攻击事件",
		"content": "中央 [事件] Tab 会刷出攻击：\n· 钓鱼/勒索/DDoS/APT 等 10 种\n· 每个事件有 [难度] 和 [时限]\n· 从下拉菜单选 1 名员工处置\n· 员工技能匹配难度 = 进度快\n\n切换到 [事件] Tab 看看吧。",
		"highlight": "IncidentTab",
	},
	{
		"id": "train",
		"title": "📚 员工培训",
		"content": "员工卡上的 [📚 培训] 按钮：\n· 11 种课程按等级解锁\n· 5 级后可转职（红队/蓝队/紫队）\n· 培训耗时几天但永久提升技能\n\n点击任意员工的 [详情] 查看技能条。",
		"highlight": "EmployeeList",
	},
	{
		"id": "upgrade_dept",
		"title": "🏗️ 升级部门",
		"content": "底部是 6 个部门：\n· SOC/培训室/实验室/取证/公关/休息区\n· 同层相邻触发 combo 加成\n· 部门升到 1 级解锁对应楼层\n\n资金够就升级 SOC 吧！",
		"highlight": "DeptPanel",
	},
	{
		"id": "speed",
		"title": "⏩ 时间控制",
		"content": "右上角速度按钮：\n· ⏸ 暂停（思考决策）\n· ▶ 正常（1天=2秒）\n· ▶▶ 快速\n· ▶▶▶ 极快\n\n感到压力就暂停，慢慢来。",
		"highlight": "SpeedButtons",
	},
	{
		"id": "finish",
		"title": "🎉 教程完成",
		"content": "你已经掌握了基本操作：\n✓ 招聘员工\n✓ 处置事件\n✓ 培训成长\n✓ 升级部门\n\n还有成就/年度奖项/CEO 评价/月度排名等玩法等你探索。\n\n祝你的安全部门越来越强！",
		"highlight": "",
	},
]

static func get_step(idx: int) -> Dictionary:
	if idx < 0 or idx >= STEPS.size():
		return {}
	return STEPS[idx]

static func step_count() -> int:
	return STEPS.size()
