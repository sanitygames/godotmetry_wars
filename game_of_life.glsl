#[compute]
#version 450

// 16x16のワークグループ（256スレッド/グループ）
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// iimage2D から image2D に修正（rgba8 フォーマットに対応）
layout(set = 0, binding = 0, rgba8) readonly uniform image2D current_state;
layout(set = 0, binding = 1, rgba8) writeonly uniform image2D next_state;

void main() {
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(current_state);

	// 画面外の処理をスキップ
	if (pos.x >= size.x || pos.y >= size.y) {
		return;
	}

	// float (vec4) として値を取得（Rチャンネルが0.5以上なら生存）
	float current_val = imageLoad(current_state, pos).r;
	int is_alive = (current_val > 0.5) ? 1 : 0;

	// 周囲8マスの生存セル数をカウント（トーラス状にループ接続）
	int neighbors = 0;
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			if (dx == 0 && dy == 0) continue;
			ivec2 neighbor_pos = (pos + ivec2(dx, dy) + size) % size;

			if (imageLoad(current_state, neighbor_pos).r > 0.5) {
				neighbors++;
			}
		}
	}

	// ライフゲームのルール適用
	float next_val = 0.0;
	if (is_alive == 1) {
		if (neighbors == 2 || neighbors == 3) {
			next_val = 1.0; // 生存
		}
	} else {
		if (neighbors == 3) {
			next_val = 1.0; // 誕生
		}
	}

	// 書き込み（生存: 白 vec4(1,1,1,1), 死滅: 黒 vec4(0,0,0,1)）
	imageStore(next_state, pos, vec4(next_val, next_val, next_val, 1.0));
}
