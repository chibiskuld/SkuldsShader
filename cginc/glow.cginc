#pragma once
int _Glow;
float4 _GlowColor;
float _GlowSpeed;
float _GlowSqueeze;
float _GlowSharpness;
int _GlowRainbow;
float _GlowAmount;
float _GlowDirection;
int _GlowDirect;

//just to make sure there's no repeat code:
float4 getGlowAmount(PIO process, v2f fragin, float mask ) {
	float glowAmt = 1;
	float d = _Time.x * _GlowSpeed;
	switch (_GlowDirection) {
	case 0:
		d += process.worldPosition.x * _GlowSqueeze;
		break;
	case 1:
		d += process.worldPosition.y * _GlowSqueeze;
		break;
	case 2:
		d += process.worldPosition.z * _GlowSqueeze;
		break;
	case 3:
		d += fragin.uv.x * _GlowSqueeze;
		break;
	case 4:
		d += fragin.uv.y * _GlowSqueeze;
		break;
	}
	glowAmt = cos(d) * _GlowSharpness;
	glowAmt += 1 - _GlowSharpness;
	glowAmt = saturate(glowAmt);
	glowAmt *= _GlowAmount;
	glowAmt *= mask;

	return glowAmt;
}

float4 applyGlowForward(PIO process, v2f fragin, float4 col) {
	if (_Glow != 1) {
		return col;
	}
	float4 mask = tex2D(_GlowTex, fragin.uv + process.uvOffset);

	float glowAmt = getGlowAmount(process, fragin, mask.a);

	col.rgb *= 1 - glowAmt;

	return col;
}

float4 applyGlow(PIO process, v2f fragin, float4 col) {
	if (_Glow != 1) {
		return col;
	}
	float4 mask = tex2D(_GlowTex, process.glowUV + process.uvOffset);

	float3 glowCol = mask.rgb;
	if (_GlowRainbow == 1) {
		glowCol *= shiftColor(float3(1, 0, 0), _Time.y * 360);
	}
	glowCol *= _GlowColor.rgb;

	if (_GlowDirect < 1) {
		float glowAmt = getGlowAmount(process, fragin, mask.a);
		glowAmt *= mask.a;
		col.rgb = lerp(col.rgb, glowCol, glowAmt);
	}
	else {
#if defined(UNITY_PASS_FORWARDBASE)
		float glowAmt = saturate(_LightColor0.a);
		glowAmt *= mask.a;
		glowAmt *= _GlowAmount;
		col.rgb = lerp(col.rgb, glowCol, glowAmt);
#endif
	}

	return col;
}
