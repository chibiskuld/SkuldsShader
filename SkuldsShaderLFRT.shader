Shader "Skuld's Shader/Light From Render Texture"
{
	Properties {
		[space]
		_ShadeRange("Shade Range",Range(0,1)) = 0.5
		_ShadeSoftness("Edge Softness", Range(0,1)) = 0.1
		_ShadePivot("Center",Range(0,1)) = .5
		_ShadeMax("Max Brightness", Range(0,2)) = 2.0
		_ShadeMin("Min Brightness",Range(0,1)) = 0.0
		_LMBrightness("Added Lightmap Brightness", Range(-1,1)) = 0
		_FinalBrightness("Final Brightness",Range(0,5)) = 1

		[space]
		_MainTex("Base Layer", 2D) = "white" {}
		[HDR]_Color("Base Color",Color) = (1,1,1,1)
		_Hue("Hue",Range(-180,180)) = 0
		_Saturation("Saturation",Range(-1,10)) = 0
		_Value("Value",Range(-1,2)) = 0
		_Contrast("Contrast",Range(0,10)) = 1

		[space]//specular, normals, smoothness and normals (Needs Height)
		[Normal] _NormalTex("Normal Map", 2D) = "bump" {}
		_FeatureTex("Feature Map", 2D) = "white" {}
		_NormalScale("Normal Amount", Range(0,1)) = 1.0
		_FresnelColor("Fresnel Color", Color)=(0, 0, 0, 0)
		_FresnelRetract("Fresnel Retract", Range(0,10)) = 1.5
		_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
		_Specular("Specular", Range(0,1)) = 0
		_SpecularSize("Specular Size",Range(.001,1)) = .1
		_SpecularReflection("Specular Reflection",Range(0,1)) = .5
		_SpecularIgnoreAtten("Specular Ignore Attenuation",Int) = 0
		_Smoothness("Smoothness", Range(0,1)) = 0
		_Reflectiveness("Reflectiveness",Range(0,1)) = 0
		_Height("Height",Range(0,1)) = 0
		_ReflectType("Reflection Type",Int) = 0
		
		[space]
		_DetailLayer("Enable Detail Layer",Int) = 0
		_DetailTex("Detail Layer", 2D) = "black" {}
		[HDR]_DetailColor("Detail Color", Color) = (1, 1, 1, 1)
		_DetailUnlit("Detail Unlit", Int) = 0
		_DetailOcclusion("Use as Ambient Occlusion",Int) = 0

		[space]
		_Glow("Detail Glow", Int) = 0
		_GlowAmount("Glow Amount",Range(0,1)) = 1
		_GlowTex("Detail Layer", 2D) = "black" {}
		_GlowColor("Glow Color", Color) = (1, 1, 1, 1)
		_GlowSpeed("Glow Speed",float) = 100.0
		_GlowSqueeze("Glow Squeeze",float) = 10.0
		_GlowSharpness("Glow Sharpness",float) = 1.0
		_GlowDirection("Glow Direction",Int) = 4
		_GlowRainbow("Rainbow Effect", Int) = 0

		_DetailHue("Hue",Range(-180,180)) = 0
		_DetailSaturation("Saturation",Range(-1,10)) = 1
		_DetailValue("Value",Range(-1,2)) = 0

		[space]
		_RenderType("Render Type",Int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Int) = 5                 // "SourceAlpha"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Int) = 10            // "OneMinusSourceAlpha"
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 2                     // "Back"
		_ZWrite("Z-Write",Int) = 1
		_TCut("Transparent Cutout",Range(0,1)) = 1
		_AlphaToMask("Alpha To Mask",Int) = 0

		[space]
		_ETex("Layer 2 Texture", 2D) = "white" {}
		_EBrightness("Emission Amount", Range(0,1)) = 1
		_EPosition("Emission Position",Vector) = (0,0,0,1)
		_ERange("Emission Range",float) = 20
		_ESamples("Samples",Vector) = (16,9,0,0)
	}
	CustomEditor "SkuldsShaderLFRTEditor"

	SubShader {
		Tags { }//defined by Custom Editor now.

        Blend[_SrcBlend][_DstBlend]
        Cull[_CullMode]
		AlphaTest Greater[_TCut] //cut amount
		Lighting Off
		SeparateSpecular On
		ZWrite [_ZWrite]
		AlphaToMask[_AlphaToMask]

		Pass {
			Tags { "LightMode" = "ForwardBase"}
			Name "Toon Base"

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"

			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#define LFRT

			#include "cginc/shared.cginc"

			ENDCG
		}
		Pass {
			Tags { "LightMode" = "ForwardAdd"}
			Blend One One
			Name "Toon Add"

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"

			#pragma target 3.5
			
			#pragma vertex vert
			#pragma fragment frag
			#define LFRT
			
			#pragma multi_compile_instancing
			#pragma multi_compile_fwdadd_fullshadows

			#include "cginc/shared.cginc"

			ENDCG
		}
		Pass {
			Tags { "LightMode" = "ShadowCaster"}
			Name "Shadow Caster"

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"

			#pragma target 3.5
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster_fullshadows

			#include "cginc/shared.cginc"

			ENDCG
		}
		Pass
		{
			Name "META"
			Tags { "LightMode" = "Meta" }

			Cull Off

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta

			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature EDITOR_VISUALIZATION

			#include "UnityStandardMeta.cginc"
			ENDCG
		}
	} 
	FallBack "Diffuse"
}