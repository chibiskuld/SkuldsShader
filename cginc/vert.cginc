#pragma once
v2f vert( IO v ){
	v2f output;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, output);
#if defined(WINDY)
	v.vertex.z += cos(_Time.y * .25f + v.vertex.z) * (v.vertex.y * v.vertex.y) * .001f;
#endif
	output.pos = UnityObjectToClipPos(v.vertex);
	output.objectPosition = v.vertex;

	output.normal = normalize(v.normal);
#if defined (SCROLLING)
	switch (_ScrollDir) {
		case 0:
			v.uv.x += _Time.x * _Scrolling;
			break;
		default:
		case 1:
			v.uv.y += _Time.x * _Scrolling;
			break;
	}
#endif
	output.uv = v.uv;
	
	output.tangent = v.tangent;

	output.vid = v.id;
	
#if !defined(UNITY_PASS_SHADOWCASTER)
	TRANSFER_SHADOW(output)
#endif
#ifdef VERTEXLIGHT_ON
	float3 worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
	float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
	output.vcolor = Shade4PointLightsFixed(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, worldPosition, worldNormal
	);
#endif
#if defined(LIGHTMAP_ON)
	output.lmuv = v.lmuv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
#if defined(DYNAMICLIGHTMAP_ON)
	output.dlmuv = v.dlmuv.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

	return output;
}
