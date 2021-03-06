using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using publicVariables;

public class RhyFlatLitMMDEditor2xEmission : ShaderGUI
{
    public class MyToggleDrawer : MaterialPropertyDrawer
    {
        // Draw the property inside the given rect
        public override void OnGUI(Rect position, MaterialProperty prop, String label, MaterialEditor editor)
        {
            // Setup
            bool value = (prop.floatValue != 0.0f);

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;

            // Show the toggle control
            value = EditorGUILayout.Toggle(label, value);

            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                // Set the new value if it has changed
                prop.floatValue = value ? 1.0f : 0.0f;
            }
        }
    }

    public enum BlendMode
    {
        Opaque,
        Cutout,
        Fade,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
        Transparent // Physically plausible transparency mode, implemented as alpha pre-multiply
    }

    MaterialProperty blendMode;
    MaterialProperty cullMode;
    MaterialProperty mainTexture;
    MaterialProperty opacity;
    MaterialProperty color;
    MaterialProperty colorMask;
    MaterialProperty colIntensity;
    MaterialProperty sphereAddTexture;
    MaterialProperty sphereAddIntensity;
    MaterialProperty sphereAddMask;
    MaterialProperty sphereMulTexture;
    MaterialProperty sphereMulIntensity;
    MaterialProperty toonTex;
    MaterialProperty shadowTex;
    MaterialProperty shadowMask;
    MaterialProperty defaultLightDir;
    MaterialProperty emissionMap;
    MaterialProperty emissionColor;
    MaterialProperty emissionAltColor;
    MaterialProperty emissionMask;
    MaterialProperty emissionIntensity;
    MaterialProperty speedX;
    MaterialProperty speedY;
    MaterialProperty emissionMap2;
    MaterialProperty emissionColor2;
    MaterialProperty emissionAltColor2;
    MaterialProperty emissionMask2;
    MaterialProperty emissionIntensity2;
    MaterialProperty speedX2;
    MaterialProperty speedY2;
    MaterialProperty normalMap;
    MaterialProperty alphaCutoff;
    MaterialProperty specularBleed;
    MaterialProperty clampMin;
    MaterialProperty clampMax;
    MaterialProperty emissionToggle;
    MaterialProperty emissionToggle2;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        { //Find Properties
            blendMode = FindProperty("_Mode", props);
            cullMode = FindProperty("_Cull", props);
            mainTexture = FindProperty("_MainTex", props);
            opacity = FindProperty("_Opacity", props);
            color = FindProperty("_Color", props);
            colorMask = FindProperty("_ColorMask", props);
            colIntensity = FindProperty("_ColorIntensity", props);
            sphereAddTexture = FindProperty("_SphereAddTex", props);
            sphereAddIntensity = FindProperty("_SphereAddIntensity", props);
            sphereAddMask = FindProperty("_SphereMap", props);
            sphereMulTexture = FindProperty("_SphereMulTex", props);
            sphereMulIntensity = FindProperty("_SphereMulIntensity", props);
            toonTex = FindProperty("_ToonTex", props);
            shadowTex = FindProperty("_ShadowTex", props);
            shadowMask = FindProperty("_ShadowMask", props);
            defaultLightDir = FindProperty("_DefaultLightDir", props);
            emissionMap = FindProperty("_EmissionMap", props);
            emissionColor = FindProperty("_EmissionColor", props);
            emissionAltColor = FindProperty("_EmissionAltColor", props);
            emissionMask = FindProperty("_EmissionMask", props);
            emissionIntensity = FindProperty("_EmissionIntensity", props);
            speedX = FindProperty("_SpeedX", props);
            speedY = FindProperty("_SpeedY", props);
            emissionMap2 = FindProperty("_EmissionMap2", props);
            emissionColor2 = FindProperty("_EmissionColor2", props);
            emissionAltColor2 = FindProperty("_EmissionAltColor2", props);
            emissionMask2 = FindProperty("_EmissionMask2", props);
            emissionIntensity2 = FindProperty("_EmissionIntensity2", props);
            speedX2 = FindProperty("_SpeedX2", props);
            speedY2 = FindProperty("_SpeedY2", props);
            normalMap = FindProperty("_BumpMap", props);
            alphaCutoff = FindProperty("_Cutoff", props);
            specularBleed = FindProperty("_SpecularBleed", props);
            clampMin = FindProperty("_ClampMin", props);
            clampMax = FindProperty("_ClampMax", props);
            clampMin = FindProperty("_ClampMin", props);
            clampMax = FindProperty("_ClampMax", props);
            emissionToggle = FindProperty("_EmissionToggle", props);
            emissionToggle2 = FindProperty("_EmissionToggle2", props);
        }
        
        Material material = materialEditor.target as Material;
        bool ToggleEmission = false;
        bool ToggleEmission2 = false;

        { //Shader Properties GUI
            EditorGUIUtility.labelWidth = 0f;
            MyToggleDrawer ToggleDraw = new MyToggleDrawer();

            EditorGUI.BeginChangeCheck();
            {
                if (emissionToggle.floatValue != 1)
                    ToggleEmission = true;
                else
                    ToggleEmission = false;

                if (emissionToggle2.floatValue != 1)
                    ToggleEmission2 = true;
                else
                    ToggleEmission2 = false;

                EditorGUI.showMixedValue = blendMode.hasMixedValue;
                EditorGUI.showMixedValue = cullMode.hasMixedValue;

                var bMode = (BlendMode)blendMode.floatValue;
                var cMode = (CullMode)cullMode.floatValue;

                EditorGUI.BeginChangeCheck();
                GUILayout.Label("-General Textures-", EditorStyles.boldLabel);
                bMode = (BlendMode)EditorGUILayout.Popup("Rendering Mode", (int)bMode, Enum.GetNames(typeof(BlendMode)));
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Rendering Mode");
                    blendMode.floatValue = (float)bMode;

                    foreach (var obj in blendMode.targets)
                    {
                        SetupMaterialWithBlendMode((Material)obj, (BlendMode)material.GetFloat("_Mode"));
                    }
                }
                cMode = (CullMode)EditorGUILayout.Popup("Cull Mode", (int)cMode, Enum.GetNames(typeof(CullMode)));
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Rendering Mode");
                    cullMode.floatValue = (float)cMode;
                }

                EditorGUI.showMixedValue = false;
                GUILayout.Space(4);
                GUILayout.Label("Minimum Light Intensity");
                materialEditor.ShaderProperty(clampMin, "", 2);
                GUILayout.Label("Maximum Light Intensity");
                materialEditor.ShaderProperty(clampMax, "", 2);
                GUILayout.Space(8);
                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "Main Color Texture"), mainTexture, color);
                EditorGUI.indentLevel += 2;          

                if ((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout)
                    materialEditor.ShaderProperty(alphaCutoff, "Alpha Cutoff", 2);
                if ((BlendMode)material.GetFloat("_Mode") == BlendMode.Transparent)
                    materialEditor.ShaderProperty(opacity, "Opacity", 1);

                materialEditor.ShaderProperty(colIntensity, "Color Intensity", 2);
                materialEditor.TexturePropertySingleLine(new GUIContent("Color Mask", "Masks Color Tinting"), colorMask);
                EditorGUI.indentLevel -= 2;
                GUILayout.Space(6);
                GUILayout.Label("-Sphere Textures-", EditorStyles.boldLabel);
                materialEditor.TexturePropertySingleLine(new GUIContent("Additive Sphere Texture"), sphereAddTexture);
                EditorGUI.indentLevel += 2;
                    materialEditor.TexturePropertySingleLine(new GUIContent("Additive Sphere Mask"), sphereAddMask);
                EditorGUI.indentLevel -= 2;
                    materialEditor.ShaderProperty(sphereAddIntensity, "Intensity", 2);
                    materialEditor.ShaderProperty(specularBleed, "Specular Bleed Through", 2);
                materialEditor.TexturePropertySingleLine(new GUIContent("Multiply Sphere Texture"), sphereMulTexture);
                    materialEditor.ShaderProperty(sphereMulIntensity, "Intensity", 2);
                GUILayout.Space(6);
                GUILayout.Label("-Toon Ramp-", EditorStyles.boldLabel);
                materialEditor.TexturePropertySingleLine(new GUIContent("Toon Texture"), toonTex);
                materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Texture"), shadowTex);
                EditorGUI.indentLevel += 2;
                materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Mask"), shadowMask);
                EditorGUI.indentLevel -= 2;
                materialEditor.VectorProperty(defaultLightDir, "Default Light Direction");
                GUILayout.Label("-Normal Maps-", EditorStyles.boldLabel);
                materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map"), normalMap);
                materialEditor.TextureScaleOffsetProperty(normalMap);
                GUILayout.Space(6);
                GUILayout.Label("-Other Effects-", EditorStyles.boldLabel);
  
                //Toggle For Alternate Emissions
                materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map", "Emission Map"), emissionMap);
                GUILayout.Space(6);
                ToggleDraw.OnGUI(new Rect(0, 0, 100, 20), emissionToggle, "Set to Default Emission Variable?", materialEditor);

                EditorGUI.BeginChangeCheck();
                if (!ToggleEmission)
                    materialEditor.ColorProperty(emissionColor, "Emission Color");
                else
                    materialEditor.ColorProperty(emissionAltColor, "Emission Alt Color");

                if (EditorGUI.EndChangeCheck())
                    materialEditor.Repaint();

                    materialEditor.ShaderProperty(emissionIntensity, "Intensity", 2);
                EditorGUI.indentLevel += 2;
                    materialEditor.TexturePropertySingleLine(new GUIContent("Emission Mask"), emissionMask);
                    materialEditor.TextureScaleOffsetProperty(emissionMask);
                    materialEditor.ShaderProperty(speedX, new GUIContent("Mask X Scroll Speed"), 0);
                    materialEditor.ShaderProperty(speedY, new GUIContent("Mask Y Scroll Speed"), 0);
                EditorGUI.indentLevel -= 2;

                materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map 2", "Emission Map 2"), emissionMap2);
                GUILayout.Space(6);
                ToggleDraw.OnGUI(new Rect(0, 0, 100, 20), emissionToggle2, "Set to Default Emission Variable?", materialEditor);

                EditorGUI.BeginChangeCheck();
                if (!ToggleEmission2)
                    materialEditor.ColorProperty(emissionColor2, "Emission 2 Color");
                else
                    materialEditor.ColorProperty(emissionAltColor2, "Emission 2 Alt Color");

                if (EditorGUI.EndChangeCheck())
                    materialEditor.Repaint();

                materialEditor.ShaderProperty(emissionIntensity2, "2nd Intensity", 2);
                EditorGUI.indentLevel += 2;
                materialEditor.TexturePropertySingleLine(new GUIContent("2nd Emission Mask"), emissionMask2);
                    materialEditor.TextureScaleOffsetProperty(emissionMask2);
                    materialEditor.ShaderProperty(speedX2, new GUIContent("2nd Mask X Scroll Speed"), 0);
                    materialEditor.ShaderProperty(speedY2, new GUIContent("2nd Mask Y Scroll Speed"), 0);
                EditorGUI.indentLevel -= 2;
                GUILayout.Space(20);
                GUILayout.Label("Version: " + shaderVariables.versionNumber + " - 2x Emission");
                EditorGUI.BeginChangeCheck();
                
                
                EditorGUILayout.Space();      
            }
            EditorGUI.EndChangeCheck();
        }
    }

    public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch ((BlendMode)material.GetFloat("_Mode"))
        {
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                break;
            case BlendMode.Fade:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                break;
            case BlendMode.Transparent:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                break;
        }
    }
}