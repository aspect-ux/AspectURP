Shader "Hidden/SnowAccumulation"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			// https://answers.unity.com/questions/399751/randomity-in-cg-shaders-beginner.html 
			// pseudo random numbers
			float rand(float3 co)
			{
				return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
			}

			TEXTURE2D (_MainTex);
			SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			half _SnowflakeCount, _SnowflakeOpacity;
			CBUFFER_END
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				// sample the texture
				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
				float rValue = ceil(rand(float3(i.uv.x, i.uv.y, 0) * _Time.x) - (1 - _SnowflakeCount));

				// clamp 0 - 1
				return saturate(col - (rValue * _SnowflakeOpacity));
			}
			ENDHLSL
		}
	}
}
