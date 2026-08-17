shader_type canvas_item;

uniform vec4 col: source_color;

void fragment() {
  vec2 uv = UV * 2.0 - 1.0;
  float d = length(uv);
  vec4 c = col * step(d, 0.9);
  c = c - vec4(col.rgb * step(d, 0.8), 0.0);
  COLOR = c;
	// Called for every pixel the material is visible on.
}

