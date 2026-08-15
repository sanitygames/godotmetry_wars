extends Node
## godotplayer Score SDK — autoload singleton `GodotplayerScore`.
##
## ゲームから godotplayer 公式ランキングへスコアを送信/取得するための SDK。
## すべてのメソッドは await で結果 Dictionary を返す（シグナルは補助的に発火する）。
##
## 使い方:
##   var r = await GodotplayerScore.submit_score("main", 1200)
##   if r.ok and r.updated:
##       print("ベスト更新! rank=%d" % r.rank)
##
##   var b = await GodotplayerScore.get_scores("main", {"limit": 10})
##   for row in b.scores:
##       print("%d位 %s %d" % [row.rank, row.display_name, row.score])
##
## 実行環境で動作が変わる:
##   - Web (godotplayer.com 上でのプレイ): JavaScriptBridge → 注入JS → 親ページが
##     同一オリジンのスコアAPIへ送信する。ゲームは認証情報を一切扱わない。
##   - エディタ / ネイティブ実行: in-memory のモックで同じ形の結果を返す。
##     mock_seed / mock_latency_ms でランキングUIの開発がエディタ内で完結する。
##
## ベストプラクティス: スコア送信はゲームオーバーやステージクリアなどの節目で行う。
## 毎フレーム送信しない（レート制限で 429 になる）。

## submit_score 完了時に発火（await の補助。payload は submit_score の戻り値と同じ）。
signal score_submitted(result: Dictionary)
## get_scores 完了時に発火（await の補助。payload は get_scores の戻り値と同じ）。
signal scores_loaded(result: Dictionary)

# 内部: web ブリッジ応答の相関用
signal _request_completed(request_id: String, result: Dictionary)

## エディタ確認用のダミーランキング。代入した時点で mock に反映される
## （autoload の _ready はゲームコードより先に走るため、setter で遅延 seed する）。
## 形式: { "main": { "ascending": false, "entries": [ { "display_name": "alice", "score": 1200 }, ... ] } }
## 旧形式の bare array ( { "main": [ {...}, ... ] } ) も受け付ける。
@export var mock_seed: Dictionary = {}:
	set(value):
		mock_seed = value
		_seed_mock()

## mock の擬似レイテンシ (ms)。0 で即時。本番同様に非同期処理を強制するため既定 150ms。
@export var mock_latency_ms: int = 150

const _MOCK_PLAYER_ID := "dev-player"
const _MOCK_PLAYER_NAME := "You (mock)"
## 同一ボードへの最短送信間隔 (ms)。ゲームループからの暴発を抑止する。
const _MIN_SUBMIT_INTERVAL_MS := 1000

var _is_web := false

# mock state: board_id -> { "ascending": bool, "seq": int,
#   "entries": { player_id: { "name": String, "score": int, "seq": int } } }
var _mock_boards: Dictionary = {}

# web bridge state
var _js_window = null                  # JavaScriptObject (window)
var _js_callback = null                # JavaScriptBridge callback (参照保持しないと GC される)
# request_id -> { "kind": "submit"|"get" }
var _pending: Dictionary = {}

# board_id -> 最終送信時刻 (msec ticks)
var _last_submit_ms: Dictionary = {}


func _ready() -> void:
	_is_web = OS.has_feature("web")
	if _is_web:
		_setup_bridge()
	else:
		print("[GodotplayerScore] mock mode (editor/native)。スコアはローカルのみ。godotplayer にアップロードすると実ランキングに接続されます。")


## スコアを送信する。awaitで結果を受け取る。
## options:
##   "ascending": bool — true なら小さいほど上位（タイム等）。ボード初回作成時のみ有効。
##   "display_name": String — 表示名の上書き（連名 "Alice & Bob" など。32文字まで）。
## 戻り値: { "ok": bool, "updated": bool, "rank": int, "best_score": int,
##           "sort_order": "asc"|"desc", "error": String|null }
func submit_score(board_id: String, score: int, options: Dictionary = {}) -> Dictionary:
	var now := Time.get_ticks_msec()
	var last: int = _last_submit_ms.get(board_id, -_MIN_SUBMIT_INTERVAL_MS)
	if now - last < _MIN_SUBMIT_INTERVAL_MS:
		var throttled := _submit_error("throttled", score)
		score_submitted.emit(throttled)
		return throttled
	_last_submit_ms[board_id] = now

	var result: Dictionary
	if _is_web:
		result = await _web_submit(board_id, score, options)
	else:
		result = await _mock_submit(board_id, score, options)
	score_submitted.emit(result)
	return result


## ランキングを取得する。awaitで結果を受け取る。
## options:
##   "limit": int — 取得件数（既定 10、最大 100）。
## 戻り値: { "ok": bool, "sort_order": "asc"|"desc",
##           "scores": [ { "rank": int, "display_name": String, "score": int, "is_me": bool } ],
##           "me": {} または { "rank": int, "score": int, "display_name": String },
##           "error": String|null }
func get_scores(board_id: String, options: Dictionary = {}) -> Dictionary:
	var result: Dictionary
	if _is_web:
		result = await _web_get(board_id, options)
	else:
		result = await _mock_get(board_id, options)
	scores_loaded.emit(result)
	return result


# ---------------------------------------------------------------------------
# 共通
# ---------------------------------------------------------------------------

func _submit_error(error: String, score: int) -> Dictionary:
	return {
		"ok": false, "updated": false, "rank": 0,
		"best_score": score, "sort_order": "desc", "error": error,
	}


func _get_error(error: String) -> Dictionary:
	return { "ok": false, "sort_order": "desc", "scores": [], "me": {}, "error": error }


# ---------------------------------------------------------------------------
# Mock mode (editor / native)
# ---------------------------------------------------------------------------

func _seed_mock() -> void:
	# seed に含まれるボードのみ作り直す（再代入時も同じ結果になるように）
	for board_id in mock_seed.keys():
		var raw = mock_seed[board_id]
		var ascending := false
		var entries: Array = []
		if raw is Array:
			entries = raw
		elif raw is Dictionary:
			ascending = bool(raw.get("ascending", false))
			entries = raw.get("entries", [])
		var board := { "ascending": ascending, "seq": 0, "entries": {} }
		for entry in entries:
			var seq: int = board["seq"]
			board["entries"]["seed:%d" % seq] = {
				"name": String(entry.get("display_name", entry.get("player_name", "player"))),
				"score": int(entry.get("score", 0)),
				"seq": seq,
			}
			board["seq"] = seq + 1
		_mock_boards[board_id] = board


func _mock_latency() -> void:
	if mock_latency_ms > 0 and is_inside_tree():
		await get_tree().create_timer(mock_latency_ms / 1000.0).timeout
	else:
		await get_tree().process_frame


func _ensure_mock_board(board_id: String, ascending: bool) -> Dictionary:
	if not _mock_boards.has(board_id):
		_mock_boards[board_id] = { "ascending": ascending, "seq": 0, "entries": {} }
	return _mock_boards[board_id]


func _mock_better(board: Dictionary, a: int, b: int) -> bool:
	# a が b より上位スコアか
	return a < b if bool(board["ascending"]) else a > b


func _mock_rank(board: Dictionary, score: int) -> int:
	var better := 0
	for pid in board["entries"]:
		if _mock_better(board, board["entries"][pid]["score"], score):
			better += 1
	return better + 1


func _mock_submit(board_id: String, score: int, options: Dictionary) -> Dictionary:
	await _mock_latency()
	var board := _ensure_mock_board(board_id, bool(options.get("ascending", false)))
	var entries: Dictionary = board["entries"]
	var display_name := String(options.get("display_name", _MOCK_PLAYER_NAME))

	var existing: Dictionary = entries.get(_MOCK_PLAYER_ID, {})
	var updated := existing.is_empty() or _mock_better(board, score, int(existing["score"]))
	if updated:
		var seq: int = existing.get("seq", board["seq"])
		if existing.is_empty():
			board["seq"] = int(board["seq"]) + 1
		entries[_MOCK_PLAYER_ID] = { "name": display_name, "score": score, "seq": seq }
	var best: int = entries[_MOCK_PLAYER_ID]["score"]
	var sort_order := "asc" if bool(board["ascending"]) else "desc"
	var rank := _mock_rank(board, best)
	print("[GodotplayerScore][mock] submit board=%s score=%d -> updated=%s rank=%d best=%d" % [board_id, score, str(updated), rank, best])
	return {
		"ok": true, "updated": updated, "rank": rank,
		"best_score": best, "sort_order": sort_order, "error": null,
	}


func _mock_get(board_id: String, options: Dictionary) -> Dictionary:
	await _mock_latency()
	var limit := clampi(int(options.get("limit", 10)), 1, 100)
	if not _mock_boards.has(board_id):
		print("[GodotplayerScore][mock] get board=%s -> 0 rows (board未作成)" % board_id)
		return { "ok": true, "sort_order": "desc", "scores": [], "me": {}, "error": null }

	var board: Dictionary = _mock_boards[board_id]
	var entries: Dictionary = board["entries"]
	var rows: Array = []
	for pid in entries:
		rows.append({
			"name": entries[pid]["name"], "score": entries[pid]["score"],
			"seq": entries[pid]["seq"], "is_me": pid == _MOCK_PLAYER_ID,
		})
	var ascending := bool(board["ascending"])
	rows.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return a["score"] < b["score"] if ascending else a["score"] > b["score"]
		return a["seq"] < b["seq"]
	)

	var scores: Array = []
	var prev_score := 0
	var prev_rank := 0
	for i in range(mini(limit, rows.size())):
		var rank := i + 1
		if i > 0 and rows[i]["score"] == prev_score:
			rank = prev_rank
		prev_score = rows[i]["score"]
		prev_rank = rank
		scores.append({
			"rank": rank, "display_name": rows[i]["name"],
			"score": rows[i]["score"], "is_me": rows[i]["is_me"],
		})

	var me: Dictionary = {}
	if entries.has(_MOCK_PLAYER_ID):
		me = {
			"rank": _mock_rank(board, entries[_MOCK_PLAYER_ID]["score"]),
			"score": entries[_MOCK_PLAYER_ID]["score"],
			"display_name": entries[_MOCK_PLAYER_ID]["name"],
		}
	print("[GodotplayerScore][mock] get board=%s -> %d rows" % [board_id, scores.size()])
	return {
		"ok": true,
		"sort_order": "asc" if ascending else "desc",
		"scores": scores, "me": me, "error": null,
	}


# ---------------------------------------------------------------------------
# Web mode (godotplayer.com 上でのプレイ)
# ---------------------------------------------------------------------------

func _setup_bridge() -> void:
	_js_window = JavaScriptBridge.get_interface("window")
	if _js_window == null:
		push_warning("[GodotplayerScore] window interface unavailable")
		return
	# 注入JS (godotplayer_score.js) が結果を window.__godotplayer_score_callback(json) で返す。
	# 参照を保持しないと callback が GC されるため _js_callback に保持する。
	_js_callback = JavaScriptBridge.create_callback(_on_js_result)
	_js_window.__godotplayer_score_callback = _js_callback


func _bridge_ready() -> bool:
	return _js_window != null and _js_window.GodotplayerScore != null


func _web_submit(board_id: String, score: int, options: Dictionary) -> Dictionary:
	if not _bridge_ready():
		push_warning("[GodotplayerScore] bridge not ready (submit)。スコアスクリプト注入が無効の可能性")
		await get_tree().process_frame
		return _submit_error("bridge_unavailable", score)
	var js_options := {}
	if bool(options.get("ascending", false)):
		js_options["ascending"] = true
	if options.has("display_name"):
		js_options["display_name"] = String(options["display_name"])
	var request_id := String(_js_window.GodotplayerScore.submitScore(board_id, score, JSON.stringify(js_options)))
	_pending[request_id] = { "kind": "submit" }
	var result := await _await_result(request_id)
	if not bool(result.get("ok", false)):
		return _submit_error(String(result.get("error", "unknown")), score)
	return {
		"ok": true,
		"updated": bool(result.get("updated", false)),
		"rank": int(result.get("rank", 0)),
		"best_score": int(result.get("best_score", 0)),
		"sort_order": String(result.get("sort_order", "desc")),
		"error": null,
	}


func _web_get(board_id: String, options: Dictionary) -> Dictionary:
	if not _bridge_ready():
		push_warning("[GodotplayerScore] bridge not ready (get)。スコアスクリプト注入が無効の可能性")
		await get_tree().process_frame
		return _get_error("bridge_unavailable")
	var js_options := { "limit": clampi(int(options.get("limit", 10)), 1, 100) }
	var request_id := String(_js_window.GodotplayerScore.getScores(board_id, JSON.stringify(js_options)))
	_pending[request_id] = { "kind": "get" }
	var result := await _await_result(request_id)
	if not bool(result.get("ok", false)):
		return _get_error(String(result.get("error", "unknown")))
	var scores: Array = []
	for row in result.get("scores", []):
		scores.append({
			"rank": int(row.get("rank", 0)),
			"display_name": String(row.get("displayName", "")),
			"score": int(row.get("score", 0)),
			"is_me": bool(row.get("isMe", false)),
		})
	var me: Dictionary = {}
	var raw_me = result.get("me")
	if raw_me is Dictionary and not raw_me.is_empty():
		me = {
			"rank": int(raw_me.get("rank", 0)),
			"score": int(raw_me.get("score", 0)),
			"display_name": String(raw_me.get("displayName", "")),
		}
	return {
		"ok": true,
		"sort_order": String(result.get("sort_order", "desc")),
		"scores": scores, "me": me, "error": null,
	}


func _await_result(request_id: String) -> Dictionary:
	# 注入JS側に10秒タイムアウトがあるため必ず解決される
	while true:
		var args = await _request_completed
		if args[0] == request_id:
			return args[1]
	return {}  # 到達しない


# 注入JS からの応答。args[0] は結果 JSON 文字列 (requestId を含む)。
func _on_js_result(args: Array) -> void:
	if args.is_empty():
		return
	var result = JSON.parse_string(String(args[0]))
	if result == null or not (result is Dictionary):
		push_warning("[GodotplayerScore] failed to parse bridge result")
		return
	var request_id := String(result.get("requestId", ""))
	if not _pending.has(request_id):
		return
	_pending.erase(request_id)
	if not bool(result.get("ok", false)):
		push_warning("[GodotplayerScore] bridge error: %s" % str(result.get("error", "unknown")))
	_request_completed.emit(request_id, result)
