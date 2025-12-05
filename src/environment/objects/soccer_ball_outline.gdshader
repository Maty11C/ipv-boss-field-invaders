shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Amarillo por defecto
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	
	float outline = 0.0;
	outline += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline = min(outline, 1.0);
	
	vec4 color = texture(TEXTURE, UV);
	
	// Si el pixel es transparente pero tiene vecinos opacos, dibuja el contorno
	if (color.a < 0.1 && outline > 0.0) {
		COLOR = outline_color;
	} else {
		COLOR = color;
	}
}

