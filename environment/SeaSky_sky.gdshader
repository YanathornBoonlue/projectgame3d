shader_type sky;

// สีท้องฟ้า
uniform vec3 top_color      : source_color = vec3(0.35, 0.55, 0.95);
uniform vec3 horizon_color  : source_color = vec3(0.80, 0.90, 1.00);
uniform float horizon_height   : hint_range(-0.5, 0.5) = 0.00; // ตำแหน่งเส้นขอบฟ้า (y); ค่าติดลบ = ขอบฟ้าต่ำลง
uniform float horizon_softness : hint_range(0.0, 0.6)  = 0.18; // ความฟุ้งของขอบ (ยิ่งน้อยยิ่งคม)
uniform float horizon_gamma    : hint_range(0.2, 3.0)  = 1.0;  // รูปร่างโค้งการไล่สี (มากขึ้น = คมขึ้น)

// ดวงอาทิตย์
uniform vec3  sun_dir        = vec3(0.0, 0.8, 0.6); // ต้องเป็นเวกเตอร์หน่วย (ปรับทิศได้)
uniform vec3  sun_color      : source_color = vec3(1.0, 0.95, 0.85);
uniform float sun_size       = 0.996;  // ใกล้ 1 = แคบ/ดวงเล็ก
uniform float sun_glow_size  = 0.985;  // ใกล้ 1 = ฮาโลแคบ
uniform float sun_intensity  = 1.2;

// เมฆ (FBM)
uniform float cloud_scale     = 2.5;
uniform float cloud_coverage  = 0.55;   // 0 โล่ง, 1 ทึบ
uniform float cloud_speed     = 0.02;   // รอบ/วินาที
uniform vec3  cloud_color     : source_color = vec3(1.0, 1.0, 1.0);
uniform float cloud_intensity = 0.25;

// ---- noise helpers ----
float hash21(vec2 p){
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
float fbm(vec2 p){
    float v = 0.0;
    float a = 0.5;
    // Godot 4: mat2 ใช้คอลัมน์เป็น vec2 สองตัว
    mat2 m = mat2(vec2(1.6, -1.2), vec2(1.2, 1.6));
    for (int i = 0; i < 5; i++){
        v += a * noise(p);
        p = m * p;
        a *= 0.5;
    }
    return v;
}

void sky(){
    // SKY_COORDS: vec2 [0..1]^2
    vec2 uv = SKY_COORDS;

    // equirectangular -> ทิศท้องฟ้า
    float phi   = uv.x * 6.28318530718; // 2π
    float theta = uv.y * 3.14159265359; // π
    vec3 dir = vec3(
        sin(theta) * cos(phi),
        cos(theta),
        sin(theta) * sin(phi)
    );

    // ไล่สีบน-ขอบฟ้า
    float t = smoothstep(horizon_height - horizon_softness,
                     horizon_height + horizon_softness,
                     dir.y);
	t = pow(t, horizon_gamma);
    vec3 col = mix(horizon_color, top_color, t);

    // ดวงอาทิตย์ + ฮาโล
    vec3 sdir = normalize(sun_dir);
    float mu = max(dot(dir, sdir), 0.0);
    float sun_disk = smoothstep(sun_size, 1.0, mu);
    float sun_glow = smoothstep(sun_glow_size, 1.0, mu);
    col += sun_color * (sun_disk * sun_intensity + sun_glow * sun_intensity * 0.35);

    // เมฆเคลื่อน
    vec2 cloud_uv = vec2(uv.x + TIME * cloud_speed, uv.y);
    float n = fbm(cloud_uv * cloud_scale);
    float clouds = smoothstep(cloud_coverage, 1.0, n);
    col = mix(col, col * (1.0 - cloud_intensity) + cloud_color * cloud_intensity, clouds);

    COLOR = col; // NOTE: sky shader ใช้ vec3
}
