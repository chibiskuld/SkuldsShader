#pragma once
#define BINORMAL_PER_FRAGMENT

#if defined(TERRAIN)
float _FadeRange;

sampler2D _Tex3;
float4 _Tex3_ST;
sampler2D _Tex2;
float4 _Tex2_ST;
sampler2D _Tex1;
float4 _Tex1_ST;

sampler2D _Normal3;
float4 _Normal3_ST;
sampler2D _Normal2;
float4 _Normal2_ST;
sampler2D _Normal1;
float4 _Normal1_ST;

float _Height1;
float _Height2;
float _Height3;
float _GrassHeight;
float _GrassDistance;
float _ClipDistance;

//Mask Layer Paramters
int _DetailLayer;
int _DetailUnlit; //OPTION IGNORED!

float4 _DetailColor;
float _DetailHue;
float _DetailSaturation;
float _DetailValue;
#endif

//general IO with Semantics
struct IO
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	uint id : SV_VertexID;
	float4 tangent : TANGENT;
#if defined(LIGHTMAP_ON)
	float2 lmuv : TEXCOORD1;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


//processed IO to be used by submethods
//do not add things in here that do not need to be interporlated, 
//and transferred from vert to frag. Smaller is better, unless graphically.
//plus less means the terrain can do more.
struct v2f
{
	float4 pos : SV_POSITION; //the Position relative to the screen
	//this needs to be here, to carry along.
	float4 objectPosition : POSITION2; //The position relative to the mesh origin. 
	float3 normal : NORMAL; //The normal in screen space.
	float2 uv : TEXCOORD0; //uv coordinates
	float4 tangent : TEXCOORD5;//for bump mapping.
	float vid : VERTEXID;
	float instanceID : INSTANCEID;

#if defined(VERTEXLIGHT_ON)
	float3 vcolor : VCOLOR;
#endif
#if defined(LIGHTMAP_ON)
	float2 lmuv : TEXCOORD1;
#endif
#if !defined(UNITY_PASS_SHADOWCASTER)
	SHADOW_COORDS(7)
#endif
#if defined(TERRAIN)
	fixed detail : DETAIL;
#endif
};

//processed IO to be used by submethods
struct PIO
{
	float3 worldPosition : TEXCOORD3; //the position relative to world origin.
	float3 viewDirection : TEXCOORD4; //The direction the camera is looking at the mesh.
	float attenuation : ATTENUATION;
	float2 detailUV : DETAILUV;
	float2 normalUV : NORMALUV;
	float2 featureUV : FEATUREUV;
	float2 glowUV : GLOWUV;
	float3 binormal : TEXCOORD6; //also for bump mapping.
	float4 worldTangent : TANGENT1;  //more bump mapping.
	float3 worldNormal : TEXCOORD2; //The normal in world space.
	float2 uvOffset : PARALLAX;
};

int _RenderType;
float _LMBrightness;
float _FinalBrightness;

//Base Layer paramters
sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _DetailTex;
float4 _DetailTex_ST;
sampler2D _FeatureTex;
float4 _FeatureTex_ST;
sampler2D _NormalTex;
float4 _NormalTex_ST;
sampler2D _GlowTex;
float4 _GlowTex_ST;
float4 _Color;
float _TCut;

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;
sampler2D _CameraGBufferTexture4;

#if defined (SHADOWS_SCREEN)
//sampler2D _ShadowMapTexture;
#endif

#if defined (SCROLLING)
int _ScrollDir;
float _Scrolling;
#endif

#if !UNITY_PASS_SHADOWCASTER
	#include "featureMap.cginc"
	#include "toon.cginc"
	#include "vertexLights.cginc"
	#include "HSV.cginc"
	#if !defined(TERRAIN)
	#include "detailLayer.cginc"
	#endif
	#include "glow.cginc"
	#include "shadows.cginc"
	#if defined(LFRT)
	#include "lfrt.cginc"
	#endif
	#include "light.cginc"
	#include "normals.cginc"
	#include "specular.cginc"
	#include "reflections.cginc"
	#include "height.cginc"
	#include "vert.cginc"
	#include "adjustProcess.cginc"
	#if defined(TERRAIN)
	#include "cginc/terrainGeom.cginc"
	#include "terrainFrag.cginc"
	#else
	#include "frag.cginc"
	#endif
#else 
	#include "featureMap.cginc"
	#include"height.cginc"
	#include "normals.cginc"
	#include "adjustProcess.cginc"
	#include "vert.cginc"
	#include "shadowFrag.cginc"
	#if defined(TERRAIN)
	#include "cginc/terrainGeom.cginc"
	#endif
#endif
