#if UNITY_EDITOR
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;
using System;

public class SkuldsShaderScrollingEditor : SkuldsShaderEditor
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

        ScrollingOptions();
    }

    bool ScrollGroup = false;
    public static Transform location;
    public enum ScrollDir { UVx, UVy }
    void ScrollingOptions()
    {
        ScrollGroup = EditorGUILayout.Foldout(ScrollGroup, "Scrolling Options", skuldHeader);
        if (ScrollGroup)
        {
            EditorGUILayout.BeginVertical(EditorStyles.textArea);
            MaterialProperty scrolling = FindProperty("_Scrolling", properties);
            materialEditor.FloatProperty(scrolling, "Scrolling Speed:");

            CreatePopupFromProperty("Scrolling Direction:", "_ScrollDir", typeof(ScrollDir));


            EditorGUILayout.EndVertical();
        }
    }
}
#endif