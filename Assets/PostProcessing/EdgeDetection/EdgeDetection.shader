Shader "AspectURP/PostProcessing/Edge Detection" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Tags
		{
		   "RenderPipeline" = "UniversalRenderPipeline"
		}
		LOD 100
    
        HLSLINCLUDE
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

        CBUFFER_START(UnityPerMaterial)
        uniform float _BlurSize;

        float _EdgeOnly;
		float4 _EdgeColor;
		float4 _BackgroundColor;

        float4 _MainTex_TexelSize;
        CBUFFER_END

        TEXTURE2D(_MainTex);     
        SAMPLER(sampler_MainTex);

        // named after cg
        struct app_img
		{
			float3 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};
        
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[9] : TEXCOORD0;
		};
		  
		v2f vert(app_img v) {
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex);
			
			half2 uv = v.uv;
			
			o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
			o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
			o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
			o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
			o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
					 
			return o;
		}
		
		float luminance(float4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}
		
		half Sobel(v2f i) {
			const half Gx[9] = {-1,  0,  1,
									-2,  0,  2,
									-1,  0,  1};
			const half Gy[9] = {-1, -2, -1,
									0,  0,  0,
									1,  2,  1};		
			
			half texColor;
			half edgeX = 0;
			half edgeY = 0;
			for (int it = 0; it < 9; it++) {
				texColor = luminance(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv[it]));
				edgeX += texColor * Gx[it];
				edgeY += texColor * Gy[it];
			}
			
			half edge = 1 - abs(edgeX) - abs(edgeY);
			
			return edge;
		}
		
		float4 fragSobel(v2f i) : SV_Target {
			half edge = Sobel(i);
			
			float4 withEdgeColor = lerp(_EdgeColor, SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv[4]), edge);
			float4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
			return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
 		}
        ENDHLSL
		
		Pass {  
			ZTest Always Cull Off ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment fragSobel
			ENDHLSL
		} 
	}
	FallBack Off
}
