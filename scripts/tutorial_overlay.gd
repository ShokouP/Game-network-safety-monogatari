extends CanvasLayer
## 新手教程覆盖层：半透明遮罩 + 高亮 + 提示气泡

signal tutorial_finished

@onready var dim: ColorRect = %Dim
@onready var highlight: Panel = %Highlight
@onready var bubble_panel: PanelContainer = %BubblePanel
@onready var step_label: Label = %StepLabel
@onready var title_label: Label = %TitleLabel
@onready var content_label: Label = %ContentLabel
@onready var next_btn: Button = %NextButton
@onready var skip_btn: Button = %SkipButton

var current_step: int = 0
var is_active: bool = false
var main_ref: Control = null

func _ready() -> void:
	visible = false
	next_btn.pressed.connect(_on_next)
	skip_btn.pressed.connect(_on_skip)

func start(root: Control) -> void:
	main_ref = root
	current_step = 0
	is_active = true
	visible = true
	_show_step(current_step)

func _show_step(idx: int) -> void:
	var step := TutorialData.get_step(idx)
	if step.is_empty():
		_finish()
		return
	step_label.text = "步骤 %d/%d" % [idx + 1, TutorialData.step_count()]
	title_label.text = step["title"]
	content_label.text = step["content"]
	# 高亮
	var hl: String = step.get("highlight", "")
	if hl.is_empty() or main_ref == null:
		highlight.visible = false
		dim.color = Color(0, 0, 0, 0.4)
	else:
		var target := _find_node_by_name(hl)
		if target:
			dim.color = Color(0, 0, 0, 0.6)
			highlight.visible = true
			var rect := target.get_global_rect()
			highlight.position = rect.position - Vector2(6, 6)
			highlight.size = rect.size + Vector2(12, 12)
		else:
			highlight.visible = false
			dim.color = Color(0, 0, 0, 0.4)
	# 自动下一步（如招聘成功）
	var auto_signal: String = step.get("auto_next_on", "")
	if not auto_signal.is_empty():
		if EmployeeRoster.has_signal(auto_signal):
			if not EmployeeRoster.is_connected(auto_signal, _on_auto_next):
				EmployeeRoster.connect(auto_signal, _on_auto_next, CONNECT_ONE_SHOT)
	# 按钮文案
	if idx >= TutorialData.step_count() - 1:
		next_btn.text = "完成"
	else:
		next_btn.text = "下一条 →"

func _find_node_by_name(node_name: String) -> Control:
	if main_ref == null:
		return null
	return main_ref.find_child(node_name, true, false) as Control

func _on_auto_next(_arg = null) -> void:
	if is_active:
		call_deferred("_on_next")

func _on_next() -> void:
	current_step += 1
	if current_step >= TutorialData.step_count():
		_finish()
	else:
		_show_step(current_step)

func _on_skip() -> void:
	_finish()

func _finish() -> void:
	is_active = false
	visible = false
	tutorial_finished.emit()
