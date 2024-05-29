///  Reference: 	Gooch A, Gooch B, Shirley P, et al. A non-photorealistic lighting model for automatic technical illustration[C]
///						Proceedings of the 25th annual conference on Computer graphics and interactive techniques. ACM, 1998: 447-452.
/// 
Shader "NPR/Cartoon/Tone Based Shading" {
	Properties {
		_Color ("Diffuse Color", Color) = (1, 1, 1, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Outline ("Outline", Range(0,1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(1.0, 500)) = 20
		_Blue ("Blue", Range(0, 1)) = 0.5
		_Alpha ("Alpha", Range(0, 1)) = 0.5
		_Yellow ("Yellow", Range(0, 1)) = 0.5
		_Beta ("Beta", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags 
        { 
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque" 
        }
        
		LOD 200
		
		//UsePass "NPR/Cartoon/Antialiased Cel Shading/OUTLINE"
        UsePass "AspectURP/NPR/Toon/Outline"
		
		Pass {
			Tags { "LightMode"="UniversalForward" }
			
			HLSLPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
            // 存储在GPU中的缓冲，适用于渲染过程尽量少的更改的属性
            CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _MainTex_ST;
			float4 _Specular;
			float _Gloss;
			float _Blue;
			float _Alpha;
			float _Yellow;
			float _Beta;
            CBUFFER_END

            sampler2D _MainTex;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 
			
			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};
			
			v2f vert (a2v v) {
				v2f o;
								
				o.pos = TransformObjectToHClip( v.vertex); 
				o.worldNormal  = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				
				return o;
			}
			
			float4 frag(v2f i) : COLOR 
            { 

                Light mainLight = GetMainLight();
                float atten = mainLight.distanceAttenuation;

				float3 worldNormal = normalize(i.worldNormal);
				float3 worldLightDir = normalize(mainLight.direction);
				float3 worldViewDir = _WorldSpaceCameraPos.xyz - i.worldPos;
				float3 worldHalfDir = normalize(worldViewDir + worldLightDir);
				
				float4 c = tex2D (_MainTex, i.uv);
				
				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				//UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				float diff =  dot (worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten;
				
				float3 k_d = c.rgb * _Color.rgb;
				
				float3 k_blue = float3(0, 0, _Blue);
				float3 k_yellow = float3(_Yellow, _Yellow, 0);
				float3 k_cool = k_blue + _Alpha * k_d;
				float3 k_warm = k_yellow + _Beta * k_d;
				
				float3 diffuse = _MainLightColor.rgb * (diff * k_warm + (1 - diff) * k_cool);
						
				float3 specular = _MainLightColor.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, worldHalfDir)), _Gloss);
				
				return float4(ambient + diffuse + specular, 1.0);	
			}
			
			ENDHLSL
		}
		
		Pass {
			//Tags { "LightMode"="ForwardAdd" }
			
			Blend One One
			
			HLSLPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _MainTex_ST;
			float4 _Specular;
			float _Gloss;
			float _Blue;
			float _Alpha;
			float _Yellow;
			float _Beta;
            CBUFFER_END

            sampler2D _MainTex;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 
			
			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = TransformObjectToHClip( v.vertex); 
				o.worldNormal  = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				
				return o;
			}
			
			float4 frag(v2f i) : COLOR { 
				float3 worldNormal = normalize(i.worldNormal);
				float3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
				float3 worldViewDir = UnityWorldSpaceViewDir(i.worldPos);
				float3 worldHalfDir = normalize(worldViewDir + worldLightDir);
				
				float4 c = tex2D (_MainTex, i.uv);
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				float diff =  dot (worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten;
				
				float3 k_d = c.rgb * _Color.rgb;
				
				float3 k_blue = float3(0, 0, _Blue);
				float3 k_yellow = float3(_Yellow, _Yellow, 0);
				float3 k_cool = k_blue + _Alpha * k_d;
				float3 k_warm = k_yellow + _Beta * k_d;
				
				float3 diffuse = _MainLightColor.rgb * (diff * k_warm + (1 - diff) * k_cool);
						
				float3 specular = _MainLightColor.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, worldHalfDir)), _Gloss);
				
				return float4(diffuse + specular, 1.0);
			} 
			
			ENDHLSL
		}
	}
}
