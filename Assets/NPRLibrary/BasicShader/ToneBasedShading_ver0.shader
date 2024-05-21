Shader "AspectURP/NPR/Tone Based Shading(Simple ver)"
{
	Properties
	{
		_CoolColor("Cool Color",Color) = (1,1,1,1)
		_WarmColor("Warm Color",Color) = (1,1,1,1)
		_Extsn("Extsn Value", Range(0,1)) = 1
		_OutColor("Outline Color", Color) = (0,0,0,1)
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
 
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
 
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
 
			struct appdata
			{
				float4 normal : NORMAL;
				float4 vertex : POSITION;
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldP2S : TEXCOORD1;
			};
 
			float4 _CoolColor;
			float4 _WarmColor;
			float _CoolAlpha;
			float _WarmBeta;
 
			v2f vert(appdata v)
			{
				v2f o;
				o.worldNormal = UnityObjectToWorldNormal(v.normal.xyz);
				o.worldP2S = normalize(WorldSpaceLightDir(v.vertex));
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				float LN = dot(i.worldNormal ,-i.worldP2S);
				float4 I = (0.5 + LN * 0.5)*_CoolColor + (0.5 - LN * 0.5)*_WarmColor;
				return I;
			}
			ENDCG
		}
 
		Pass
		{
			Cull front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
 
			#include "UnityCG.cginc"
 
			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
			};
 
			float _Extsn;
			float4 _OutColor;
 
			v2f vert(appdata v)
			{
				v2f o;
				v.vertex += v.normal * _Extsn;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = _OutColor;
				return col;
			}
			ENDCG
		}
	}
}