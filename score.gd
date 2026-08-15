extends Node

var hi_score := 0

var ranking: Array = [100, 500, 1000]


func get_ranking() -> void:
	var dict = await GodotplayerScore.get_scores("main", {"limit": 100})
	ranking = dict["scores"]
	ranking.sort()
