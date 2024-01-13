Shader "AspectURP/PostProcessing/Bloom" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		//_BloomTex ("Bloom (RGB)", 2D) = "black" {}
		//_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		//_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
		
		Tags
        {
           "RenderPipeline" = "UniversalRenderPipeline" "RenderType"="Opaque"
        }
		
        LOD 100
		HLSLINCLUDE
		
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

		CBUFFER_START(UnityPerMaterial)
		half4 _MainTex_TexelSize;

		uniform float _LuminanceThreshold;
		uniform float _BlurSize;
		CBUFFER_END

		TEXTURE2D(_MainTex);       
        SAMPLER(sampler_MainTex); 

		TEXTURE2D(_BloomTex);       
        SAMPLER(sampler_BloomTex);
		
		struct app_img
		{
			float3 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};
		
		struct v2f {
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
		};	
		
		v2f vertExtractBright(app_img v) {
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex);
			o.uv = v.uv;
			return o;
		}
		
		float luminance(float4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}
		
		float4 fragExtractBright(v2f i) : SV_Target {
			float4 c = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
			float val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
			
			return c * val;
		}

		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;
		};

		v2fBloom vertBloom(app_img v) {
			v2fBloom o;
			
			o.pos = TransformObjectToHClip(v.vertex);
			o.uv.xy = v.uv;		
			o.uv.zw = v.uv;
			
			#if UNITY_UV_STAR_AT_TOP			
			if (_MainTex_TexelSize.y TS< 0.0)
				o.uv.w = 1.0 - o.uv.w;
			#endif
				        	
			return o; 
		}
		
		float4 fragBloom(v2fBloom i) : SV_Target {
			return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy)
			+ SAMPLE_TEXTURE2D(_BloomTex,sampler_BloomTex,i.uv.zw);
		} 
		
		ENDHLSL
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {  
			HLSLPROGRAM  
			#pragma vertex vertExtractBright  
			#pragma fragment fragExtractBright  
			
			ENDHLSL  
		}
		
		Pass {  
			HLSLPROGRAM  
			#pragma vertex vertBloom  
			#pragma fragment fragBloom  
			
			ENDHLSL  
		}
		
		//UsePass "AspectURP/PostProcessing/GaussianPass0"
		
		//UsePass "AspectURP/PostProcessing/GaussianPass1"
	}
	FallBack Off
}
