////////////////////////////////////////////////////////////////////////////////
///Aspect NPR Shader for Anime Characters,replicate of Genshin and GGS(GGXrd)///
//@author: aspect_ux
//@file: AspectURP/Aspect_NPR_Character
//@date: 2023/12/25
///////////////////////////////////////////////////////////////////////////////

Shader "AspectURP/Aspect_NPR_Character"
{
    Properties
    {
        [Header(ShaderEnum)]
        [Space(5)]
        [KeywordEnum(Base,Face,Hair)] _ShaderEnum ("Shader Enum",int) = 1
        [Enum(OFF,0,FRONT,1,BACK,2)] _Cull ("Cull Mode",int) = 1

        [Header(BaseMap)]
        [Space(5)]
        _MainTex ("Main Tex",2D) = "white"{}
        [HDR]_MainColor ("Main Color",Color) = (1,1,1,1)
        
        [Header(DetailMap)]
        [Space(5)]
        _DetaiMap ("Detail Tex",2D) = "white"{}

        [Space(5)]
        _SSSTexture ("SSS Texture",2D) = "white"{}
        _SceneColor ("Scene Color",Color) = (1,1,1,1)
        
        // Ramp
        [Header(Diffuse)]
        [Space(5)]
        _RampOffset ("Ramp Offset",Range(-2,1)) = 0.2

         //face, the same with paramTex
        [Space(5)]
         _AO ("AO",Range(0,20)) = 1
        _LightMap ("Light Map(for specular :gloss or metal)",2D) = "grey"{}
        //_FaceShadowOffset ("Face Shadow Offset", range(0.0, 1.0)) = 0.1
        //_FaceShadowPow ("Face Shadow Pow", range(0.001, 1)) = 0.1

        [Header(ParamTex)]
        [Space(5)]
        _ParamTex ("param Tex(_HairLightMap or Face_LightMap)", 2D) = "white" { }
        [Space(5)]
        //now we have hair and cloth light map

        [Header(Specular)]
        [Space(5)]
        [Header(BasicSpecular)]
        _SpecularGloss ("Specular Gloss",Range(0,1)) = 0.2
        _SpecularIntensity ("Specular Intensity",Range(0,1)) = 0.2
        _SpecularColor ("Specular Color",Color) = (1,1,1,1)

        _StepSpecularWidth ("Step Specular Width",Range(0,1)) = 0.2
        _StepViewWidth ("Step View Specular Width",Range(0,1)) = 0.2
        _StepSpecularIntensity ("Step Specular Intensity",Range(0,1)) = 0.6
        _StepViewIntensity ("Step View Intensity",Range(0,1)) = 0.6
       
        [Header(RimLight)]
        [Space(5)]
        _RimLightWidth ("Rim Light Width",Range(0,1)) = 1
        _RimIntensity ("Rim Light Intensity",Range(0,10)) = 8
        _RimRadius ("Rim Light Radius",Range(0,20)) = 0
        _RimLightColor ("Rim Color",Color) = (1,1,1,1)
        _RimLightBias ("Rim Light Bias",range(0,20)) = 0
        _RimLightAlbedoMix ("Albedo Mix (Multiply)", Range(0, 1)) = 0.5
        _RimLightSmoothstep ("Smoothstep", Range(0, 1)) = 0

        [Header(Emission)]
        _EmissionIntensity ("Emission Intensity",RANGE(0,1)) = 0.2
        _EmissionColor ("Emission Color",Color) = (1,1,1,1)

        _FresnelScale ("Fresnel Scale",Range(0,1)) = 0.5
        _FresnelPower ("Fresnel Power",Range(0,20)) = 5 
        [Space(5)]

        [Header(Sihouetting(Outline))]
        [Space(5)]
        _OutlineColor ("OutLine Color",Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width",Range(-1,1)) = 0.1
        
        [Space(5)]
        [Header(ShadowCast)]
        [Space(5)]
        [Header(ShadowAO)]
        _ShadowAOMap ("Shadow AO Map",2D) = "white"{}
        _ShadowThreshold("Shadow Threshold",Range(0,1)) = 0.5
        _ShadowIntensity("Shadow Intensity",Range(0,1)) = 0.4
        _ShadowArea("Shadow Area",RANGE(0,10)) = 0 
        _DarkShadowArea ("Dark Shadow Area",RANGE(0,10)) = 0
        _FixDarkShadow ("Fix Dark Shadow",RANGE(0,10)) = 0
        _ShadowColor ("Shadow Color",Color) = (1,1,1,1)

        _LightThreshold ("Light Threshold",Range(0,10)) = 0.5
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

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile_fragment _ _SHADOWS_SOFT

        //声明
        CBUFFER_START(UnityPerMaterial) //缓冲区

        //BaseMap
        float4 _MainTex_ST;  //要注意纹理不能放在缓冲区
        float4 _MainColor;
        float4 _RampTex_ST;
        float4 _Detail_ST;
       

        //RimLight
        uniform float _RimIntensity;
        uniform float _RimLightWidth;
        uniform float _RimRadius;
        uniform float4 _RimLightColor;
        uniform float _RimLightBias;
        uniform float _RimLightAlbedoMix;
        uniform float _RimLightSmoothstep;

        uniform float _FresnelScale;
        uniform float _FresnelPower;

        //diffuse
        uniform float _FaceDiffuseIntensity;
        uniform float _SmoothRange;
        uniform float _Smooth;

        //Specualr
        uniform float4 _SpecularColor;
        uniform float _SpecularGloss;
        uniform float _SpecularIntensity;
        uniform float4 _MetalColor;
        uniform float _MetalIntensity;
        uniform float _MetalMapV;
        uniform float _HairSpecularIntensity;
        uniform float _HairSpecularRange;
        uniform float _HairSpecularVRange;
        uniform float _HairSpecularColor;
        uniform float _HairSpecularGloss;
        uniform float _SpecularStepGloss;
        uniform float _StepSpecularIntensity;
        uniform float _StepSpecularWidth;
        uniform float _StepViewIntensity;
        uniform float _StepViewWidth;
        uniform float _HairLineIntensity;

        uniform float _KajiyaP;

        //decide which ramp
        uniform float _RampYRange;
        uniform float _RimPower;
        uniform int _isCloth;
        uniform float _RampIntensity;
        uniform float _RampOffset;
        uniform float _TornLineIntensity;

        //Emission
        uniform float _EmissionIntensity;
        uniform float4 _EmissionColor;
        uniform float _HasEmission;

        //Sihouetting
        uniform float4 _OutlineColor;
        uniform float _OutlineWidth;
        //face
        uniform float _FaceShadowPow;
        uniform float _FaceShadowOffset;

        uniform float _IsNight;

        //SHADOW
        uniform float _ShadowThreshold;
        uniform float _ShadowIntensity;
        uniform float _ShadowArea;
        uniform float _DarkShadowArea;
        uniform float _FixDarkShadow;
        uniform float _ShadowColor;
        uniform float _AO;
        uniform float4 _SceneColor;

        float _LightThreshold;

        CBUFFER_END

        //Texture
        TEXTURE2D(_MainTex);        //要注意在CG中只声明了采样器 sampler2D _MainTex,
        SAMPLER(sampler_MainTex); //而在HLSL中除了采样器还有纹理对象，分成了两部分
        TEXTURE2D(_RampTex);     
        SAMPLER(sampler_RampTex);//
        TEXTURE2D(_ParamTex);     
        SAMPLER(sampler_ParamTex);
        TEXTURE2D(_LightMap);     
        SAMPLER(sampler_LightMap);
        TEXTURE2D(_MetalMap);     
        SAMPLER(sampler_MetalMap);
        TEXTURE2D(_ShadowAOMap);     
        SAMPLER(sampler_ShadowAOMap);  
        TEXTURE2D(_SSSTexture);     
        SAMPLER(sampler_SSSTexture);
        TEXTURE2D(_DetailMap);     
        SAMPLER(sampler_DetailMap); 

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
            float3 worldNormal : TEXCOORD6;
            float3 worldTangent : TANGENT;
        };
        /*
        //头发
        float3 NPR_Hair(float NdotL, float NdotH, float NdotV, float3 nDir, float4 baseColor, float4 var_ParamTex, float _InNight, float _RampMapYRange)
        {
            //头发的rampColor不应该把固定阴影的部分算进去，所以这里固定阴影给定0.5 到计算ramp的时候 *2 结果等于1
            float3 RampColor = NPR_Ramp(NdotL, _InNight, _RampMapYRange);
            float3 Albedo = baseColor * RampColor;

            //float HariSpecRadius = 0.25; //这里可以控制头发的反射范围
            //float HariSpecDir = normalize(mul(UNITY_MATRIX_V, nDir)) * 0.5 + 0.5;
            //float3 HariSpecular = smoothstep(HariSpecRadius, HariSpecRadius + 0.1, 1 - HariSpecDir) * smoothstep(HariSpecRadius, HariSpecRadius + 0.1, HariSpecDir) * NdotL; //利用屏幕空间法线 
            //float3 Specular = NPR_Specular(NdotH, baseColor, var_ParamTex) + HariSpecular * _HairSpecularIntensity * var_ParamTex.g * step(var_ParamTex.r, 0.1);
            float3 hairSpec = NPR_Hair_Specular(NdotH, var_ParamTex);

            float3 Metal = NPR_Metal(nDir, var_ParamTex, baseColor);
            float3 RimLight = NPR_Rim(NdotV, NdotL, baseColor);
            float3 finalRGB = Albedo + hairSpec * RampColor + Metal + RimLight;
            return finalRGB;
        }*/
        
        float3 NPR_Emission(float4 baseColor)
        {
            return baseColor.a * baseColor * _EmissionIntensity * abs((frac(_Time.y * 0.5) - 0.5) * 2) * _EmissionColor.rgb;
        }

        // Reference from UnityCG.cginc
        inline half3 GammaToLinearSpace (half3 sRGB)
        {
		    // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
		    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);
		    // Precise version, useful for debugging.
		    //return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
        }
        inline half3 LinearToGammaSpace (half3 linRGB)
        {
		    linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
		    // An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
		    return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);
		    // Exact version, useful for debugging.
		    //return half3(LinearToGammaSpaceExact(linRGB.r), LinearToGammaSpaceExact(linRGB.g), LinearToGammaSpaceExact(linRGB.b))
        }

        float3 GGS_Diffuse(float4 sssTex,float4 baseColor,float4 detailMap,float4 rampOffsetMask,
            float shadowAOMask,float innerLine,float halfLambert)
        {
            //GGX:ShadowColor = albedo * SSS_TEX_Color * SceneColor;
            // 1. 计算ShadowColor
            float3 shadowColor = sssTex.rgb * (1-_ShadowIntensity);
            // 2. 判断是否为Shadow
            //shadowAOMask = VertexColor.r, Confirm that vertexColor exists
            //float isShadow = step(halfLambert + rampOffsetMask +  _RampOffset,0.5) || step(shadowAOMask * _AO,0.5); 
            float isShadow = step((halfLambert + _RampOffset), rampOffsetMask) * shadowAOMask;
            isShadow = saturate(isShadow);
            // 3. 叠加内描边和磨损线条
            baseColor *= (innerLine * detailMap);
            // 4. 插值计算漫反射
            float3 diffuse = _MainLightColor.rgb * lerp(baseColor * shadowColor,baseColor,1 - isShadow);
            return diffuse;
        }

        float3 GGS_Specular(float3 albedo,float ndotH,float ndotV,float specularIntensityMask,
            float linearLayer)
        {
            float3 specular = float3(0.0,0.0,0.0);
            float3 stepSpecular = float3(0,0,0);
            // 基础BlinnPhong光照模型
            specular = albedo * pow(saturate(ndotH),_SpecularGloss * specularIntensityMask)
            * _SpecularIntensity;
            specular = max(float3(0,0,0),specular);
            
            // 高光层次类型
            float specularLayer =  linearLayer * 255;
            
            if (specularLayer > 0 && specularLayer <= 140)
            {
                //【无高光】 暗部有边缘光 区别于亮部边缘光
                //TODO:TO be fixed
                float3 bodySpecular = albedo * step(1 - _StepSpecularWidth,ndotH)
                * _StepSpecularIntensity;
                specular = lerp(specular,bodySpecular,1);
            }
            if (specularLayer > 140 && specularLayer <= 190)
            {
                //【皮革材质】 需要视角裁边高光 暗部边缘光 这里直接用blinnPhong的参数了 区别[视角高光 blinnPhong]  
                float3 stepViewLight = step(1 - _StepViewWidth,ndotH) * _StepViewIntensity;
                stepSpecular = stepViewLight * albedo;
            }
            if (specularLayer > 190 && specularLayer < 260)                 //布料填充高光
            {
                //【金属材质】 blinnPhong 光源裁剪高光
                //stepSpecular = step(1-_StepSpecularWidth,ndotH) *  _StepSpecularIntensity;
                stepSpecular = step(_StepSpecularWidth,ndotV * _StepSpecularIntensity) * albedo;  
            }
            specular += stepSpecular;
            
            return specular;
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
                VertexOutput o;
                o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.nDirWS = TransformObjectToWorldDir(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.worldTangent = TransformObjectToWorldDir(v.tangent);
                o.worldNormal = TransformObjectToWorldDir(v.normal);
                o.vertexColor = v.vertexColor;
                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                //片元性能比较重要 需要省的话就用half3
                //====================================================================
                //==================PREPAREATION FOR COMPUTATION==========================
                // 1. Get World Space Vectors
                Light mainLight = GetMainLight();
                float3 nDirWS = normalize(i.nDirWS);
                //float3 lightColor = mainLight.color;
                float3 lightDirWS = normalize(mainLight.direction);
                float3 vDirWS = normalize(GetCameraPositionWS().xyz - i.worldPos);
                float3 halfDirWS = normalize(lightDirWS + vDirWS);
                float3 tangentDir = normalize(i.worldTangent);

                // 2. Dot product
                float ndotL = max(0,dot(nDirWS,lightDirWS)); //if less than 0,then it will be wrong in light dir
                float ndotH = saturate(dot(nDirWS,halfDirWS));
                float ndotV = max(0,dot(nDirWS,vDirWS));
                float hdotT = max(dot(halfDirWS,tangentDir),0); //切线点乘半角
                float lambert = max(dot(nDirWS,lightDirWS),0);
                float halfLambert = dot(nDirWS,lightDirWS) * 0.5 + 0.5;

                // 3. Sample Textures
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,i.uv);//ILM TEX
                //float4 var_ParamTex = SAMPLE_TEXTURE2D(_ParamTex,sampler_ParamTex,i.uv);
                float4 shadowAOMap = SAMPLE_TEXTURE2D(_ShadowAOMap,sampler_ShadowAOMap,i.uv);
                float4 sssTex = SAMPLE_TEXTURE2D(_SSSTexture,sampler_SSSTexture,i.uv);
                float4 detailMap = SAMPLE_TEXTURE2D(_DetailMap,sampler_DetailMap,i.uv); // 磨损线条

                //==================PREPAREATION END==========================

                float3 albedo = baseColor.rgb * _MainLightColor.rgb;

                //===================================================================
                // Guilty Gear Strive Part:
                // - BaseMap：基础色；(base)
                // - ShadowMap：暗部衰减色，与BaseMap相乘构成暗部；(sss)
                // - DetailMap：磨损线条；(decal)
                // - LightMap.r：高光类型；(ilm发光贴图)
                // - LightMap.g：Ramp偏移值；
                // - LightMap.b：高光强度Mask；
                // - LightMap.a：内描边Mask；
                // - VertexColor.r：AO部分；(模型自带vertex color)
                // - VertexColor.g：用于区分身体各个部位；
                // - VertexColor.b：描边粗细；
                //========================Diffuse====================================
                float rampOffset = lightMap.g; //rampOffset
                float innerLine = lightMap.a; //内描边
                float shadowAO = i.vertexColor.r; //ao

                float3 diffuse = GGS_Diffuse(sssTex,baseColor ,detailMap,rampOffset,shadowAO,innerLine,halfLambert);

                //==========================rimLight=================================
                //【General Formula】rimLight = _FresnelScale + (1-_FresnelScale) * pow(1-ndotV,_FresnelPower);
                float3 rimLight = step(1-_RimLightWidth,1-ndotV)* albedo * _RimIntensity;
                
                //========================Base Specular====================================
                // 普通高光和裁剪高光
                float3 specular = float3(0.0,0.0,0.0);
                float specularIntensityMask = lightMap.b;
                float linearLayer = lightMap.r;
                specular = GGS_Specular(albedo,ndotH,ndotV,specularIntensityMask,linearLayer);
                
                //==========================GGS=================================
                //return i.vertexColor;
                return float4(diffuse + specular + rimLight + NPR_Emission(baseColor),1);
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
                //将法线变换到NDC空间
                float3 ndcNormal = normalize(mul(UNITY_MATRIX_P,viewNormal.xyz)) * pos.w;

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
                //顶点是原点，每个顶点自带tangent方向，加上normal可以推出切线空间
                //v.vertex.xyz += v.tangent.xyz  * _OutlineWidth * 0.01 * v.vertexColor.a;
                //o.pos = TransformObjectToHClip(v.vertex);

                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                return float4(_OutlineColor.rgb,1);
            }
            ENDHLSL
        }
        
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        //UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        // Use AspectURP
        //UsePass "AspectURP/Shadow/ShadowCaster"
        UsePass "ESM/ShadowmapCaster/ShadowCaster"
    }
}
