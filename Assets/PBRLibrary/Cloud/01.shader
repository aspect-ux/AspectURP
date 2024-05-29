Shader "Unlit/01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("base color",Color) = (1,1,1,1)
        _BottomColor("Bottom Color",color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.5
        _MoveSpeed ("MoveSpeed", float) = 0.1
        _HeightOffset ("HeightOffset", Range(0, 1)) = 0.15
        _StepLayer ("StepLayer", Range(1, 64)) = 16
        
        _ViewOffset("View offset",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent-50" "RenderPipeline" = "UniversalRenderPipeline" "LightMode" = "UniversalForward"}
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Alpha;
        float _MoveSpeed;
        float _HeightOffset;
        float _StepLayer;
        float4 _BottomColor;
        float _ViewOffset;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        struct a2v
        {
            float4 positionOS : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 uv : TEXCOORD0;
        };
        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 uv2 : TEXCOORD1;
            float3 normal : TEXCOORD2;
            float3 tangent : TEXCOORD3;
            float3 bTangent : TEXCOORD4;
            float3 posWS : TEXCOORD5;
            float3 vDir : TEXCOORD6;
        };
        ENDHLSL
        pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull off
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex) + float2(frac(_Time.y * _MoveSpeed), 0);
                o.uv2 = v.uv;
                o.normal = normalize(TransformObjectToWorldNormal(v.normal));
                o.tangent = normalize(TransformObjectToWorldDir(v.tangent.xyz));
                o.bTangent = cross(o.normal,o.tangent) * v.tangent.w;
                o.posWS = TransformObjectToWorld(v.positionOS.xyz);
                o.vDir = TransformWorldToObjectDir(normalize(_WorldSpaceCameraPos.xyz - o.posWS));
                return o;
            }
            half4 FRAG(v2f i) : SV_TARGET
            {

                float3x3 TBN = float3x3(i.tangent,i.bTangent,i.normal);
                float3 vDirTS = mul(TBN,i.vDir);//计算切线空间观察向量

                vDirTS.xy *= _HeightOffset; //添加偏移值
                vDirTS.z += _ViewOffset;

                //两张uv，z通道储存深度
                float3 uv = float3(i.uv,0);//动态uv
                float3 uv2 = float3(i.uv2,0);//静态uv

                //采样一张静态图
                float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv2.xy);
                
                //使用观察向量
                float3 minOffset = vDirTS / (vDirTS.z * _StepLayer);
                
                //混合贴图
                float finiNoise = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv.xy).r * var_MainTex.r;

                //保存uv
                float3 prev_uv = uv;

                [unroll(200)]
                while(finiNoise >= uv.z)
                {
                    uv += minOffset;
                    finiNoise = SAMPLE_TEXTURE2D_LOD(_MainTex,sampler_MainTex,uv.xy,0).r * var_MainTex.r;
                }
                
                

                float d1 = finiNoise - uv.z;
                float d2 = finiNoise - prev_uv.z;
                float w = d1 / (d1 - d2 + 0.0000001);
                
                uv = lerp(uv,prev_uv,w);
                
                float4 resultColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv.xy) * var_MainTex;
                
                
                float rangeClt = var_MainTex.r * resultColor.r + _Alpha * 1.5;
                
                float Alpha = abs(smoothstep(rangeClt,_Alpha,1.0));
                
                Alpha = pow(Alpha,5);
                return float4(lerp(_BottomColor.rgb,_BaseColor.rgb,resultColor.rgb),Alpha);


            }
            ENDHLSL
        }
    }
}