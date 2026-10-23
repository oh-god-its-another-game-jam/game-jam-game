shader_type canvas_item;

// Handles the concentric ripples
uniform float frequency : hint_range(0, 15, 0.01) = 4.0;
uniform float amplitude : hint_range(0, 3, 0.1) = 2.0;
uniform float ripple_rate : hint_range(0, 20.0, 1) = 5.0;

// Handles the waves themselves
uniform float wave_amplitude : hint_range(0.001, 0.1, 0.001) = 0.05;
uniform float wave_frequency : hint_range(0, 15, 0.01) = 4.0;

// Driven by the script
uniform vec2 origin = vec2(0.5, 0.5);                // screen UV (0-1)
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = start, 1 = done
uniform float max_radius = 2.2;                      // how far the ring travels
uniform float band_width : hint_range(0.05, 1.0, 0.01) = 0.4;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec2 wave(vec2 uv, float time) {
	return vec2(
		uv.x + sin(uv.y * wave_frequency + time) * wave_amplitude,
		uv.y + sin(uv.x * wave_frequency + time) * wave_amplitude
	);
}

void fragment() {
	// aspect-corrected offset from the origin, so the ring is circular
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x; // width / height
	vec2 center_position = (SCREEN_UV - origin) * vec2(aspect, 1.0) * 2.0;
	float center_distance = length(center_position);
	vec2 dir = center_position / max(center_distance, 0.0001);

	// travelling ring that fades out over time (replaces the fixed centre falloff)
	float ring = 1.0 - smoothstep(0.0, band_width, abs(center_distance - progress * max_radius));
	float envelope = ring * (1.0 - progress);

	float ripple = sin(center_distance * -frequency * PI + ripple_rate * TIME) * amplitude / (center_distance + 1.0);

	vec2 uv = SCREEN_UV + dir * ripple * wave_amplitude * envelope;
	vec2 background_wave = uv + (wave(uv, TIME) - uv) * envelope;
	vec4 background_texture = texture(SCREEN_TEXTURE, background_wave) * sqrt(amplitude);

	float alpha_scalar = envelope * background_texture.x * 2.5;

	background_texture.a *= alpha_scalar * (ripple + background_texture.x * background_texture.y);
	background_texture.a = max(background_texture.a - (background_texture.y * 0.45), 0.0);

	COLOR = vec4(background_texture.xyz, background_texture.a);
}