Shader "AspectURPR/Toon"
{
    Properties
    {
        [Header(ShaderEnum)]
        [KeywordEnum(Base,Others)] _ShaderEnum ("Shader Enum",int) = 1
        //[Toggle(IN_NIGHT)]_InNight ("is Night?", int) = 0
        [Enum(OFF,0,FRONT,1,BACK,2)] _Cull ("Cull Mode",int) = 1

        [Header(BaseMap)]
        _MainTex ("Main Tex",2D) = "white"{}
        _MainColor ("Main Color",Color) = (1,1,1,1)

        [Header(Diffuse)]
        _RampTex ("Ramp Tex",2D) = "white"{}
        /*_RampMapYRange("Rame Y Range",Range(-1,1)) = 1
        _RampIntensity ("Ramp Intensity",Range(0,1)) = 0.3
        _FaceDiffuseIntensity ("Face Diffuse Intensity",Range(0,1)) = 0.4
        [ToggleOff]_isCloth ("isCloth",int) = 0*/
        
        /*
         //face, the same with paramTex
        _LightMap ("Light Map(for specular :gloss or metal)",2D) = "grey"{}*/

        
        [Header(Specular)]
        [Header(BasicSpecular)]
        //_SpecularGloss ("Specular Gloss",Range(8.0,256)) = 20
        _SpecularIntensity ("Specular Intensity",Range(0,0.1)) = 0.001

        [Header(Main Lighting Settings)]
        [ToggleOff] _ReceiveShadow ("Receive Shadow", int) = 1
        _LightingDirectionFix ("Lighting Direction Fix", Range(0, 1)) = 0
        _LightingColor ("Lighting Color", Color) = (1, 1, 1)
        _ShadingColor ("Shading Color", Color) = (0.5, 0.5, 0.5)
        _DiffuseShadowBias ("Bias", Range(-1, 1)) = 0
        _DiffuseShadowSmoothstep ("Smoothstep", Range(0, 1)) = 0
    
        /*
        [Header(RimLight)]
        _RimIntensity ("Rim Light Intensity",Range(0,10)) = 8
        _RimRadius ("Rim Light Radius",Range(0,20)) = 0
        
        [Header(Emission)]
        _EmissionIntensity("Emission Intensity",Range(0,255)) = 1
        [HDR]_EmissionColor("Emission Color",Color) = (1,1,1,1)*/


        [Header(Outline(Sihouetting))]
        _OutlineColor("OutLine Color",Color) = (0,0,0,1)
        _OutlineWidth("Outline Width",Range(0,1)) = 0.1

        /*
        [Header(ShadowCast)]
        [Space(5)]
        _ShadowArea("Shadow Area",Range(0,10)) = 0 
        _DarkShadowArea ("Dark Shadow Area",RANGE(0,10)) = 0
        _FixDarkShadow ("Fix Dark Shadow",RANGE(0,10)) = 0
        _ShadowColor ("Shadow Color",Color) = (1,1,1,1)

        _LightThreshold ("Light Threshold",Range(0,10)) = 0.5*/

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        //#include "mylib.hlsl"

        #pragma vertex vert
        #pragma fragment frag

        #pragma shader_feature _SHADERENUM_BASE _SHADERENUM_FACE _SHADERENUM_HAIR

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS


        //声明
        CBUFFER_START(UnityPerMaterial) //缓冲区

        //Shadow
        int _ReceiveShadow;
        float _LightingDirectionFix;
        float3 _LightingColor;
        float3 _ShadingColor;
        float _DiffuseShadowSmoothstep;
        float _DiffuseShadowBias;

        //BaseMap
        float4 _MainTex_ST;  //要注意纹理不能放在缓冲区
        float4 _MainColor;
        float4 _RampTex_ST;
       
        //RimLight
        uniform float _RimIntensity;
        uniform float _RimRadius;

        //diffuse
        uniform float _FaceDiffuseIntensity;
        uniform float _RampMapYRange;

        //Specualr
        uniform float4 _MetalColor;
        uniform float _SpecularGloss;
        uniform float _SpecularIntensity;
       
        uniform float _MetalIntensity;
        uniform float _MetalMapV;

        //Emission
        //uniform float _EmissionIntensity;
        //uniform float4 _EmissionColor;

        //Sihouetting
        uniform float4 _OutlineColor;
        uniform float _OutlineWidth;


        CBUFFER_END

        //Texture
        TEXTURE2D(_MainTex);        //要注意在CG中只声明了采样器 sampler2D _MainTex,
        SAMPLER(sampler_MainTex); //而在HLSL中除了采样器还有纹理对象，分成了两部分
        TEXTURE2D(_RampTex);     
        SAMPLER(sampler_RampTex);
        
        //depth
        TEXTURE2D_X_FLOAT(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);
            
        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;
            float4 tangent : TANGENT;
            float4 color: COLOR;
        };
        struct VertexOutput //输出结构
        {
            float4 pos : POSITION;
            float2 uv : TEXCOORD0;
            float3 nDirWS : TEXCOORD1;
            float3 nDirVS : TEXCOORD2;
            float3 vDirWS : TEXCOORD3;
            float3 worldPos : TEXCOORD4;
            float3 lightDirWS : TEXCOORD5;
            float4 vertexColor: COLOR;
            float3 worldTangent : TANGENT;
            float4 shadowCoord : TEXCOORD6;
        };

        float3 float3Lerp(float3 a, float3 b, float c)//用于0-1插值两种颜色的函数
        {
            return a * (1 - c) + b * c;
        }

        float floatLerp(float a, float b, float c)//用于0-1插值两个数的函数
        {
            return a * (1 - c) + b * c;
        }
        ENDHLSL

        Pass
        {
            Name "Main"
            Tags
            {
                "LightMode"="UniversalForward"
                "RenderType"="Opaque"
            }
            Cull [_Cull]
            HLSLPROGRAM

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o = (VertexOutput)0; // 新建输出结构
                ZERO_INITIALIZE(VertexOutput, o); //初始化顶点着色器
                //o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                o.pos = TransformObjectToHClip(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.uv = v.uv;
                //o.uv = float2(o.uv.x, 1 - o.uv.y);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.worldTangent = TransformObjectToWorldDir(v.tangent);
                //o.nDirVS = TransformWorldToView(o.nDirWS);
                o.vertexColor = v.color;

                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                //====================================================================
                //==================PREPAREATION FOR COMPUTING==========================
                Light mainLight = GetMainLight();
                //Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.worldPos));

                float3 nDirWS = normalize(i.nDirWS);
                //float3 lightColor = mainLight.color;
                float3 lightDirWS = normalize(mainLight.direction);
                float3 vDirWS = normalize(GetCameraPositionWS().xyz - i.worldPos);
                float3 halfDirWS = normalize(lightDirWS + vDirWS);
                float3 tangentDir = normalize(i.worldTangent);

                //prepare dot product
                //if less than 0,then it will be wrong in light dir
                float ndotL = max(0,dot(nDirWS,lightDirWS)); 
                float ndotH = max(0,dot(nDirWS,halfDirWS));
                ndotH = dot(nDirWS,halfDirWS);
                float ndotV = saturate(dot(nDirWS,vDirWS));
                float hdotT = max(dot(halfDirWS,tangentDir),0); //切线点乘半角
                float halfLambert = dot(nDirWS,lightDirWS) * 0.5 + 0.5;

                //-------主光源光照计算-------
                float3 fixedLightDirection = normalize(float3Lerp(lightDirWS, float3(lightDirWS.x, 0, lightDirWS.z), _LightingDirectionFix));
                float NdotFL = dot(nDirWS, fixedLightDirection);
                float linear01DiffuseFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotFL - _DiffuseShadowBias);
                i.shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                float linear01ShadowFactor = floatLerp(1, MainLightRealtimeShadow(i.shadowCoord), _ReceiveShadow);
                float linear01LightingFactor = linear01DiffuseFactor * linear01ShadowFactor;
                float linear01ShadingFactor = 1 - linear01LightingFactor;
                float3 finalDiffuseColor = _LightingColor * linear01LightingFactor + _ShadingColor * linear01ShadingFactor;
                //-------结束主光源光照计算-------
                
                //-------次级光源光照计算-------
                int pixelLightCount = GetAdditionalLightsCount();
                float3 finalAdditionalLightingColor = float3(0, 0, 0);
                for (int lightIndex = 0; lightIndex < pixelLightCount; lightIndex ++)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, i.worldPos);
                    float NdotAL = dot(nDirWS, normalize(additionalLight.direction));
                    float linear01AdditionalLightingFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotAL - _DiffuseShadowBias) * additionalLight.distanceAttenuation;
                    finalAdditionalLightingColor += additionalLight.color.rgb * linear01AdditionalLightingFactor;
                }
                //-------结束次级光源光照计算-------

                //sample
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float4 rampColor = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(halfLambert,halfLambert));
                float3 albedo = baseColor * _MainLightColor.rgb;

                //float3 diffuse = halfLambert > _ShadowRange ? _MainColor : _ShadowColor;
                float3 diffuse = _MainLightColor.rgb * albedo * rampColor.rgb * _MainColor.rgb;

				float w = fwidth(ndotH) * 2.0;
				float3 specular = lerp(0, 1, smoothstep(-w, w, ndotH + _SpecularIntensity - 1)) * step(0.0001, _SpecularIntensity);

                specular = float3(0,0,0);
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                return float4(baseColor.rgb * float3(finalDiffuseColor + specular + ambient),1.0);
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "Outline"
            Cull Front
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
                "RenderType"="Opaque"
            }
   

            HLSLPROGRAM
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                // 普通法线方向外扩 View Space 也称作三角面扩张法 过程式几何描边
                float4 pos = mul(UNITY_MATRIX_MV , v.vertex);
                //注意法线空间变换的特殊性
                float3 normal= mul((float3x3)UNITY_MATRIX_IT_MV, v.normal); 
                normal.z = -0.5 ; 
                pos = pos + float4(normalize(normal) , 0) * _OutlineWidth; 
                o.pos = mul(UNITY_MATRIX_P , pos);
             
                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                return float4(_OutlineColor.rgb,1);
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GlossnessINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }

        
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        
    }

}
