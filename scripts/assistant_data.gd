class_name AssistantData
extends RefCounted
## 网安小助手 - 前 3 月强制指引任务

# 每月一组任务，不可跳过，完成后解锁下月
const GUIDE_TASKS := {
	4: {  # 第 1 年 4 月（开局月）
		"title": "新手入门：组建你的安全团队",
		"tasks": [
			{"id": "hire_2", "desc": "招聘 2 名员工", "check": "emp_count>=2", "hint": "点左侧 [+ 招聘]"},
			{"id": "assign_incident", "desc": "派 1 名员工处置 1 起事件", "check": "incident_assigned", "hint": "切到 [事件] Tab，下拉选择处置人"},
			{"id": "train_1", "desc": "完成 1 次员工培训", "check": "training_done", "hint": "点员工卡 [📚 培训]，选基础课程"},
			{"id": "upgrade_dept", "desc": "建设 1 个部门（推荐 SOC）", "check": "dept_built", "hint": "底部 [部门建设] 面板，点 [建设]"},
		],
		"reward": {"funds": 5000, "rp": 10, "rep": 3},
	},
	5: {  # 第 1 年 5 月
		"title": "进阶：应对真实攻击",
		"tasks": [
			{"id": "block_3", "desc": "成功拦截 3 次攻击", "check": "blocked>=3", "hint": "合理分配员工，优先高难度事件"},
			{"id": "combo_active", "desc": "激活 1 个设施 combo", "check": "combo_active", "hint": "同层相邻建设 2 个部门（如 SOC+取证）"},
			{"id": "emp_level_5", "desc": "1 名员工达到 Lv.5", "check": "emp_max_level>=5", "hint": "持续培训 + 处置事件赚经验"},
			{"id": "hire_4", "desc": "团队扩到 4 人", "check": "emp_count>=4", "hint": "继续招聘"},
		],
		"reward": {"funds": 8000, "rp": 15, "rep": 5},
	},
	6: {  # 第 1 年 6 月
		"title": "精通：成为安全专家",
		"tasks": [
			{"id": "block_8", "desc": "累计拦截 8 次攻击", "check": "blocked>=8", "hint": "保持警惕"},
			{"id": "career_path", "desc": "1 名员工完成转职", "check": "career_path", "hint": "员工 Lv.5 后，点 [详情] 选转职路径"},
			{"id": "dept_level_2", "desc": "任一部门升到 Lv.2", "check": "dept_max_level>=2", "hint": "继续投资部门"},
			{"id": "funds_100k", "desc": "账上资金达到 ¥100,000", "check": "funds>=100000", "hint": "拦截赚钱 + 控制支出"},
		],
		"reward": {"funds": 15000, "rp": 30, "rep": 8},
	},
}

# 小助手对话（每月开场 + 任务完成 + 奖励发放）
const DIALOGS := {
	"intro_4": "👋 你好，我是你的网安小助手『小盾』。接下来的 3 个月，我会带你熟悉这个岗位。先从组建团队开始吧！",
	"intro_5": "📈 第一个月干得不错！现在来点真格的 —— 学习如何应对真实攻击。",
	"intro_6": "🏆 最后一个月了，让我看看你的真正实力。完成后你就是合格的安全部长了！",
	"task_done": "✅ 任务完成！继续加油！",
	"month_done": "🎉 本月任务全部完成！奖励已发放，下个月见！",
	"all_done": "🎓 3 个月的新手期结束了。你已经是一名合格的安全部长了。祝你好运！",
}
