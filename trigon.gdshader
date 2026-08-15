shader_type canvas_item;

uniform vec4 col: source_color;


float sdEquilateralTriangle( in vec2 p, in float r )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x);
    p -= vec2(0.5,0.5*k)*max(p.x+k*p.y,0.0);
    p -= vec2(clamp(p.x,-r,r),-r/k );
    return length(p)*sign(-p.y);
}

//    "body": "vec2 uv = (UV * 2.0 - 1.0) * vec2(TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x, 1.0);",

void fragment() {
  vec2 uv = (UV * 2.0 - 1.0) * vec2(TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x, 1.0);
  float d = sdEquilateralTriangle(uv, 0.75);
  COLOR = vec4(col.rgb, step(d, 0.1));
}
