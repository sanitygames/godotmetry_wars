shader_type canvas_item;


void fragment() {
    float d = 2.0 * abs(UV.x - 0.5) - UV.y

    // fwidth と smoothstep でエッジのジャギー（アリ) を防止
    float edge = fwidth(d);
    float alpha = smoothstep(edge, -edge, d);

    COLOR = vec4(1.0, 0.0, 0.0, alpha);
}
