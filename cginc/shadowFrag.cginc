#pragma once
fixed4 frag(v2f fragin, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	PIO process = createProcess(fragin, isFrontFace);
	float4 color = tex2D(_MainTex, fragin.uv + process.uvOffset) * _Color;
	if (_RenderType == 2) {
		clip(color.a - _TCut);
	}
	SHADOW_CASTER_FRAGMENT(fragin)
}

#if defined(TERRAIN)
fixed4 terrainFrag(v2f fragin, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(fragin);
}
#endif