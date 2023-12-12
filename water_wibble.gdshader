shader_type spatial;
render_mode unshaded;

uniform vec2 amplitude = vec2(2.0, 2.2);
uniform vec2 frequency = vec2(0.8, 1.0);
uniform vec2 time_factor = vec2(0.7, 0.4);

uniform sampler2D texturemap : source_color;
uniform vec2 texturescale = vec2(1.0, 1.0);
uniform vec2 scroll = vec2(0.0, 0.0);

float height(vec2 pos, float time) {
	return (amplitude.x * sin(pos.x * frequency.x + time * time_factor.x)) + (amplitude.y * sin(pos.y * frequency.y + time * time_factor.y));
}

void vertex() {
	VERTEX.y += height(VERTEX.xz, TIME);

	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME) - height(VERTEX.xz + vec2(0.0, -0.2), TIME), 1.2));
	BINORMAL = normalize(vec3(1.2, height(VERTEX.xz + vec2(0.2, 0.0), TIME) - height(VERTEX.xz + vec2(-0.2, 0.0), TIME), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}

void fragment() {
	vec2 uv = UV;
	uv.x += 0.001 * sin(60.0 * uv.y + 0.6 * TIME) + scroll.x;
	uv.y += 0.0008 * sin(90.0 * uv.x + 0.4 * TIME) + scroll.y;

	ALBEDO = texture(texturemap, uv * texturescale).rgb;
}
