shader_type spatial;
render_mode unshaded, blend_mix;   // โปร่งผสมปกติ (อย่าใช้ depth_draw_always)

uniform vec3 deep_color    : source_color = vec3(0.00, 0.15, 0.35);
uniform vec3 shallow_color : source_color = vec3(0.10, 0.55, 0.85);
uniform float alpha = 0.70;  // ความโปร่ง

// คลื่น 2 ชั้น
uniform float wave_amp    = 0.35;
uniform float wave_len    = 10.0;
uniform float wave_speed  = 0.8;

uniform float wave2_amp   = 0.20;
uniform float wave2_len   = 3.5;
uniform float wave2_speed = 1.6;

// เฟรเนลอย่างง่าย (ขอบสว่าง)
uniform float fresnel_power = 5.0;

void vertex() {
    float w1 = sin((VERTEX.x + TIME * wave_speed) * 6.2831853 / wave_len) * wave_amp;
    float w2 = sin((VERTEX.z * 1.3 - TIME * wave2_speed) * 6.2831853 / wave2_len) * wave2_amp;
    VERTEX.y += w1 + w2;
}

void fragment() {
    float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), fresnel_power);
    vec3 col = mix(deep_color, shallow_color, fres);
    EMISSION = col * 1.15;   // เรืองนิดๆ ให้เข้ากับ Glow
    ALBEDO   = col;
    ALPHA    = alpha;
}
