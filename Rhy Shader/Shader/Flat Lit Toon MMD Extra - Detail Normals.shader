Shader "Rhy Custom Shaders/Flat Lit Toon + MMD/Detail Normals"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_ColorMask("ColorMask", 2D) = "black" {}
		_ColorIntensity("Intensity", Range(0, 5)) = 1.0
		_SphereAddTex("Sphere Add Texture", 2D) = "black" {}
		_SphereAddIntensity("Add Sphere Texture Intensity", Range(0, 500)) = 1.0
		_SphereMulTex("Sphere Multiply Texture", 2D) = "white" {}
		_SphereMulIntensity("Multiply Sphere Texture Intensity", Range(0, 500)) = 1.0
		_DefaultLightDir("Default Light Direction", Vector) = (1,1,1,2)
		_ToonTex("Toon Texture", 2D) = "white" {}
		_ShadowTex("Shadow Texture", 2D) = "white" {}
		_ShadowMask("Shadow Mask", 2D) = "black" {}
		_outline_width("outline_width", Float) = 0.2
		_outline_color("outline_color", Color) = (0.5,0.5,0.5,1)
		_outline_tint("outline_tint", Range(0, 1)) = 0.5
		_EmissionMap("Emission Map", 2D) = "white" {}
		_EmissionMask("Emission Mask", 2D) = "white" {}
		_EmissionIntensity("Emission Intensity", Range(0, 20)) = 0.0
		_SpeedX("Emission X speed", Float) = 1.0
		_SpeedY("Emission Y speed", Float) = 1.0
		_SphereMap("Sphere Mask", 2D) = "white" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_BumpMap("Normal Map", 2D) = "bump" {}
		_DetailMap("Detail Normal Map", 2D) = "bump" {}
		_DetailMapMask("Detail Normal Map Mask", 2D) = "white" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		_SpecularToggle("Specular Toggle", Float) = 1
		_Opacity("Opacity", Range(1,0)) = 0
		_SpecularBleed("Specular Bleedthrough", Range(0,1)) = 0.1
		_ClampMin("Minimum Light Intensity", Range(0,3)) = 0
		_ClampMax("Maximum Light Intensity", Range(1,5)) = 5
		
		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _Cull ("__cull", Float) = 0.0
		[HideInInspector] _OutlineMode("__outline_mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}
	
	
	
	SubShader
	{
		Tags
		{
			"Queue"="Geometry+1"
			"RenderType" = "Opaque"
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase"}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite On
			ZTest LEqual
			LOD 200
			Cull Off
						
			CGPROGRAM
			#include "FlatLitToonCoreMMD Extra.cginc"
			#include "RhyShaderHelperFunction.cginc"
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma only_renderers d3d11 glcore gles
			#pragma target 4.0
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			
			float2 emissionUV;
			float2 emissionMovement;
			LightContainer Lighting;
			LightContainer Lighting2;
			MatcapContainer Matcap;
			MatcapContainer Matcap2;
			
			uniform sampler2D _DetailMapMask;
			float4 _DetailMapMask_ST;
			
			float4 frag(VertexOutput i, float facing : VFACE) : COLOR 
			{
				float faceSign = ( facing >= 0 ? 1 : -1 );
			
				emissionUV = i.uv0;
				emissionUV.x += _Time.x * _SpeedX;
				emissionUV.y += _Time.x * _SpeedY;
				float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
				
				i.normalDir = normalize(i.normalDir);
				float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);

				float3 normalDirection = CalculateNormal(TRANSFORM_TEX(i.uv0, _BumpMap), _BumpMap, tangentTransform);
				//float3 _DetailMap_var = UnpackNormal(tex2D(_DetailMap, TRANSFORM_TEX(i.uv0, _DetailMap)));
				float3 _DetailMap_var = CalculateNormal(TRANSFORM_TEX(i.uv0, _DetailMap), _DetailMap, tangentTransform);
				float3 _DetailMapMask_var = tex2D(_DetailMapMask ,TRANSFORM_TEX(i.uv0, _DetailMapMask));
				//float3 maskedNormalDirection = CalculateNormal(TRANSFORM_TEX(i.uv0, _DetailMap), _DetailMap, tangentTransform);
				float3 maskedNormalDirection = normalize(mul(float3(normalDirection.xy*_DetailMap_var.z + _DetailMap_var.xy*normalDirection.z, normalDirection.z*_DetailMap_var.z), 1));
				//float3 maskedNormalDirection = _DetailMap_var;
				maskedNormalDirection *= _DetailMapMask_var;

				float4 baseColor = CalculateColor(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex), _Color);			
				
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
				attenuation = FadeShadows(attenuation, i.posWorld.xyz);

				Lighting = CalculateLight(_WorldSpaceLightPos0, _LightColor0, normalDirection, attenuation, _ClampMin, _ClampMax);
				Lighting2 = CalculateLight(_WorldSpaceLightPos0, _LightColor0, maskedNormalDirection, attenuation, _ClampMin, _ClampMax);

				float4 _EmissionMap_var = tex2D(_EmissionMap,TRANSFORM_TEX(i.uv0, _EmissionMap));
				float4 emissionMask_var = tex2D(_EmissionMask,TRANSFORM_TEX(emissionUV, _EmissionMask));
				float3 emissive = (_EmissionMap_var.rgb*_EmissionColor.rgb);
				emissive.rgb *= emissionMask_var.rgb;
				emissive.rgb *= _EmissionIntensity;

				float rampValue = smoothstep(0, Lighting.bw_lightDif, 0 - dot(ShadeSH9(float4(0, 0, 0, 1)), grayscale_vector));
				float tempValue = (0.5 * dot(normalDirection, Lighting.lightDir.xyz) + 0.5);
				float detailTempValue = (0.5 * dot((_DetailMap_var * _DetailMapMask_var), Lighting2.lightDir.xyz) + 0.5);
				
				float3 toonTexColorDetail = tex2D( _ToonTex, detailTempValue);
				float3 toonTexColor = tex2D(_ToonTex, tempValue);
				float3 shadowTexColor = tex2D(_ShadowTex, rampValue);
				float4 shadowMask_var = tex2D(_ShadowMask,TRANSFORM_TEX(i.uv0, _ShadowMask));

				toonTexColor += toonTexColorDetail;
				
				Lighting.indirectLit += ((shadowTexColor*2) * Lighting.lightCol) + shadowMask_var.rgb;
				Lighting2.indirectLit += ((shadowTexColor*2) * Lighting2.lightCol) + shadowMask_var.rgb;
				Matcap = CalculateSphere(normalDirection, i, _SphereAddTex, _SphereMulTex, _SphereMap, TRANSFORM_TEX(i.uv0, _SphereMap), _SpecularBleed, faceSign, attenuation);
				Matcap2 = CalculateSphere(maskedNormalDirection, i, _SphereAddTex, _SphereMulTex, _SphereMap, TRANSFORM_TEX(i.uv0, _SphereMap), _SpecularBleed, faceSign, attenuation);

				Matcap.Add.rgb *= (Matcap.Mask * _SphereAddIntensity) * Matcap.Shadow;
				Matcap.Mul.rgb *= _SphereMulIntensity;
				Matcap2.Add.rgb *= (Matcap2.Mask * _SphereAddIntensity) * Matcap2.Shadow;
				Matcap2.Mul.rgb *= _SphereMulIntensity;

				Matcap.Add = lerp(Matcap.Add, Matcap2.Add, attenuation);
				Matcap.Mul = lerp(Matcap.Mul, Matcap2.Mul, attenuation);

				float finalAlpha = baseColor.a;

				if(_Mode == 1)
					clip (finalAlpha - _Cutoff);
				if(_Mode == 3)
					finalAlpha -= _Opacity;

				float3 finalColor = emissive + (Matcap.Add + ((_ColorIntensity / 2) * (baseColor.rgb * toonTexColor)) * Matcap.Mul) * lerp(lerp(Lighting.indirectLit, Lighting2.indirectLit, 0.5), lerp(Lighting.directLit, Lighting2.directLit, 0.5), attenuation);
				float4 white = float4(1,1,1,1);

				if(all(shadowMask_var == white))
					finalColor = emissive + (Matcap.Add + ((_ColorIntensity / 2) * (baseColor.rgb * toonTexColor)) * Matcap.Mul) * lerp(_LightColor0, lerp(Lighting.directLit, Lighting2.directLit, 0.5), attenuation);

				fixed4 finalRGBA = fixed4(finalColor, finalAlpha);						
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}		
		
		Pass
		{
			Name "FORWARD_DELTA"
			Tags 
			{ 
				"LightMode" = "ForwardAdd"
			}
			Blend [_SrcBlend] One
			ZWrite On
			ZTest LEqual
			LOD 200
			Cull Off
						
			Fog { Color (0,0,0,0) } // in additive pass fog should be black
			

			CGPROGRAM
			#include "FlatLitToonCoreMMD Extra.cginc"
			#include "RhyShaderHelperFunction.cginc"
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma only_renderers d3d11 glcore gles
			#pragma target 4.0
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			LightContainer Lighting;
			LightContainer Lighting2;
			MatcapContainer Matcap;
			MatcapContainer Matcap2;

			uniform sampler2D _DetailMapMask;
			float4 _DetailMapMask_ST;


			float4 frag(VertexOutput i, float facing : VFACE) : COLOR
			{
				float faceSign = ( facing >= 0 ? 1 : -1 );
				float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
				
				i.normalDir = normalize(i.normalDir);
				float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);

				float3 normalDirection = CalculateNormal(TRANSFORM_TEX(i.uv0, _BumpMap), _BumpMap, tangentTransform);
				//float3 _DetailMap_var = UnpackNormal(tex2D(_DetailMap, TRANSFORM_TEX(i.uv0, _DetailMap)));
				float3 _DetailMap_var = CalculateNormal(TRANSFORM_TEX(i.uv0, _DetailMap), _DetailMap, tangentTransform);
				float3 _DetailMapMask_var = tex2D(_DetailMapMask ,TRANSFORM_TEX(i.uv0, _DetailMapMask));
				//float3 maskedNormalDirection = CalculateNormal(TRANSFORM_TEX(i.uv0, _DetailMap), _DetailMap, tangentTransform);
				float3 maskedNormalDirection = normalize(mul(float3(normalDirection.xy*_DetailMap_var.z + _DetailMap_var.xy*normalDirection.z, normalDirection.z*_DetailMap_var.z), 1));
				//float3 maskedNormalDirection = _DetailMap_var;
				maskedNormalDirection *= _DetailMapMask_var;

				float4 baseColor = CalculateColor(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex), _Color);			
				
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
				attenuation = FadeShadows(attenuation, i.posWorld.xyz);
				float light_Env = float(any(_WorldSpaceLightPos0.xyz));

				Lighting = CalculateLight(_WorldSpaceLightPos0, _LightColor0, normalDirection, attenuation, _ClampMin, _ClampMax);
				Lighting2 = CalculateLight(_WorldSpaceLightPos0, _LightColor0, maskedNormalDirection, attenuation, _ClampMin, _ClampMax);
				
				float rampValue = smoothstep(0, Lighting.bw_lightDif, 0 - dot(ShadeSH9(float4(0, 0, 0, 1)), grayscale_vector));
				float tempValue = (0.5 * dot(normalDirection, Lighting.lightDir.xyz) + 0.5);
				float detailTempValue = (0.5 * dot(maskedNormalDirection, Lighting2.lightDir.xyz) + 0.5);
				
				float3 toonTexColorDetail = tex2D( _ToonTex, detailTempValue);
				float3 toonTexColor = tex2D(_ToonTex, tempValue);
				float3 shadowTexColor = tex2D(_ShadowTex, rampValue);
				float4 shadowMask_var = tex2D(_ShadowMask,TRANSFORM_TEX(i.uv0, _ShadowMask));
				
				toonTexColor += toonTexColorDetail;

				Lighting.indirectLit += (shadowTexColor * Lighting.lightCol) + shadowMask_var.rgb;
				Lighting2.indirectLit += (shadowTexColor * Lighting2.lightCol) + shadowMask_var.rgb;
				Matcap = CalculateSphere(normalDirection, i, _SphereAddTex, _SphereMulTex, _SphereMap, TRANSFORM_TEX(i.uv0, _SphereMap), _SpecularBleed, faceSign, attenuation);
				Matcap2 = CalculateSphere(maskedNormalDirection, i, _SphereAddTex, _SphereMulTex, _SphereMap, TRANSFORM_TEX(i.uv0, _SphereMap), _SpecularBleed, faceSign, attenuation);

				Matcap.Add.rgb *= (Matcap.Mask * _SphereAddIntensity) * Matcap.Shadow;
				Matcap.Mul.rgb *= _SphereMulIntensity;
				Matcap2.Add.rgb *= (Matcap.Mask * _SphereAddIntensity) * Matcap.Shadow;
				Matcap2.Mul.rgb *= _SphereMulIntensity;

				Matcap.Add = lerp(Matcap.Add, Matcap2.Add, 0.5);
				Matcap.Mul = lerp(Matcap.Mul, Matcap2.Mul, 0.5);

				float finalAlpha = baseColor.a;

				if(_Mode == 1)
					clip (finalAlpha - _Cutoff);
				if(_Mode == 3)
					finalAlpha -= _Opacity;

				float3 finalColor = (Matcap.Add + ((_ColorIntensity / 2) * (baseColor.rgb * toonTexColor)) * Matcap.Mul) * lerp(0, lerp(Lighting.directLit, Lighting2.directLit, 0.5), attenuation);

				if(light_Env != 1)
					finalColor = (Matcap.Add + ((_ColorIntensity / 2) * (baseColor.rgb * toonTexColor)) * Matcap.Mul) * lerp(lerp(Lighting.lightCol,  Lighting2.lightCol, 0.5), lerp(Lighting.directLit, Lighting2.directLit, 0.5), attenuation);

				fixed4 finalRGBA = fixed4(finalColor, finalAlpha);						
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}
		
		Pass
		{
			Name "SHADOW_CASTER"
			Tags{ "LightMode" = "ShadowCaster" }
			Blend [_SrcBlend] [_DstBlend]

			ZWrite On
			ZTest LEqual
			Cull Off

			CGPROGRAM
			#include "FlatLitToonShadows.cginc"
			
			#pragma multi_compile_shadowcaster
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma only_renderers d3d11 glcore gles
			#pragma target 4.0

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster
			ENDCG
		}
	}
	Fallback "Toon/Lit (Double)"
	CustomEditor "RhyFlatLitMMDEditorDetail"
}