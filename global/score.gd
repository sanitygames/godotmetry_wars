extends Node

var hi_score := 0

var ranking: Array = [100, 500, 1000]
var dict: Dictionary = {"scores": [100, 300, 500, 1000]}


func get_ranking() -> void:
	dict = await GodotplayerScore.get_scores("main", {"limit": 100})
	ranking = dict["scores"].map(func(d): return d["score"])
	ranking.sort()


func get_rank(score: int) -> int:
	var rank = ranking.size() - ranking.bsearch(score) + 1
	return rank
