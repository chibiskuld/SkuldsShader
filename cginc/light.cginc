#pragma once
//keep in mind to always add lights. But multiply the sum to the final color. 
//This method applies ambient light from directional and lightprobes.
float4 applyLight(PIO process, v2f fragin, float4 color) {
	float4 output = float4(0, 0, 0, 1);

	/************************
	* Brightness / toon edge:
	************************/
	//I supply the attenuation to the ToonDot, to be the constant muliplier with dotl calculation, 
	//Before the toon ramp is calculated.
#if defined(UNITY_PASS_FORWARDADD)
	//foward add lighting and details from pixel lights.
	float3 direction = normalize(_WorldSpaceLightPos0.xyz - process.worldPosition.xyz);
	#if defined(POINT_COOKIE) || defined(SPOT) 
		//let spotlights just be spotlights.
		float brightness = dot(direction, process.worldNormal);
		brightness += 1;
		brightness /= 2;
		brightness *= process.attenuation;
	#else
		float brightness = ToonDot(direction, process.worldNormal, process.attenuation);
	#endif
#else
	//Calculate light probes from foward base.
	#if defined(LIGHTMAP_ON)
		float3 ambientDirection = normalize(UnityObjectToWorldNormal(fragin.normal).xyz);
		float lpbrightness = -1.5;
		float2 nm = tex2D(_NormalTex, process.normalUV + process.uvOffset).rg;
		lpbrightness += nm.r;
		lpbrightness += nm.g;
	#else 
		float3 ambientDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz; //do not normalize
		float brightness = ToonDot(ambientDirection, process.worldNormal.xyz, 1);
	#endif
	float directBrightness = ToonDot(normalize(_WorldSpaceLightPos0.xyz), process.worldNormal.xyz, process.attenuation);
#endif

	/************************
	* Color:
	************************/
#if defined(UNITY_PASS_FORWARDADD)
	//get directional color:
	float3 lightColor = _LightColor0.rgb * brightness;
	lightColor *= color.rgb;
	output.rgb += lightColor;
#else

	//Keep in mind color is added, and any time it's added it's +(basecolor * light)
	#if defined(LIGHTMAP_ON)
		float3 lightmapCol = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, fragin.lmuv));
		lightmapCol += _LMBrightness;
		output.rgb += lerp( color.rgb * lightmapCol, color.rgb, _ShadeMin);
		output.rgb = max(0, output.rgb);
		output.rgb *= _FinalBrightness;
		output.rgb *= process.attenuation;
		#if defined(DYNAMICLIGHTMAP_ON)
			output.rgb += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, fragin.dlmuv));
		#endif

		//ambient color (lightprobes)
		float3 probeColor = lpbrightness * _LMProbeAmount;
		output.rgb += probeColor;

		//direct Light
		float3 directColor = _LightColor0.rgb;
		directColor *= directBrightness;
		directColor *= color.rgb;
		output.rgb += directColor * _LMDirectAmount;

		#ifdef VERTEXLIGHT_ON
				float3 vcolor = Shade4PointLightsFixed(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb,
					unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, process.worldPosition, process.worldNormal
				);
				output.rgb += vcolor * color.rgb;
		#endif
	#else
		//ambient color (lightprobes): 
		float3 probeColor = ShadeSH9(float4(0, 0, 0, 1));
		probeColor *= brightness;
		output.rgb += color.rgb * probeColor;
	
		//direct Light
		float3 directColor = _LightColor0.rgb;
		directColor *= directBrightness;
		directColor *= color.rgb;
		output.rgb += directColor;

		//vertex Lights
		#ifdef VERTEXLIGHT_ON
			float3 vcolor = Shade4PointLightsFixed(
				unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
				unity_LightColor[0].rgb, unity_LightColor[1].rgb,
				unity_LightColor[2].rgb, unity_LightColor[3].rgb,
				unity_4LightAtten0, process.worldPosition, process.worldNormal
			);
			output.rgb += vcolor * color.rgb;
		#endif

		//minimum Shade Value (forced ambient):
		output.rgb = lerp(output.rgb, color.rgb, _ShadeMin);
	#endif

	//The final blend
	output.rgb *= (1 - _Height);//height brightness
#endif
	output.a = color.a;
	return output;
}
