class_name ShopData
extends RefCounted
## 商店道具

const ITEMS := [
	{"id": "coffee", "name": "咖啡", "icon": "☕", "desc": "全员疲劳 -20", "price": 800, "effect": {"fatigue": -20}},
	{"id": "energy_drink", "name": "能量饮料", "icon": "🥤", "desc": "指定员工疲劳清零", "price": 500, "effect": {"fatigue_clear": true}},
	{"id": "training_boost", "name": "培训加速卡", "icon": "🎫", "desc": "下次培训时间减半", "price": 2000, "effect": {"training_boost": true}},
	{"id": "temp_worker", "name": "临时顾问", "icon": "👨‍💼", "desc": "雇佣 1 名 Lv.5 临时员工 30 天", "price": 5000, "effect": {"temp_emp": true}},
	{"id": "threat_intel", "name": "威胁情报", "icon": "🔍", "desc": "下次事件难度 -20%", "price": 1500, "effect": {"intel_boost": true}},
	{"id": "pr_package", "name": "公关礼包", "icon": "📢", "desc": "声誉 +5", "price": 3000, "effect": {"rep": 5}},
	{"id": "research_grant", "name": "研究经费", "icon": "🔬", "desc": "RP +20", "price": 2500, "effect": {"rp": 20}},
	{"id": "firewall_license", "name": "防火墙授权", "icon": "🛡️", "desc": "下次事件自动拦截", "price": 8000, "effect": {"auto_block": true}},
]
