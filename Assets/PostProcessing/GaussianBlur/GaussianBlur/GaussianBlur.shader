Shader "AspectURP/PostProcessing/GaussianBlur"
{
    Properties
    {
         _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
           "RenderPipeline" = "UniversalRenderPipeline"
        }
        LOD 100

        HLSLINCLUDE
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

        CBUFFER_START(UnityPerMaterial)
        uniform float _BlurSize;

        float4 _MainTex_TexelSize;
        //sampler2D _MainTex;
        CBUFFER_END

        TEXTURE2D(_MainTex);     
        SAMPLER(sampler_MainTex);


        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float2 uv[5] : TEXCOORD0;
            float4 positionCS : SV_POSITION;
        };
        

        Varyings VertBlurVertical(Attributes v)
        {
            Varyings o;
            o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
            float2 uv = v.uv;

            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

            return o;
        }

        Varyings VertBlurHorizontal(Attributes v)
        {
            Varyings o = (Varyings)0;
            o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
            float2 uv = v.uv;

            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            return o;
        }

        float4 fragBlur(Varyings i) : SV_Target
        {
            float weight[3] = {0.4026, 0.2442, 0.0545};

            //中心像素值
            float3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[0]).rgb * weight[0];
            //float3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

            for (int it = 1; it < 3; it++)
            {
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it * 2]).rgb * weight[it];
                //sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                //sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
            }

            return float4(sum, 1.0);
        }
        ENDHLSL


        ZTest Always
        Cull Off
        ZWrite Off

        Pass
        {
            //blend one one
            Name "GaussianPass0"
            HLSLPROGRAM            
            #pragma vertex VertBlurVertical
            #pragma fragment fragBlur
            ENDHLSL
        }

        Pass
        {
            //blend one one
            
            Name "GaussianPass1"
            HLSLPROGRAM            
            #pragma vertex VertBlurHorizontal
            #pragma fragment fragBlur
           
            ENDHLSL
        }
    }
    Fallback Off
}