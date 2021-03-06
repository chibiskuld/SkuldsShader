﻿#if UNITY_EDITOR
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

public class SkuldsShaderTerrainEditor : ShaderGUI
{

    protected MaterialEditor materialEditor;
    protected MaterialProperty[] properties;
    protected Material material;
    protected GUIStyle skuldHeader = null;
    protected bool initialized = false;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.materialEditor = materialEditor;
        this.properties = properties;
        this.material = materialEditor.target as Material;

        if (!initialized) Initialize(materialEditor, properties);

        TerrainOptions();
        HSVOptions();
        RenderOptions();
        GrassOptions();
        LightOptions();
        FeaturesOptions();
        FeatureMapCreator();

    }

    //The gui will only initialize when displayed in the inspector. 
    void Initialize(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        if (skuldHeader == null)
        {
            skuldHeader = EditorStyles.foldout;
            skuldHeader.fontStyle = FontStyle.Bold;
            skuldHeader.fontSize = 14;
            skuldHeader.normal.textColor = new Color(.25f, 0, .5f);
            skuldHeader.margin.bottom = 5;
            skuldHeader.margin.top = 5;
        }

        initialized = true;
    }



    bool FeaturesGroup = false;
    public enum ReflectType { Lerp, Multiply, Add }
    void FeaturesOptions()
    {
        FeaturesGroup = EditorGUILayout.Foldout(FeaturesGroup, "Light Enhancements", skuldHeader);
        if (FeaturesGroup)
        {
            //SSRH
            EditorGUILayout.LabelField("Feature Control:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty specular = FindProperty("_Specular", properties);
            materialEditor.RangeProperty(specular, "Specular Scale:");
            MaterialProperty smoothness = FindProperty("_Smoothness", properties);
            materialEditor.RangeProperty(smoothness, "Smoothness Scale:");
            MaterialProperty reflect = FindProperty("_Reflectiveness", properties);
            materialEditor.RangeProperty(reflect, "Reflective Scale:");
            MaterialProperty height = FindProperty("_Height", properties);
            materialEditor.RangeProperty(height, "Height Scale:");
            EditorGUILayout.HelpBox("The feature texture is an rgba texture with the following mapping: specular, smoothness, reflective, and height.", MessageType.Info);
            EditorGUILayout.EndVertical();

            //normals
            EditorGUILayout.LabelField("Normals:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty normalScale = FindProperty("_NormalScale", properties);
            materialEditor.RangeProperty(normalScale, "Scale:");
            EditorGUILayout.EndVertical();

            EditorGUILayout.LabelField("Specular Extended:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty specColor = FindProperty("_SpecularColor", properties);
            materialEditor.ColorProperty(specColor, "Color:");
            MaterialProperty specSize = FindProperty("_SpecularSize", properties);
            materialEditor.RangeProperty(specSize, "Size:");
            MaterialProperty specRef = FindProperty("_SpecularReflection", properties);
            materialEditor.RangeProperty(specRef, "Reflection Balance:");
            CreateToggleFromProperty("Ignore Attenuation:", "_SpecularIgnoreAtten");
            EditorGUILayout.EndVertical();
            /*
            EditorGUILayout.LabelField("Fresnel:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty color = FindProperty("_FresnelColor", properties);
            materialEditor.ColorProperty(color, "Color:");
            MaterialProperty retract = FindProperty("_FresnelRetract", properties);
            materialEditor.RangeProperty(retract, "Retract:");
            EditorGUILayout.EndVertical();
            */

            EditorGUILayout.LabelField("Other:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            CreatePopupFromProperty("Reflection Type:", "_ReflectType", typeof(ReflectType));
            EditorGUILayout.EndVertical();
        }
    }

    bool featureMapGroup = false;
    public static Texture2D specTex;
    public static Texture2D smoothTex;
    public static Texture2D reflectTex;
    public static Texture2D heightTex;
    public static Texture2D resultTex;
    void FeatureMapCreator()
    {
        featureMapGroup = EditorGUILayout.Foldout(featureMapGroup, "Create RGBA Texture", skuldHeader);
        if (featureMapGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            specTex = (Texture2D)EditorGUILayout.ObjectField("Red Channel Texture:", specTex, typeof(Texture2D), true);
            smoothTex = (Texture2D)EditorGUILayout.ObjectField("Green Channel Texture:", smoothTex, typeof(Texture2D), true);
            reflectTex = (Texture2D)EditorGUILayout.ObjectField("Blue Channel Texture:", reflectTex, typeof(Texture2D), true);
            heightTex = (Texture2D)EditorGUILayout.ObjectField("Alpha Channel Texture:", heightTex, typeof(Texture2D), true);
            resultTex = (Texture2D)EditorGUILayout.ObjectField("Final Texture (RGBA png):", resultTex, typeof(Texture2D), true);
            EditorGUILayout.HelpBox("These textures need to be grayscale, if not, only the red channel will be used.\n Warning: Result texture is required, and will be written to. Create an empty image at the desired resolution and place it result slot.", MessageType.Info);
            EditorGUILayout.EndVertical();
            if (GUILayout.Button("Create"))
            {
                MakeFeatureTexture();
            }
        }
    }

    float GetValue(int i, Texture2D tex)
    {
        int ix = i % resultTex.width;
        int iy = i / resultTex.width;
        int x = (int)(((float)ix / (float)resultTex.width) * resultTex.width);
        int y = (int)(((float)iy / (float)resultTex.height) * resultTex.height);
        if (tex)
        {
            Color col = tex.GetPixel(x, y);
            return col.r;
        }
        else
        {
            return 1.0f;
        }
    }

    void MakeFeatureTexture()
    {
        if (resultTex == null)
        {
            Debug.LogError("Cannot create texture, no result texture specified.");
        }
        Color[] colors = resultTex.GetPixels();
        for (int i = 0; i < colors.Length; i++)
        {
            Color color = new Color(
                GetValue(i, specTex),
                GetValue(i, smoothTex),
                GetValue(i, reflectTex),
                GetValue(i, heightTex)
            );
            colors[i] = color;
        }
        Texture2D outputTex = new Texture2D(resultTex.width, resultTex.height, TextureFormat.RGBAFloat, false);
        outputTex.SetPixels(colors);
        outputTex.Apply();
        System.IO.File.WriteAllBytes(
            UnityEditor.AssetDatabase.GetAssetPath(resultTex),
            outputTex.EncodeToPNG()
        );
        EditorUtility.SetDirty(resultTex);
        Debug.Log("Saved Features Texture");
    }



    bool DetailGroup = false;
    void GrassOptions()
    {
        DetailGroup = EditorGUILayout.Foldout(DetailGroup, "Grass", skuldHeader);
        if (DetailGroup)
        {
            bool enabledDetails = CreateToggleFromProperty("Enabled:", "_DetailLayer");
            if (enabledDetails)
            {
                EditorGUILayout.BeginVertical(EditorStyles.textArea);
                bool unlit = CreateToggleFromProperty("Unlit:", "_DetailUnlit");
                //bool occlusion = CreateToggleFromProperty("Use As Ambient Occlusion:", "_DetailOcclusion");
                MaterialProperty tex = FindProperty("_DetailTex", properties);
                materialEditor.TextureProperty(tex, "Grass Texture:");
                MaterialProperty color = FindProperty("_DetailColor", properties);
                materialEditor.ColorProperty(color, "Color:");
                MaterialProperty hue = FindProperty("_DetailHue", properties);
                materialEditor.RangeProperty(hue, "Hue:");
                MaterialProperty saturation = FindProperty("_DetailSaturation", properties);
                materialEditor.RangeProperty(saturation, "Saturation:");
                MaterialProperty value = FindProperty("_DetailValue", properties);
                materialEditor.RangeProperty(value, "Value:");
                MaterialProperty grassDistance = FindProperty("_GrassDistance", properties);
                materialEditor.FloatProperty(grassDistance, "Grass Distance:");
                EditorGUILayout.EndVertical();
            }
        }
    }



    bool GlowGroup = false;
    public enum GlowDirection { WorldX, WorldY, WorldZ, UVX, UVY }
    void GlowOptions()
    {
        GlowGroup = EditorGUILayout.Foldout(GlowGroup, "Glow Mask", skuldHeader);
        if (GlowGroup)
        {
            bool glow = CreateToggleFromProperty("Enabled:", "_Glow");
            if (glow)
            {
                EditorGUILayout.BeginVertical(EditorStyles.textArea);
                MaterialProperty glowAmount = FindProperty("_GlowAmount", properties);
                materialEditor.RangeProperty(glowAmount, "Glow Amount:");
                MaterialProperty glowTex = FindProperty("_GlowTex", properties);
                materialEditor.TextureProperty(glowTex, "Mask:");
                CreatePopupFromProperty("Glow Direction:", "_GlowDirection", typeof(GlowDirection));
                MaterialProperty glowColor = FindProperty("_GlowColor", properties);
                materialEditor.ColorProperty(glowColor, "Color:");
                CreateToggleFromProperty("Rainbow Effect:", "_GlowRainbow");
                MaterialProperty glowSpeed = FindProperty("_GlowSpeed", properties);
                materialEditor.FloatProperty(glowSpeed, "Speed:");
                MaterialProperty glowSqueeze = FindProperty("_GlowSqueeze", properties);
                materialEditor.FloatProperty(glowSqueeze, "Squeeze:");
                MaterialProperty glowSharpness = FindProperty("_GlowSharpness", properties);
                materialEditor.FloatProperty(glowSharpness, "Sharpness:");
                EditorGUILayout.EndVertical();
            }
        }
    }


    bool lightGroup = false;
    void LightOptions()
    {

        lightGroup = EditorGUILayout.Foldout(lightGroup, "Lighting", skuldHeader);
        if (lightGroup)
        {
            EditorGUILayout.LabelField("Non-Static Light Options:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty range = FindProperty("_ShadeRange", properties);
            materialEditor.RangeProperty(range, "Range:");
            MaterialProperty softness = FindProperty("_ShadeSoftness", properties);
            materialEditor.RangeProperty(softness, "Softness:");
            MaterialProperty pivot = FindProperty("_ShadePivot", properties);
            materialEditor.RangeProperty(pivot, "Center:");
            MaterialProperty min = FindProperty("_ShadeMin", properties);
            materialEditor.RangeProperty(min, "Minimum:");
            MaterialProperty max = FindProperty("_ShadeMax", properties);
            materialEditor.RangeProperty(max, "Maximum:");
            EditorGUILayout.EndVertical();

            EditorGUILayout.LabelField("Static Light Options:", EditorStyles.boldLabel);
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty lmb = FindProperty("_LMBrightness", properties);
            materialEditor.RangeProperty(lmb, "Light Map Brightness Adjustment:");
            MaterialProperty lmfb = FindProperty("_FinalBrightness", properties);
            materialEditor.RangeProperty(lmfb, "Final Brightness Multiplier:");
            EditorGUILayout.EndVertical();
        }
    }



    bool baseGroup = false;
    void HSVOptions()
    {
        baseGroup = EditorGUILayout.Foldout(baseGroup, "Color, Hue, Saturation and Value", skuldHeader);
        if (baseGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty color = FindProperty("_Color", properties);
            materialEditor.ColorProperty(color, "Color:");
            MaterialProperty hue = FindProperty("_Hue", properties);
            materialEditor.RangeProperty(hue, "Hue:");
            MaterialProperty saturation = FindProperty("_Saturation", properties);
            materialEditor.RangeProperty(saturation, "Saturation:");
            MaterialProperty value = FindProperty("_Value", properties);
            materialEditor.RangeProperty(value, "Value:");
            MaterialProperty contrast = FindProperty("_Contrast", properties);
            materialEditor.RangeProperty(contrast, "Contrast:");
            EditorGUILayout.EndVertical();
        }
    }

    bool renderGroup = false;
    public enum RenderType { Opaque, Transparent, TransparentCutout, Background, Overlay, TreeOpaque, TreeTransparentCutout, TreeBillboard, Grass, GrassBillboard };
    void RenderOptions()
    {
        renderGroup = EditorGUILayout.Foldout(renderGroup, "Rendering", skuldHeader);
        if (renderGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            //render Type:
            RenderType renderType = (RenderType)CreatePopupFromProperty("Render Type:", "_RenderType", typeof(RenderType));
            if (renderType == RenderType.TransparentCutout)
            {
                MaterialProperty tCut = FindProperty("_TCut", properties);
                materialEditor.RangeProperty(tCut, "Transparent Cutout:");
            }
            material.SetOverrideTag("RenderType", renderType.ToString());
            //blending,etc:
            CreatePopupFromProperty("Source Blend:", "_SrcBlend", typeof(UnityEngine.Rendering.BlendMode));
            CreatePopupFromProperty("Destination Blend:", "_DstBlend", typeof(UnityEngine.Rendering.BlendMode));
            CreatePopupFromProperty("Cull Mode:", "_CullMode", typeof(UnityEngine.Rendering.CullMode));
            bool zWrite = CreateToggleFromProperty("Enable Z-write:", "_ZWrite");
            bool alpha = CreateToggleFromProperty("Enable Alpha To Mask:", "_AlphaToMask");

            materialEditor.EnableInstancingField();
            materialEditor.DoubleSidedGIField();
            materialEditor.RenderQueueField();
            EditorGUILayout.EndVertical();
        }
    }

    bool CreateToggleFromProperty(string label, string property)
    {
        MaterialProperty prop = FindProperty(property, properties);
        bool value = (prop.floatValue != 0.0f) ? true : false;
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label(label);
        value = EditorGUILayout.Toggle(value);
        material.SetInt(property, (value) ? 1 : 0);
        EditorGUILayout.EndHorizontal();
        return value;
    }

    int CreatePopupFromProperty(string label, string property, System.Type type)
    {
        int value = 0;
        System.Array enumValues = System.Enum.GetValues(type);
        string[] values = new string[enumValues.Length];
        for (int i = 0; i < enumValues.Length; i++)
        {
            values[i] = enumValues.GetValue(i).ToString();
        }

        MaterialProperty prop = FindProperty(property, properties);
        value = (int)prop.floatValue;
        value = EditorGUILayout.Popup(label, value, values);
        material.SetInt(property, value);
        return value;
    }

    bool TerrainGroup = false;
    public static Transform location;
    void TerrainOptions()
    {
        TerrainGroup = EditorGUILayout.Foldout(TerrainGroup, "Terrain", skuldHeader);
        if (TerrainGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty clipDistance = FindProperty("_ClipDistance", properties);
            materialEditor.FloatProperty(clipDistance, "Clip Distance:");
            MaterialProperty fadeRange = FindProperty("_FadeRange", properties);
            materialEditor.FloatProperty(fadeRange, "Fade Range:");
            MaterialProperty grassHeight = FindProperty("_GrassHeight", properties);
            materialEditor.FloatProperty(grassHeight, "Grass Begin Height:");;

            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            EditorGUILayout.LabelField("Layer 0:", EditorStyles.boldLabel);
            MaterialProperty basetex = FindProperty("_MainTex", properties);
            materialEditor.TextureProperty(basetex, "texture:");
            MaterialProperty basenormal = FindProperty("_NormalTex", properties);
            materialEditor.TextureProperty(basenormal, "normals:");
            EditorGUILayout.EndVertical();

            MaterialProperty[] height = new MaterialProperty[7];
            MaterialProperty[] tex = new MaterialProperty[7];
            MaterialProperty[] normal = new MaterialProperty[7];
            for ( int i = 1; i < 4; i++)
            {
                EditorGUILayout.BeginVertical(EditorStyles.textArea);

                EditorGUILayout.LabelField("Layer " + i + ":", EditorStyles.boldLabel);

                height[i - 1] = FindProperty("_Height"+i, properties);
                materialEditor.FloatProperty(height[i - 1], "Height:");

                tex[i - 1] = FindProperty("_Tex"+i, properties);
                materialEditor.TextureProperty(tex[i - 1], "texture:");

                normal[i - 1] = FindProperty("_Normal"+i, properties);
                materialEditor.TextureProperty(normal[i - 1], "normals:");

                EditorGUILayout.EndVertical();
            }

            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            EditorGUILayout.LabelField("Pathways:", EditorStyles.boldLabel);
            MaterialProperty pathwayTex = FindProperty("_GlowTex", properties);
            materialEditor.TextureProperty(pathwayTex, "Path Way Texture:");
            MaterialProperty pathwayMap = FindProperty("_FeatureTex", properties);
            materialEditor.TextureProperty(pathwayMap, "Path Way Map:");
            EditorGUILayout.EndVertical();

            EditorGUILayout.EndVertical();
        }
    }
}
#endif