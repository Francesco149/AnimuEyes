// AnimuEyes - procedurally generated anime eyes shader
//   add an extra shader pass to your character model and set uvArea to the uv range where you want
//   the eyes to appear. xy are the middle point of the rectangle, zw are width/height.
//   _if you have other transparent materials, make sure to adjust the render priority_
//   adjust the depthOffset if you don't want them to render through hair or if rendering through
//   hair is wonky
// godot version tested: v4.3.stable.nixpkgs [77dcf97d8]
// license: public domain (UNLICENSE)

shader_type spatial;
render_mode unshaded;

// these are the uniforms that should be dynamically changed for facial expressions and such
uniform vec3 lookAt = vec3(0, 0, 100000); // target point relative to eyes
uniform vec4 maxLook = vec4(-.4, -.2, .4, .2); // eye movement range
uniform vec2 lookSens = vec2(.2, .2); // adjust until eyes match up with the look target
uniform float irisScale : hint_range(.1, 1.5) = 1;
uniform float eyebrowOffset = 0;
uniform float eyebrowRotationOffsetDegrees : hint_range(-180, 180) = 0;
uniform float open : hint_range(0, 1) = 1; // might cause some artifacts, mainly used for blinking

// everything else is only recommended to be used to define the base eye aesthetic
uniform vec4 uvArea = vec4(.5, .5, 1, 1);
uniform float position = .2;
uniform float dist = .2;
uniform float depthOffset = .01;

uniform vec4 irisColor : source_color = vec4(1, .3, 0, 1);
uniform vec4 whiteColor : source_color = vec4(1, 1, 1, 1);
uniform vec4 rimColor : source_color = vec4(1, 1, 1, 1);
uniform vec4 eyebrowColor : source_color = vec4(0, 0, 0, 1);
uniform vec4 border1Color : source_color = vec4(0, 0, 0, 1);
uniform vec4 border2Color : source_color = vec4(0, 0, 0, 1);
uniform vec4 leftIrisColor : source_color = vec4(1, 1, 1, 1);
uniform vec4 rightIrisColor : source_color = vec4(1, 1, 1, 1);
uniform vec4 leftEyeColor : source_color = vec4(1, 1, 1, 1);
uniform vec4 rightEyeColor : source_color = vec4(1, 1, 1, 1);

uniform float shapeSquare : hint_range(0, 1) = .554;
uniform float irisSquare : hint_range(0, 1) = .219;
uniform float border1Square : hint_range(0, 1) = .5;
uniform float border2Square : hint_range(0, 1) = 1;
uniform float eyebrowSquare : hint_range(0, 1) = .5;

uniform vec4 topEllipse = vec4(.444, .598, .5, .4);
uniform vec4 bottomEllipse = vec4(.49, .297, .3, .33);
uniform vec4 irisEllipse = vec4(.53, .35, .17, .236);
uniform vec4 pupilEllipse = vec4(0, .02, .08, .1);

uniform float eyebrowPosition = 0;
uniform vec4 eyebrow = vec4(.037, -.369, 1.1, 1.1);
uniform vec4 eyebrowFalloffEllipse = vec4(.5, -.315, .028, .039);
uniform float eyebrowFalloff : hint_range(0, 1) = .5;
uniform float eyebrowRotationDegrees : hint_range(-180, 180) = -10;
uniform float eyebrowThickness : hint_range(0, .1) = .025;

uniform vec4 border1 = vec4(.025, .016, 1.1, 1.1);
uniform vec4 border1FalloffEllipse = vec4(.222, -.03, .3, .2);
uniform float border1Falloff : hint_range(0, 1) = .3;
uniform float border1RotationDegrees : hint_range(-180, 180) = -3;
uniform float border1Thickness : hint_range(0, .1) = .025;

uniform vec4 border2 = vec4(-.043, .057, .916, 1);
uniform vec4 border2FalloffEllipse = vec4(.5, .861, .03, .049);
uniform float border2Falloff : hint_range(0, 1) = .2;
uniform float border2RotationDegrees : hint_range(-180, 180) = 0;
uniform float border2Thickness : hint_range(0, .1) = .008;

uniform float sharpness : hint_range(100, 1000) = 200;
uniform vec2 scale = vec2(.3, .3);
uniform float attenuation : hint_range(0, 1) = .3;
uniform float irisAttenuation : hint_range(0, 1) = .1;
uniform vec4 highlightEllipse = vec4(.608, .6, .4, .3);
uniform vec2 irisGradientOffset = vec2(0, -.01);
uniform vec4 rim1Ellipse = vec4(0.128, -0.034, .067, .043);
uniform float rim1RotationDegrees : hint_range(-180, 180) = 10;
uniform vec4 rim2Ellipse = vec4(-0.135, 0.057, .05, .03);
uniform float rim2RotationDegrees : hint_range(-180, 180) = 10;

float ellipse(vec2 c, vec2 r, vec2 uv) {
	// this is essentialy doing a circle sdf and then distorting the space by the aspect ratio
	float smallDim = min(r.x, r.y);
	return length((c - uv) / r) * smallDim - smallDim;
}

float ellipse4(vec4 cr, vec2 uv) {
	return ellipse(cr.xy, cr.zw, uv);
}

float rect(vec2 c, vec2 r, vec2 uv) {
	return length(max(abs(uv - c) - r, 0));
}

float rect4(vec4 cr, vec2 uv) {
	return rect(cr.xy, cr.zw, uv);
}

// this gives a smooth transition when doing min distance to combine shapes
float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
	return mix(b, a, h) - k * h * (1.0 - h);
}

float squaredEllipse(vec4 cr, vec2 uv, float squareAmt) {
	float e = ellipse4(cr, uv);
	float r = rect4(vec4(cr.xy, cr.zw * squareAmt), uv);
	return smin(e, r, .3);
}

float hardEdge(float d) {
	return 1.0 - smoothstep(0, 1.0 / sharpness, d);
}

mat2 rotateMat(float deg) {
	float rad = radians(deg);
	float s = sin(rad), c = cos(rad);
	return mat2(vec2(c, -s), vec2(s, c));
}

vec2 rotate(vec2 uv, float deg, vec2 origin) {
	return (uv - origin) * rotateMat(deg) + origin;
}

vec4 openDelta(float openAmt) {
	return -(bottomEllipse - topEllipse) * vec4(0, 1. - openAmt, 0, 0);
}

float shape(vec2 uv, float square, float openAmt) {
	float dTop = squaredEllipse(topEllipse + openDelta(openAmt), uv, square);
	float dBot = squaredEllipse(bottomEllipse, uv, square);
	return max(dTop, dBot);
}

float border(vec2 uv, float ds, vec4 posScale, float rotDeg, vec4 fallEl, float thick,
			 float square, float fall, float openAmt)
{
	// arbitrary small scaling delta to make stuff look better from far away
	float epsilon = ds * .00011;
	vec2 borderUv = rotate((uv + posScale.xy) / posScale.zw, rotDeg, vec2(.5,  .5));
	float dShape = shape(borderUv, square, openAmt); // shape sdf offset by border offset
	float d = bottomEllipse.y - topEllipse.y;
	float dFalloff = ellipse4(fallEl + openDelta(openAmt), borderUv);
	float falloffAmt = 1.0 - smoothstep(0, fall, dFalloff);
	float thicc = thick * falloffAmt;
	float dBorder = abs(dShape - thick * falloffAmt) - thicc; // always touching edge of shape
	float borderAmt = 1.0 - hardEdge(falloffAmt);
	return hardEdge(dBorder / ds + epsilon) * borderAmt;
}

float brow(vec2 uv, float dScale) {
	float r = eyebrowRotationDegrees + eyebrowRotationOffsetDegrees;
	return border(uv, dScale, eyebrow, r, eyebrowFalloffEllipse,
				  eyebrowThickness, eyebrowSquare, eyebrowFalloff, 1);
}

vec4 eye(float flipRims, vec2 uv, vec2 look, float dScale, vec4 eyeIrisColor) {
	float epsilon = dScale * .00011;
	float shapeEdge = hardEdge(shape(uv, shapeSquare, open) / dScale);
	float border1Edge = border(uv, dScale, border1, border1RotationDegrees, border1FalloffEllipse,
							   border1Thickness, border1Square, border1Falloff, open);
	float border2Edge = border(uv, dScale, border2, border2RotationDegrees, border2FalloffEllipse,
							   border2Thickness, border2Square, border2Falloff, open);
	vec4 irisE = irisEllipse;
	irisE.xy += look;
	irisE.zw *= irisScale;
	float dIris = squaredEllipse(irisE, uv, irisSquare) / dScale;
	float dIrisGradient = squaredEllipse(irisE, uv + irisGradientOffset, irisSquare);
	float irisEdge = hardEdge(dIris + epsilon * .5);
	float irisGradient = (1.0 - smoothstep(-.001, -.03, dIrisGradient)) * irisEdge;
	vec4 pupilE = pupilEllipse;
	pupilE.xy += irisE.xy;
	pupilE.zw *= irisScale;
	float dPupil = ellipse4(pupilE, uv);
	float pupilEdge = 1.0 - smoothstep(0, .035, dPupil);
	float highlight = ellipse4(highlightEllipse, uv);
	float highlightEdge = smoothstep(0, .05, highlight);
	vec4 r1 = rim1Ellipse;
	vec4 r2 = rim2Ellipse;
	r1.x *= flipRims;
	r2.x *= flipRims;
	r1.xy += irisE.xy;
	r2.xy += irisE.xy;
	float dRim1 = ellipse4(r1, rotate(uv, rim1RotationDegrees * flipRims, r1.xy));
	float rim1Edge = hardEdge(dRim1 / dScale + epsilon);
	float dRim2 = ellipse4(r2, rotate(uv, rim2RotationDegrees * flipRims, r2.xy));
	float rim2Edge = hardEdge(dRim2 / dScale + epsilon);
	vec4 col = vec4(0, 0, 0, 0);
	col = mix(col, whiteColor, shapeEdge);
	col = mix(col, eyeIrisColor, irisEdge);
	col = mix(col, eyeIrisColor * irisAttenuation, pupilEdge);
	col = mix(col, col * irisAttenuation, irisGradient);
	col = mix(col, col * attenuation, highlightEdge);
	col = mix(col, rimColor, max(rim1Edge, rim2Edge));
	col = mix(col, border1Color, border1Edge);
	col = mix(col, border2Color, border2Edge);
	col.a = max(max(shapeEdge, border1Edge), border2Edge);
	return col;
}

// maps uvs that fall into area (x, y, width, height) to 0.0-1.0 - this way functions don't need
// to be aware of position and scale
vec2 toLocal(vec2 uv, vec4 area) {
	return (uv - area.xy) / area.zw + .5;
}

void fragment() {
	// this is used to scale smoothsteps so it's equally smooth regardless of distance.
	// if I didn't do this, it would become blurry close-up and aliased from afar
	float dScale = abs(VERTEX.z) / scale.x;
	vec2 uv = toLocal(UV, uvArea);
	uv = (uv - .5) / vec2(uvArea.z / uvArea.w, 1) + .5; // adjust for uvArea aspect ratio
	dScale /= uvArea.z;
	vec3 look = normalize(lookAt);
	look.xy *= lookSens;
	look.xy = clamp(look.xy, maxLook.xy, maxLook.zw);
	look.x *= -1.;
	vec4 right = eye(1, toLocal(uv, vec4(.5 - dist, position, scale.x, scale.y)), look.xy, dScale,
								irisColor * rightIrisColor) * rightEyeColor;
	look.x *= -1.;
	vec4 left = eye(-1, toLocal(uv, vec4(.5 + dist, position, -scale.x, scale.y)), look.xy, dScale,
								irisColor * leftIrisColor) * leftEyeColor;
	float browpos = eyebrowOffset + eyebrowPosition;
	float browR = brow(toLocal(uv, vec4(.5 - dist, browpos, scale.x, scale.y)), dScale);
	float browL = brow(toLocal(uv, vec4(.5 + dist, browpos, -scale.x, scale.y)), dScale);
	vec4 col = mix(right, left, left.a);
	col = mix(col, eyebrowColor, max(browR, browL));
	ALPHA = col.a;
	ALBEDO = col.rgb;
	// adjust depth to render through hair
	vec4 fragpos = FRAGCOORD * INV_PROJECTION_MATRIX;
	fragpos.z += depthOffset; // view space Z
	DEPTH = (fragpos * PROJECTION_MATRIX).z;
}
