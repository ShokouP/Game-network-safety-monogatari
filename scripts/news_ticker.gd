extends PanelContainer
## 开罗式新闻滚动条（横向 ticker）

@onready var ticker_label: Label = %TickerLabel

const SCROLL_SPEED := 80.0  # px/s
const NEWS_POOL := [
	"📢 国家网络安全宣传周即将开幕，主题是『共建清朗网络空间』",
	"🌐 某运营商发生大规模 DDoS 攻击，业务中断 3 小时",
	"🔐 监管机构发布新版《数据安全管理办法》，明年 1 月生效",
	"💰 安全上市公司 Q3 财报：行业平均增速 23%",
	"🎓 高校新增『网络空间安全』本科专业，首批招生 5000 人",
	"🦠 新型勒索软件『幽冥锁』肆虐，已感染 30+ 企业",
	"🔥 0day 市场报价创新高，iOS 完整链突破 300 万美金",
	"📱 某手机厂商推送紧急补丁，修复远程代码执行漏洞",
	"🌍 国际刑警破获跨国钓鱼团伙，抓获嫌疑人 47 名",
	"⚠️ 多家快递公司数据库泄露，数亿条面单信息在暗网出售",
	"🎮 游戏公司遭 APT 攻击，源代码被窃取",
	"💼 资深 CISO 年薪突破 200 万，安全人才缺口持续扩大",
	"🤖 AI 换脸诈骗成功率 78%，监管机构要求平台加强审核",
	"🛡️ 等保 3.0 征求意见稿发布，强调供应链安全",
	"🏆 国际 CTF 大赛落幕，中国战队夺冠",
	"📊 报告：勒索软件平均赎金降至 5 万美元",
	"🔬 量子计算突破：Shor 算法威胁 RSA-2048",
	"🎯 金融行业成为 APT 首要目标，占比 34%",
	"🚨 某电商平台遭遇撞库攻击，百万账号受影响",
	"📦 开源组件投毒事件同比增加 240%",
]

var news_queue: Array[String] = []
var current_text: String = ""
var scroll_offset: float = 0.0
var label_width: float = 0.0
var is_paused: bool = false

func _ready() -> void:
	_shuffle_news()
	_load_next_news()
	# 鼠标悬停暂停
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _shuffle_news() -> void:
	news_queue.clear()
	news_queue.assign(NEWS_POOL)
	news_queue.shuffle()

func _load_next_news() -> void:
	if news_queue.is_empty():
		_shuffle_news()
	if news_queue.is_empty():
		return
	current_text = news_queue.pop_front()
	ticker_label.text = current_text
	await get_tree().process_frame
	# 估算文本宽度（字符数 * 字号近似）
	label_width = current_text.length() * 14.0
	scroll_offset = size.x
	ticker_label.position.x = scroll_offset

func _process(delta: float) -> void:
	if is_paused:
		return
	scroll_offset -= SCROLL_SPEED * delta
	ticker_label.position.x = scroll_offset
	if scroll_offset < -label_width:
		_load_next_news()

func _on_mouse_entered() -> void:
	is_paused = true

func _on_mouse_exited() -> void:
	is_paused = false

func push_breaking_news(text: String) -> void:
	## 插入紧急新闻（插到队首）
	news_queue.push_front(text)
