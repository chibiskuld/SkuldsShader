#pragma once
float4 frag(v2f fragin, uint isFrontFace : SV_IsFrontFace) : SV_Target
{
	PIO process = createProcess(fragin, isFrontFace);

	float4 color = tex2D(_MainTex, fragin.uv + process.uvOffset) * _Color;
	if (_RenderType == 2) {
		clip(color.a - _TCut);
	}


	float finalAlpha = color.a;
	color = HSV(color, _Hue, _Saturation, _Value);
	color = Contrast(color, _Contrast);
	//apply contrast

	float4 baseColor = color; //for any alternative calculations.

	#ifdef UNITY_PASS_FORWARDBASE
		color = applyDetailLayer(process, fragin, color, 1-_DetailUnlit);

		color = applyFresnel(process, fragin, color);
		color = applySpecular(process, fragin, color);
		color = applyLight(process, fragin, color);
		color = applyReflectionProbe( process, fragin, color, _Smoothness, _Reflectiveness);

		color = applyDetailLayer(process, fragin, color, _DetailUnlit);
		
		#if defined(LFRT)
			baseColor = applyDetailLayer(process, fragin, baseColor, 1 - _DetailUnlit);
			baseColor = applySpecular(process, fragin, baseColor);
			baseColor = applyReflectionProbe(process, fragin, baseColor, _Smoothness, _Reflectiveness);
			//just gets added like a foward add light.
			color = applyLFRTColor(process, fragin, color, baseColor);
		#endif
		color = max(color,0);
		color = applyGlow(process, fragin, color);
	#else
		color = applyDetailLayer(process, fragin, color, 1 - _DetailUnlit);

		color = applySpecular(process, fragin, color);
		color = applyLight(process, fragin, color);

		//I'm still not quiet sure what would be the correct way to handle reflections with Forward add. For now, ommitting.
		//color = applyReflectionProbe(color, process, _Smoothness, _Reflectiveness);
		//color = lerp(color, 0, _Reflectiveness);

		color = applyDetailLayerForward(process, fragin, color, _DetailUnlit);
		color = max(color,0);
		color = applyGlowForward(process, fragin, color);
	#endif

	
	if (_RenderType == 0 || _RenderType == 2 ) {
		color.a = 1;
	}
	else {
		color.a = finalAlpha;
	}

	return color;
}