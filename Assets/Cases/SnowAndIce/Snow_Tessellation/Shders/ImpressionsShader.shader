Shader "Unlit/ImpressionsShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Coordinates("Coordinates", Vector) = (0,0,0,0)
		_Color("Red Color", Color) = (1,0,0,0)
		_Size("Size", Range(1,500)) = 1
		_Strength("Strength", Range(0,1)) = 1
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

			TEXTURE2D (_MainTex);
			SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			half4 _Coordinates, _Color; 
			half _Size, _Strength;
			float _Displacement;
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
				float draw = pow(saturate(1 - distance(i.uv, _Coordinates.xy)), 500 / _Size);
				half4 drawcol = _Color * (draw * _Strength);
				return saturate(col + drawcol);

				return col;
			}
			ENDHLSL
		}
	}
}
