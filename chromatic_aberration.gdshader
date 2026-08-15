shader_type canvas_item;

// 画面全体のテクスチャを取得
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// 色収差の強度（画面ピクセル単位）
uniform float r_offset : hint_range(-10.0, 10.0) = 3.0;
uniform float b_offset : hint_range(-10.0, 10.0) = -3.0;

void fragment() {
    vec2 center_dir = SCREEN_UV - vec2(0.5); // 画面中心からのベクトル
    
    // 中心からの距離に応じて赤と青のUV位置を外側にずらす
    vec2 r_uv = SCREEN_UV + center_dir * (r_offset * SCREEN_PIXEL_SIZE);
    vec2 g_uv = SCREEN_UV;
    vec2 b_uv = SCREEN_UV + center_dir * (b_offset * SCREEN_PIXEL_SIZE);
    
    // 各チャンネルを個別にサンプリング
    float r = texture(screen_texture, r_uv).r;
    float g = texture(screen_texture, g_uv).g;
    float b = texture(screen_texture, b_uv).b;
    
    COLOR = vec4(r, g, b, 1.0);
}
