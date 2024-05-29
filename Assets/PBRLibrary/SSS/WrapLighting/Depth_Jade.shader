Shader "AspectURP/DepthShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			// depth declare
		    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float uv : TEXCOORD0;
			};


			v2f vert(appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);

				o.uv = v.texcoord;

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				// 采样_CameraDepthTexture,返回0-1非线性深度
				float rawDepth = SampleSceneDepth(i.uv);

				// 0-1线性深度
				return Linear01Depth(rawDepth,_ZBufferParams);
			}
			ENDHLSL
		}
	}
}
