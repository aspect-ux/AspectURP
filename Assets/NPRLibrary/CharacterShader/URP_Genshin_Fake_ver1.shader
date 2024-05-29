// A Character Shader replicate of Honkai Star trail and Genshin Impact
Shader "AspectURP/FAKE_yuanshen"
{
    Properties
    {
        [Header(ShaderEnum)]
        [Space(5)]
        [KeywordEnum(Base,Face,Hair)] _ShaderEnum ("Shader Enum",int) = 1
        [Toggle(IN_NIGHT)]_InNight ("is Night?", int) = 0
        [KeywordEnum(Cool,Warm)] _Climate ("Climate",int) = 0
        [Enum(OFF,0,FRONT,1,BACK,2)] _Cull ("Cull Mode",int) = 1

        [Header(BaseMap)]
        [Space(5)]
        _MainTex ("Main Tex",2D) = "white"{}
        [HDR]_MainColor ("Main Color",Color) = (1,1,1,1)

        [Header(Diffuse)]
        [Space(5)]
        _RampTex ("Ramp Tex",2D) = "white"{}
        _RampTex1 ("Ramp Tex",2D) = "white"{}
        _AO ("AO",RANGE(0,1)) = 0.2   
        //[Toggle(ISNIGHT)] _IsNight ("IsNight",int) = 0
        _RampMapYRange("Rame Y Range",Range(-1,1)) = 1
        _RampIntensity ("Ramp Intensity",Range(0,1)) = 0.3
        _FaceDiffuseIntensity ("Face Diffuse Intensity",Range(0,1)) = 0.4
        [ToggleOff]_isCloth ("isCloth",int) = 0

         //face, the same with paramTex
        [Space(5)]
        _LightMap ("Light Map(for specular :gloss or metal)",2D) = "grey"{}
        //_FaceShadowMap ("Face Shadow Map",2D) = "white"{}
        //_FaceShadowOffset ("Face Shadow Offset", range(0.0, 1.0)) = 0.1
        //_FaceShadowPow ("Face Shadow Pow", range(0.001, 1)) = 0.1


        [Header(Specular)]
        [Space(5)]
        [Header(BasicSpecular)]
        _SpecularGloss ("Specular Gloss",Range(8.0,256)) = 20
        _SpecularIntensity ("Specular Intensity",Range(0,255)) = 20
        [Header(MetalSpecular)]
        _MetalMap ("Metal Map",2D) = "white" {}
        _MetalIntensity ("Metal Intensity",Range(0,10)) = 0
        _MetalMapV ("Metal Map V",Range(0,1)) = 0.2
        [HDR]_MetalColor ("Metal Color",Color) = (1,1,1,1)//metal color


        [Space(5)]
        [Header(HairSpecular)]
        //_HairSpecularIntensity ("Hair Specular Intensity",Range(0,10)) = 0.5
        //_HairSpecularGloss ("Hair Specular Gloss",Range(0,3)) = 1
        _HairSpecularRange ("Hair Specular Range",Range(0,1)) = 0.5
        //_HairSpecularVRange ("Hair Specular view Range",Range(0,1)) = 0.5
        _HairSpecularColor ("Hair Specular Color",Color) = (1,1,1,1)
        //_KajiyaP ("Hair Kajiya",Range(0,1)) = 0.1
        //[Header(LineSpecular)]
        //_HairLineIntensity ("Hair Line Intensity",Range(0,1)) = 0.2

        [Header(Main Lighting Settings)]
        [ToggleOff] _ReceiveShadow ("Receive Shadow", int) = 1
        _LightingDirectionFix ("Lighting Direction Fix", Range(0, 1)) = 0
        _LightingColor ("Lighting Color", Color) = (1, 1, 1)
        _ShadingColor ("Shading Color", Color) = (0.5, 0.5, 0.5)
        _DiffuseShadowBias ("Bias", Range(-1, 1)) = 0
        _DiffuseShadowSmoothstep ("Smoothstep", Range(0, 1)) = 0

        [Header(RimLight)]
        [Space(5)]
        _RimIntensity ("Rim Light Intensity",Range(0,10)) = 8
        _RimRadius ("Rim Light Radius",Range(0,20)) = 0
        _RimLightColor("Rim Light Color",Color) = (1,1,1,1)
        _RimOffset("RimOffset",range(0,1)) = 0.5
        _RimThreshold("RimThreshold",range(-1,1)) = 0.5


        [Header(Emission)]
        [Space(5)]
        [Toggle(_IS_EMISSIVE)]_IS_EMISSIVE("_IS_EMISSIVE", Float) = 0
        [Toggle(_IS_FLICKER)]_IS_FLICKER("_IS_FLICKER", Float) = 0 // Open this after _IS_EMISSIVE or only _IS_EMISSIVE
        _EmissionIntensity("Emission Intensity",Range(0,255)) = 1
        [HDR]_EmissionColor("Emission Color",Color) = (1,1,1,1)



        [Header(Outline(Sihouetting))]
        [Space(5)]
        _OutlineColor("OutLine Color",Color) = (0,0,0,1)
        _OutlineWidth("Outline Width",Range(-1,1)) = 0.1


        _ShadowColor ("Shadow Color",Color) = (1,1,1,1)

        //_LightThreshold ("Light Threshold",Range(0,10)) = 0.5

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

        #pragma vertex vert
        #pragma fragment frag

        #pragma shader_feature _SHADERENUM_BASE _SHADERENUM_FACE _SHADERENUM_HAIR

        #pragma shader_feature_local _CLIMATE_COOL _CLIMATE_WARM

        #pragma shader_feature_local _IS_EMISSIVE _IS_FLICKER

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS


        //声明
        CBUFFER_START(UnityPerMaterial) //缓冲区

        //BaseMap
        float4 _MainTex_ST;  //要注意纹理不能放在缓冲区
        float4 _MainColor;
        float4 _RampTex_ST;
        float4 _RampTex1_ST;

        uniform float _InNight;

        //RimLight
        uniform float _RimIntensity;
        uniform float _RimRadius;
        uniform float4 _RimLightColor;

        //diffuse
        uniform float _FaceDiffuseIntensity;
        uniform float _RampMapYRange;

        //Specualr
        uniform float4 _MetalColor;
        uniform float _SpecularGloss;
        uniform float _SpecularIntensity;

        uniform float _MetalIntensity;
        uniform float _MetalMapV;


        uniform float4 _HairSpecularColor;
        uniform float _HairSpecularRange;
        /*uniform float _HairSpecularIntensity;
        uniform float _HairSpecularVRange;

        uniform float _HairSpecularGloss;
        uniform float _SpecularStepGloss;
        uniform float _StepSpecularIntensity;
        uniform float _StepSpecularWidth;
        uniform float _HairLineIntensity;*/

        //uniform float _KajiyaP;

        //decide which ramp
        uniform float _RampYRange;
        uniform float _RimPower;
        uniform int _isCloth;
        uniform float _RampIntensity;

        //Emission
        uniform float _EmissionIntensity;
        uniform float4 _EmissionColor;

        //Sihouetting
        uniform float4 _OutlineColor;
        uniform float _OutlineWidth;
        //face
        //uniform float _FaceShadowPow;
        //uniform float _FaceShadowOffset;

        //SHADOW
        uniform float4 _ShadowColor;

        int _ReceiveShadow;
        float _LightingDirectionFix;
        float3 _LightingColor;
        float3 _ShadingColor;
        float _DiffuseShadowSmoothstep;
        float _DiffuseShadowBias;

        float _LightThreshold;

        half _RimOffset;
        half _RimThreshold;

        half _AO;

        // Silk
        half _Denier;
        //_DenierTex("Density Texture", 2D) = "black"{}
		half _Smoothness;
		half _Metallic;
        half4 _SkinTint;
        //_SkinTex("Skin Color", 2D) = "white" {}
        half4 _StockingTint;
        //_StockingTex("Stocking Color", 2D) = "white"{}
        CBUFFER_END

        //Texture
        TEXTURE2D(_MainTex);        //要注意在CG中只声明了采样器 sampler2D _MainTex,
        SAMPLER(sampler_MainTex); //而在HLSL中除了采样器还有纹理对象，分成了两部分
        TEXTURE2D(_RampTex);
        SAMPLER(sampler_RampTex);
        TEXTURE2D(_RampTex1);
        SAMPLER(sampler_RampTex1);
        TEXTURE2D(_FaceShadowMap);
        SAMPLER(sampler_FaceShadowMap);
        TEXTURE2D(_LightMap);
        SAMPLER(sampler_LightMap);
        TEXTURE2D(_MetalMap);
        SAMPLER(sampler_MetalMap);

        //depth
        TEXTURE2D_X_FLOAT(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);

        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;
            float4 tangent : TANGENT;
            float4 vertexColor: COLOR;
        };
        struct VertexOutput //输出结构
        {
            float4 pos : POSITION;
            float2 uv : TEXCOORD0;
            float4 vertexColor: COLOR;
            float3 nDirWS : TEXCOORD1;
            float3 nDirVS : TEXCOORD2;
            float3 vDirWS : TEXCOORD3;
            float3 worldPos : TEXCOORD4;
            float3 lightDirWS : TEXCOORD5;
            float clipW : TEXCOORD6;
             float4 shadowCoord : TEXCOORD7;
            float3 worldTangent : TANGENT;
        };

        float3 NPR_Emission(float4 baseColor)
        {
            float3 factor = float3(1,1,1);
            #if _IS_FLICKER
                factor *= abs((frac(_Time.y * 0.5) - 0.5) * 2);
            #endif
            return baseColor * _EmissionIntensity  * _EmissionColor.rgb * factor;
        }

        //金属部分
        float3 GenshinNPR_Metal(float3 normalDirWS, float4 metalMap, float3 baseColor,float4 lightMap)
        {
            // Get NormalDirVS,视角空间法线用于采样Matcap贴图
            float metalDir = normalize(mul(UNITY_MATRIX_V,normalDirWS));

            float metalRadius = saturate(1 - metalDir) * saturate(1 + metalDir);

            float metalFactor = saturate(step(0.5,metalRadius)+0.25) * 0.5
            * saturate(step(0.15,metalRadius) + 0.25);

            float3 metalColor = metalFactor * baseColor * step(0.95,lightMap.r);

            return metalColor;
        }

        float3 GenshinNPR_RimLight(float ndotV,float ndotL,float3 albedo)
        {
            return (1 - smoothstep(_RimRadius,_RimRadius + 0.03,ndotV)) * _RimIntensity * (1 - (ndotL)) * albedo;
        }

        float3 GenshinNPR_Specular(float ndotH,float ndotL,float3 normalDirWS,float4 baseColor,float4 lightMap,float4 metalMap)
        {
            //SD的blinnPhong的高光计算方法
            float Ks = 0.04;
            float  SpecularPow = exp2(0.5 * lightMap.r * 11.0 + 2.0);//这里乘以0.5是为了扩大高光范围
            float  SpecularNorm = (SpecularPow+8.0) / 8.0;
            float3 SpecularColor = baseColor * lightMap.g;
            float SpecularContrib = baseColor * (SpecularNorm * pow(ndotH, SpecularPow));
            return float3(0,0,0);
            //float3 MetalColor = GenshinNPR_Metal(normalDirWS,metalMap,baseColor,lightMap);
            return SpecularColor * (SpecularContrib  * ndotL* Ks * lightMap.b);
        }

        float3 GenshinNPR_RimLight(float ndotV,float ndotL,float4 baseColor)
        {
            float3 rim = (1 - smoothstep(_RimRadius, _RimRadius + 0.03, ndotV)) *
                _RimIntensity * (1 - (ndotL * 0.5 + 0.5)) * baseColor * _MainLightColor.rgb;
            //float3 rim = (1 - smoothstep(_RimRadius, _RimRadius + 0.03, NdotV)) * _RimIntensity * baseColor;
            return rim;
        }
         //头发高光
        float3 GenshinNPR_Hair_Specular(float ndotH, float4 lightMap)
        {
            //头发高光
            float SpecularRange = smoothstep(1 - _HairSpecularRange, 1, ndotH);
            float HairSpecular = lightMap.b * SpecularRange;
            float3 hairSpec = HairSpecular * _HairSpecularColor.rgb;
            return hairSpec;
        }

        float3 GenshinNPR_Ramp(float ndotL,float4 lightMap)
        {
            float halfLambert = smoothstep(0.0, 0.5, ndotL); //只要halfLambert的一半映射Ramp
            /*
            Skin = 255
            Silk = 160
            Metal = 128
            Soft = 78
            Hand = 0
            */
            //只保留0.0 - 0.5之间的，超出0.5的范围就强行改成1，一般ramp的明暗交界线是在贴图中间的，这样被推到贴图最右边的一个像素上
            if (_InNight > 0.0)
            {
                //因为分层材质贴图是一个从0-1的一张图 所以可以直接把他当作采样UV的Y轴来使用
                return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, _RampMapYRange)).rgb;
                //return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, lightMap.a * 0.45 + 0.55)).rgb * _RampIntensity;
                //又因为白天需要只采样Ramp贴图的上半段，所以把他 * 0.45 + 0.55来限定范围 (范围 0.55 - 1.0)
            }
            else
            {
                //因为晚上需要只采样Ramp贴图的上半段，所以把他 * 0.45来限定范围(其中如果采样0.5的话 会被上面的像素所影响)
                return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, _RampMapYRange + 0.5)).rgb;
                //return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, lightMap.a * 0.45)).rgb * _RampIntensity;
            }

        }


        //=======================Output for Character===============================

        //【StarTrail】 use Hanya as model
        float3 StarTrailNPR_Ramp(float ndotL,float4 lightMap)
        {
            // 分成cool 和 warm两种气候
            // lightmap.g存储了AO
            float shadowFactor = lightMap.g + _AO;
            shadowFactor = saturate(shadowFactor);
            float halfLambert = smoothstep(0.0, 0.5, ndotL);

            #if _CLIMATE_COOL
                //只保留0.0 - 0.5之间的，超出0.5的范围就强行改成1，一般ramp的明暗交界线是在贴图中间的，这样被推到贴图最右边的一个像素上
                if (_InNight > 0.0)
                {
                    //因为分层材质贴图是一个从0-1的一张图 所以可以直接把它当作采样UV的Y轴来使用
                    return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, _RampMapYRange)).rgb * shadowFactor;
                    //return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, lightMap.a * 0.45 + 0.55)).rgb * _RampIntensity;
                    //又因为白天需要只采样Ramp贴图的上半段，所以把他 * 0.45 + 0.55来限定范围 (范围 0.55 - 1.0)
                }
                else
                {
                    //因为晚上需要只采样Ramp贴图的上半段，所以把它 * 0.45来限定范围(其中如果采样0.5的话 会被上面的像素所影响)
                    return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, _RampMapYRange + 0.5)).rgb * shadowFactor;
                    //return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, lightMap.a * 0.45)).rgb * _RampIntensity;
                }
            #elif _CLIMATE_WARM
                if (_InNight > 0.0)
                {
                    return SAMPLE_TEXTURE2D(_RampTex1, sampler_RampTex1, float2(halfLambert, _RampMapYRange)).rgb * shadowFactor;
                }
                else
                {
                    return SAMPLE_TEXTURE2D(_RampTex1, sampler_RampTex1, float2(halfLambert, _RampMapYRange + 0.5)).rgb * shadowFactor;

                }
            #endif
        }

        float3 StarTrailNPR_Specular(float ndotH,float ndotL,float3 normalDirWS,float4 baseColor,float4 lightMap,float4 metalMap)
        {
            //TODO: 使用LighMap
            // 普通BlinnPhong
            float3 blinnPhongSpecular = baseColor.rgb * _MainLightColor.rgb * pow(ndotH,_SpecularGloss)* _SpecularIntensity * lightMap.b;// * lightMap.a;

            return blinnPhongSpecular;

            //根据需求添加
            //float3 stepSpecular = 0;
            /*float specularLayer = lightMap.b * 255;
            if (specularLayer >= 10 && specularLayer < 100)
            {
                stepSpecular = pow(saturate(ndotV), 2 * _SpecularGloss) *_SpecularIntensity;
                stepSpecular = max(0, stepSpecular);
                stepSpecular += MetalMap; // 金属效果
                stepSpecular *= baseColor;

                // TODO:根据需求添加自发光
                //后续使用了BaseColor.a中存储的自发光的范围，所以这里姑且不做自发光
                //emission = NPR_Emission(baseColor) * 0.2;
            }*/


            return float3(0,0,0);
            return blinnPhongSpecular;
        }

         //头发高光
        float3 StarTrailNPR_Hair_Specular(float ndotH, float4 lightMap)
        {
            //直接根据LightMap获得高光范围，然后是二分BlinnPhong
            float SpecularRange = smoothstep(1 - _HairSpecularRange, 1, ndotH);
            float HairSpecular = lightMap.b * SpecularRange;
            float3 hairSpec = HairSpecular * _HairSpecularColor.rgb;
            return hairSpec;
        }

        float3 StarTrailNPR_Hair(float ndotL, float ndotH, float ndotV, float3 nDir,
            float4 baseColor, float4 lightMap,float4 metalMap)
        {
            //头发的rampColor不应该把固定阴影的部分算进去，所以这里固定阴影给定0.5 到计算ramp的时候 *2 结果等于1
            float3 rampColor = StarTrailNPR_Ramp(ndotL,lightMap);

            float3 albedo = baseColor * rampColor * _MainLightColor.rgb;

            //float HariSpecRadius = 0.25; //这里可以控制头发的反射范围
            //float HariSpecDir = normalize(mul(UNITY_MATRIX_V, nDir)) * 0.5 + 0.5;
            //float3 HariSpecular = smoothstep(HariSpecRadius, HariSpecRadius + 0.1, 1 - HariSpecDir) * smoothstep(HariSpecRadius, HariSpecRadius + 0.1, HariSpecDir) * NdotL; //利用屏幕空间法线
            //float3 Specular = NPR_Specular(NdotH, baseColor, lightMap) + HariSpecular * _HairSpecularIntensity * lightMap.g * step(lightMap.r, 0.1);
            float3 hairSpec = StarTrailNPR_Hair_Specular(ndotH, lightMap);

            float3 Metal = GenshinNPR_Metal(nDir, metalMap,baseColor,lightMap);
            float3 RimLight = GenshinNPR_RimLight(ndotV, ndotL, baseColor);
            float3 finalRGB = albedo + hairSpec * rampColor;// + RimLight + Metal;
            return finalRGB;
        }

        float3 StarTrailNPR_Face(float4 baseColor, float4 lightMap, float3 lightDirWS, float2 uv1)
        {
            //【Star trail】lightMap.r 从0-1存储了SDF图
            // unity_ObjectToWorld 4x4
            // 1. 最后一列是世界坐标
            // 2. 左上3x3的部分是旋转矩阵(需要先乘以缩放,缩放是列向量的模,4x4其它部分除了右下角全部归0)
            // 3. 从模型空间变换到世界空间

            //上方向
            float3 Up = float3(0.0, 1.0, 0.0);
            //角色朝向
            float3 Front = unity_ObjectToWorld._13_23_33;
            //Front = float3(0,0,1);
            //角色右侧朝向
            float3 Right = cross(Up, Front);
            //阴影贴图左右正反切换的开关
            float switchShadow = step(dot(normalize(Right.xz), lightDirWS.xz) * 0.5 + 0.5, 0.5);

            uv1.x = switchShadow ? uv1.x : 1 - uv1.x;
            lightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,uv1);


            //阴影贴图左右正反切换
            //float FaceShadow = lerp(1- lightMap.g, 1 - lightMap.r, switchShadow);
            //FaceShadow = lerp(lightMap, 1 - lightMap, switchShadow);
            //脸部阴影切换的阈值
            float FaceShadowRange = dot(normalize(Front.xz), normalize(lightDirWS.xz));
            //使用阈值来计算阴影 _FaceShadowOffset
            float lightAttenuation = 1 - smoothstep(FaceShadowRange - 0.05,
                FaceShadowRange + 0.05, 1-lightMap.r);

            float stepFaceShadowFactor = lightAttenuation > 0?1:0.8;

            float3 emission = NPR_Emission(baseColor);

            return lerp(baseColor*stepFaceShadowFactor,baseColor ,saturate(lightAttenuation)) + emission;
        }

        float3 StarTrailNPR_Base(float ndotL, float ndotH, float ndotV, float3 normalDirWS,
            float4 baseColor, float4 lightMap,float4 metalMap)
        {
            float3 rampColor = StarTrailNPR_Ramp(ndotL,lightMap);

            float3 albedo = baseColor * rampColor * _MainLightColor.rgb;

            float3 specular = StarTrailNPR_Specular(ndotH,ndotL,normalDirWS,baseColor, lightMap,metalMap) * rampColor;

            float3 metal = GenshinNPR_Metal(normalDirWS, metalMap,baseColor,lightMap);

            float3 rimLight = GenshinNPR_RimLight(ndotV, ndotL, baseColor) * lightMap.b; // Special for specular

            float3 emission = NPR_Emission(baseColor) * lightMap.g;

            float3 finalColor = albedo + specular + metal + rimLight + emission;
            return finalColor;
        }


        // Genshin Impact Part
        //1. 头发
        float3 GenshinNPR_Hair(float ndotL, float ndotH, float ndotV, float3 nDir,
            float4 baseColor, float4 lightMap,float4 metalMap)
        {
            //头发的rampColor不应该把固定阴影的部分算进去，所以这里固定阴影给定0.5 到计算ramp的时候 *2 结果等于1
            float3 rampColor = GenshinNPR_Ramp(ndotL,lightMap);

            float3 albedo = baseColor * rampColor * _MainLightColor.rgb;

            //float HariSpecRadius = 0.25; //这里可以控制头发的反射范围
            //float HariSpecDir = normalize(mul(UNITY_MATRIX_V, nDir)) * 0.5 + 0.5;
            //float3 HariSpecular = smoothstep(HariSpecRadius, HariSpecRadius + 0.1, 1 - HariSpecDir) * smoothstep(HariSpecRadius, HariSpecRadius + 0.1, HariSpecDir) * NdotL; //利用屏幕空间法线
            //float3 Specular = NPR_Specular(NdotH, baseColor, lightMap) + HariSpecular * _HairSpecularIntensity * lightMap.g * step(lightMap.r, 0.1);
            float3 hairSpec = GenshinNPR_Hair_Specular(ndotH, lightMap);

            float3 emission = NPR_Emission(baseColor) * lightMap.a;

            float3 Metal = GenshinNPR_Metal(nDir, metalMap,baseColor,lightMap);
            float3 RimLight = GenshinNPR_RimLight(ndotV, ndotL, baseColor);
            float3 finalRGB = albedo + hairSpec * rampColor + RimLight + Metal + emission;
            return finalRGB;
        }

        //2. 面部
        float3 GenshinNPR_Face(float4 baseColor, float4 lightMap, float3 lightDirWS, float2 uv1)
        {
            //【Star trail】lightMap.r
            // unity_ObjectToWorld 4x4
            // 1. 最后一列是世界坐标
            // 2. 左上3x3的部分是旋转矩阵(需要先乘以缩放,缩放是列向量的模,4x4其它部分除了右下角全部归0)
            // 3. 从模型空间变换到世界空间

            //上方向
            float3 Up = float3(0.0, 1.0, 0.0);
            //角色朝向
            float3 Front = unity_ObjectToWorld._13_23_33;
            //Front = float3(0,0,1);
            //角色右侧朝向
            float3 Right = cross(Up, Front);
            //阴影贴图左右正反切换的开关
            float switchShadow = step(dot(normalize(Right.xz), lightDirWS.xz) * 0.5 + 0.5, 0.5);

            uv1.x = switchShadow ? uv1.x : 1 - uv1.x;
            lightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,uv1);
            //float switchShadow  = dot(normalize(Right.xz), normalize(lightDirWS.xz)) < 0;
            //阴影贴图左右正反切换
            float FaceShadow = lerp(1- lightMap.g, 1 - lightMap.r, switchShadow);
            //FaceShadow = lerp(lightMap, 1 - lightMap, switchShadow);
            //脸部阴影切换的阈值
            float FaceShadowRange = dot(normalize(Front.xz), normalize(lightDirWS.xz));
            //使用阈值来计算阴影 _FaceShadowOffset
            float lightAttenuation = 1 - smoothstep(FaceShadowRange - 0.05,
                FaceShadowRange + 0.05, FaceShadow);

            //Ramp
            float3 tempRampMap = float3(lightAttenuation,lightAttenuation,lightAttenuation);


            float stepFaceShadowFactor = lightAttenuation > 0?1:0.8;
            //return tempRampMap;
            //float3 rampColor =  GenshinNPR_Ramp(lightAttenuation,lightMap);

            float3 faceShadowColor = lerp(baseColor,baseColor * stepFaceShadowFactor,stepFaceShadowFactor);
            //float3 emission = NPR_Emission(baseColor);
            //rampColor = lerp(baseColor,tempRampMap,lightAttenuation);


            float3 faceColor = lerp(baseColor,faceShadowColor,stepFaceShadowFactor);

            float3 emission = NPR_Emission(baseColor) * lightMap.a;

            return faceColor * _MainLightColor.rgb + emission;
        }

        //3. 身体部分
        float3 GenshinNPR_Base(float ndotL, float ndotH, float ndotV, float3 normalDirWS,
            float4 baseColor, float4 lightMap,float4 metalMap)
        {
            float3 rampColor = GenshinNPR_Ramp(ndotL,lightMap);
            float3 albedo = baseColor * rampColor * _MainLightColor.rgb;
            float3 specular = GenshinNPR_Specular(ndotH,ndotL,normalDirWS,baseColor, lightMap,metalMap);
            float3 metal = GenshinNPR_Metal(normalDirWS, metalMap,baseColor,lightMap);
            float3 rimLight = GenshinNPR_RimLight(ndotV, ndotL, baseColor) * lightMap.g;
            float3 emission = NPR_Emission(baseColor);

            float3 finalColor = albedo * (1 - lightMap.r) + specular + metal + rimLight + emission;
            return finalColor;
        }

        // 丝织品(丝袜之类)
        float3 SilkRendering()
        {
            // ref: https://blog.csdn.net/qq_42115447/article/details/102616272
            // 1. Denier 丹尼尔值 衡量fabric纤维的值
            //o.Normal = UnpackNormal(tex2D(_NormalTex, IN.uv_NormalTex));  //得到法线
            //float4 skinColor = tex2D(_SkinTex, IN.uv_SkinTex) * _SkinTint;    //内颜色
            //float4 stockingColor = tex2D(_StockingTex, IN.uv_StockingTex) * _StockingTint;    //外颜色
            //float rim = pow(1 - dot(normalize(IN.viewDir), o.Normal), _RimPower / 10);   //边缘光
			//float fresnel = pow(1.0 - max(0,dot(normalize(IN.viewDir), o.Normal)),_FresnelScale);    //菲涅尔
            //float denier = (_Denier - 5) / 115;    //丹尼尔参数
            //float density = max(rim, (denier * (1 - tex2D(_DenierTex, IN.uv_DenierTex))));  //lerp参数

            // 皮肤颜色
            float4 skinColor =  _SkinTint; //tex2D(_SkinTex, IN.uv_SkinTex) *
        }
        //===================END Output for Character===============================


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
                o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.uv = v.uv;
                //o.uv = float2(o.uv.x, 1 - o.uv.y);
                o.nDirWS = TransformObjectToWorldDir(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.worldTangent = TransformObjectToWorldDir(v.tangent);
                o.vertexColor = v.vertexColor;

                o.clipW = o.pos.w;
                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                //====================================================================
                //==================PREPAREATION FOR COMPUTE==========================
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
                float ndotV = saturate(dot(nDirWS,vDirWS));
                float hdotT = max(dot(halfDirWS,tangentDir),0); //切线点乘半角
                float halfLambert = dot(nDirWS,lightDirWS) * 0.5 + 0.5;


                //-------主光源光照计算-------
                /*
                float3 fixedLightDirection = normalize(float3Lerp(lightDirWS, float3(lightDirWS.x, 0, lightDirWS.z), _LightingDirectionFix));
                float NdotFL = dot(nDirWS, fixedLightDirection);
                float linear01DiffuseFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotFL - _DiffuseShadowBias);
                i.shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                float linear01ShadowFactor = floatLerp(1, MainLightRealtimeShadow(i.shadowCoord), _ReceiveShadow);
                float linear01LightingFactor = linear01DiffuseFactor * linear01ShadowFactor;
                float linear01ShadingFactor = 1 - linear01LightingFactor;
                float3 finalDiffuseColor = _LightingColor * linear01LightingFactor + _ShadingColor * linear01ShadingFactor;*/
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
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,i.uv);
                float4 metalMap;//to be sampled if you are going to use a texture
                float3 albedo = baseColor * GenshinNPR_Ramp(ndotL,lightMap);
                //return float4(baseColor.a,baseColor.a,baseColor.a,1);


                //return float4(lightMap.g,lightMap.g,lightMap.g,1.0);


                //========================Additional Effects====================================
                float3 emission = float3(0,0,0);
                float3 specular = float3(0,0,0);
                float3 stepSpecular = float3(0,0,0);
                float3 stepSpecular2 = float3(0,0,0);
                float specularLayer = lightMap.r * 255;

                float4 MetalMap = SAMPLE_TEXTURE2D(_MetalMap,sampler_MetalMap, mul((float3x3)UNITY_MATRIX_V, nDirWS).xz).r;
                MetalMap = saturate(MetalMap);
                MetalMap = step(_MetalMapV, MetalMap) * _MetalIntensity;

                //// 这里使用lightMap.r拆分出 装饰部分的高光,例如宝石,根据需求修改
                if (specularLayer >= 10 && specularLayer < 100)
                {
                    //return float4(1,0,0,1);
                    stepSpecular = pow(saturate(ndotV), 2 * _SpecularGloss) *_SpecularIntensity;
                    stepSpecular = max(0, stepSpecular);
                    stepSpecular += MetalMap; // 金属效果
                    stepSpecular *= baseColor;

                    // TODO:根据需求添加自发光
                    //后续使用了BaseColor.a中存储的自发光的范围，所以这里姑且不做自发光
                    emission = NPR_Emission(baseColor) * 0.2;
                }
                //========================Additional Effects====================================

                float3 FinalColor = float3(0.0, 0.0, 0.0);

                // StarTrail NPR
                //【Star trail】Hanya
                // LightMap.r outline,face sdf(Face Light Map)
                // LightMap.g outline? AO
                // LightMap.b specular: metal,hair
                // LightMap.a skin,cloth...
                // Three Parts: Body(Base),Face,Hair + Additional Part
                /*
                #if _SHADERENUM_BASE
                    FinalColor = StarTrailNPR_Base(ndotL,ndotH,ndotV,lightDirWS,baseColor,lightMap,metalMap);
                #elif  _SHADERENUM_FACE
                    FinalColor = GenshinNPR_Face(baseColor, lightMap, lightDirWS,i.uv);
                    stepSpecular = float3(0,0,0);
                #elif _SHADERENUM_HAIR
                    FinalColor = StarTrailNPR_Hair(ndotL, ndotH, ndotV,  nDirWS, baseColor, lightMap,metalMap);
                #endif*/


                //return float4(FinalColor,1.0);
                // Genshin NPR
                // Three Parts: Body(Base),Face,Hair
                #if _SHADERENUM_BASE
                    FinalColor = GenshinNPR_Base(ndotL,ndotH,ndotV,lightDirWS,baseColor,lightMap,metalMap);
                #elif  _SHADERENUM_FACE
                    FinalColor = GenshinNPR_Face(baseColor, lightMap, lightDirWS,i.uv);
                    stepSpecular = float3(0,0,0);
                #elif _SHADERENUM_HAIR
                    FinalColor = GenshinNPR_Hair(ndotL, ndotH, ndotV,  nDirWS, baseColor, lightMap,metalMap);
                #endif


                // 屏幕空间UV(视口坐标)SV_Position
                float2 screenParams01 = float2(i.pos.x/_ScreenParams.x,i.pos.y/_ScreenParams.y);
                float2 offectSamplePos = screenParams01-float2(_RimOffset/i.clipW,0);
                float offcetDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture, offectSamplePos);
                float trueDepth   = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,screenParams01);
                float linear01EyeOffectDepth = Linear01Depth(offcetDepth,_ZBufferParams);
                float linear01EyeTrueDepth = Linear01Depth(trueDepth,_ZBufferParams);
                float depthDiffer = linear01EyeOffectDepth-linear01EyeTrueDepth;
                float rimIntensity = step(_RimThreshold,depthDiffer);
                float4 col = float4(rimIntensity,rimIntensity,rimIntensity,1) * _RimLightColor;

                float3 fresnelRimLight = GenshinNPR_RimLight(ndotV,ndotL,albedo);

                float3 ans = lerp(col.rgb,fresnelRimLight,0.6);

                //ans = 0;//no ssrl

                //return float4(ans ,1.0);

                //return col;
                // 也许面部不需要stepSpecular的高光?
                //return float4(FinalColor,1.0);
                return float4(FinalColor + stepSpecular + emission + ans.rgb + finalAdditionalLightingColor, 1.0);
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
                // 1. 普通法线外扩 View Space 也称作三角面扩张法 过程式几何描边
                //float4 pos = mul (UNITY_MATRIX_MV , v.vertex);
                //注意法线空间变换的特殊性
                //float3 normal= mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                //normal.z = -0.5 ;
                //pos = pos + float4(normalize(normal) , 0) * _OutlineWidth ;
                //o.pos = mul(UNITY_MATRIX_P , pos);

                // 2. NDC空间法线方向外扩
                float4 pos = TransformObjectToHClip(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                //将法线变换到NDC空间  //clamp(0,1)加上后当相机拉远后会减弱看上去黑色描边明显问题，也可以不加;
                float3 ndcNormal = normalize(mul(UNITY_MATRIX_P,viewNormal.xyz)) * pos.w; //clamp(pos.w, 0, 1);

                //将近裁剪面右上角位置的顶点变换到观察空间
                float4 nearUpperRight = mul(unity_CameraInvProjection,
                    float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));

                //求得屏幕宽高比
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);
                ndcNormal.x *= aspect;
                pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
                o.pos = pos;

                // 3. 平滑法线存在tangent中, Object Space外扩
                //罪恶装备strive
                //罪恶装备vertexcolor.a存储了描边，当前使用的原神模型的没有
                //v.vertex.xyz += v.tangent.xyz  * _OutlineWidth * 0.01;// * v.vertexColor.a;
                //o.pos = TransformObjectToHClip(v.vertex);

                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                return float4(_OutlineColor.rgb,1);
            }
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

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

        // From Universal Render Pipeline Lit
        Pass
        {
            Name "Universal2D"
            Tags{ "LightMode" = "Universal2D" }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
    }

}
