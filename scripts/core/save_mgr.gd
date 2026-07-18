extends Node
## SaveMgr autoload：多存档槽（3 手动 + 1 自动）+ 版本号

signal save_completed(slot: int)
signal load_completed(slot: int)

const SAVE_VERSION := 2
const SLOT_COUNT := 3
const AUTO_SLOT := 0  # 0 是自动槽，1-3 是手动槽

var current_slot: int = -1  # 当前游玩的槽位；-1 = 未保存过

func get_save_path(slot: int) -> String:
	if slot == AUTO_SLOT:
		return "user://save_auto.save"
	return "user://save_slot_%d.save" % slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_slot_info(slot: int) -> Dictionary:
	## 读取槽位元信息（不加载整个游戏）
	if not slot_exists(slot):
		return {}
	var f := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data == null:
		return {}
	return {
		"year": data.get("game_state", {}).get("year", 1),
		"month": data.get("game_state", {}).get("month", 4),
		"day": data.get("game_state", {}).get("day", 1),
		"funds": data.get("game_state", {}).get("funds", 0),
		"reputation": data.get("game_state", {}).get("reputation", 0),
		"employee_count": data.get("employee_roster", {}).get("employees", []).size(),
		"ng_plus_count": data.get("game_state", {}).get("ng_plus_count", 0),
		"timestamp": data.get("timestamp", 0),
		"version": data.get("save_version", 0),
	}

func save(slot: int) -> Error:
	var f := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	var data := {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": GameState.to_dict(),
		"employee_roster": EmployeeRoster.to_dict(),
		"incident_queue": IncidentQueue.to_dict(),
		"achievements": AchievementMgr.to_dict(),
		"award_history": AwardMgr.to_dict(),
	}
	f.store_string(JSON.stringify(data))
	f.close()
	current_slot = slot
	save_completed.emit(slot)
	return OK

func load(slot: int) -> Error:
	if not slot_exists(slot):
		return ERR_FILE_NOT_FOUND
	var f := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if f == null:
		return FileAccess.get_open_error()
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data == null:
		return ERR_PARSE_ERROR
	var version: int = data.get("save_version", 0)
	if version > SAVE_VERSION:
		push_warning("存档版本 %d 高于当前 %d，可能不兼容" % [version, SAVE_VERSION])
	GameState.from_dict(data.get("game_state", {}))
	EmployeeRoster.from_dict(data.get("employee_roster", {}))
	IncidentQueue.from_dict(data.get("incident_queue", {}))
	AchievementMgr.from_dict(data.get("achievements", {}))
	AwardMgr.from_dict(data.get("award_history", {}))
	current_slot = slot
	load_completed.emit(slot)
	return OK

func delete_slot(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(get_save_path(slot))

func auto_save() -> void:
	if current_slot >= 0:
		save(AUTO_SLOT)
