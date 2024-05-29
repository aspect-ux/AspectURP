// NPR + PBR Shader
// reference: girls frontline
// description: a npr + pbr shader
Shader "AspectURP/NPBR"
{
    Properties
    {
        [Enum(OFF,0,FRONT,1,BACK,2)] _Cull ("Cull Mode",int) = 1
        [KeywordEnum(PBR_Base,Cloth,Face,Hair,Eye)] _ShaderEnum ("Shader Enum",int) = 1
        _MainTex ("Main Tex", 2D) = "white" {}
        [Toggle(_USE_NORMALTEX)]_USE_NORMALTEX("_USE_NORMALTEX", Float) = 0
        _NormalTex ("Normal Tex", 2D) = "white" {}
        _NormalScale ("Normal Scale",Range(0,10)) = 1
        _MaskTex ("Mask Tex", 2D) = "white" {}
        _Metallic ("Metallic",RANGE(0,1)) = 0.01
        _AO ("Ambient Occlusion",RANGE(0,1)) = 0.01
        _DirectOcclusion ("Directional Occlusion",RANGE(0,1)) = 0.1
        _Roughness ("Roughness",RANGE(0,1)) = 0.01

        [Toggle(_ONLY_INDIRECT)]_ONLY_INDIRECT("_ONLY_INDIRECT", Float) = 0
        [Toggle(_ONLY_DIRECT)]_ONLY_DIRECT("_ONLY_DIRECT", Float) = 0

        [Toggle(INDIRECT_CUBEMAP)]_INDIRECT_CUBEMAP("_INDIRECT_CUBEMAP", Float) 		= 0
        [NoScaleOffset]_IndirSpecCubemap("Indirect Specular Cube", cube) 	= "black" {}
        _IndirectSpecLerp ("Indirect Sepcular Lerp",RANGE(0,1)) = 0.1
        _EnvironmentColor ("Env Color",COLOR) = (1,1,1,1)

        _FaceLightMap("Face Light Map(SDF)",2D) = "white"{}

        [Space(5)]
        [Header(Parallax)]
        _ParallaxScale("ParallaxScale", Range(0, 1))        = 1.0
        _ParallaxMaskEdge("MaskEdge", Range(0, 1))          = 0.8
        _ParallaxMaskEdgeOffset("MaskEdgeOffset", Range(0, 1))         = 0.2

        [Space(5)]
        [Toggle(_UseRampTex)]_UseRampTex("_UseRampTex", Float) = 0
        _RampTex ("Ramp Tex",2D) = "white"{}
        _RampYRange("Rame Y Range",Range(-1,1)) = 1
        _RampIntensity ("Ramp Intensity",Range(0,1)) = 0.3
        _ShadowColor ("Shadow Color",Color) = (1,1,1,1)
        _RampOffset ("Ramp Offset",RANGE(-1,1)) = 0.1
        _ShadowSmooth ("ShadowSmooth", Range(0,1)) = 0.0
        _ShadowStrength("ShadowStrength", Range(0,1)) = 1.0
		[Space(10)]

        //[Title(Specular)]
        [HDR]_NoseSpecColor	("NoseSpecColor", Color) = (1,1,1,1)
        _NoseSpecSlider("Range:Shadow to Light", Range(0, 1)) = 0
        _NoseSpecMin("NoseSpecMin", float) = 0
        _NoseSpecMax("NoseSpecMax", float) = 0.5

        // Hair Specular
        //[FoldoutBegin(_FoldoutHairSpecEnd)]
        //_FoldoutHairSpec("HairSpec", float) = 0
			[NoScaleOffset]_HairSpecTex	("HairSpecTex", 2D)          			= "black" {}
			[HDR]_BaseSpecColor				("SpecColor", color)					= (0.5, 0.5, 0.5, 0)
            _AnisotropicSlide			("AnisotropicSlide", Range(-0.5, 0.5))	= 0.3
			_AnisotropicOffset			("AnisotropicOffset", Range(-1.0, 1.0))	= 0.0
			_BlinnPhongPow				("BlinnPhongPow", Range(1, 50))			= 5
			_SpecMinimum				("SpecMinimum", Range(0, 0.5))			= 0.1
        //[FoldoutEnd]_FoldoutHairSpecEnd("_FoldoutEnd", float) = 0

        [Space(5)]
        _LightMap ("Light Map(for specular :gloss or metal)",2D) = "grey"{}

        [Header(NdotVRimLight)]
        [Space(5)]
        _RimIntensity ("Rim Light Intensity",Range(0,10)) = 8
        _RimRadius ("Rim Light Radius",Range(0,20)) = 0
        _RimColor ("Rim Color",Color) = (1,1,1,1)
        [Header(ScreenSpaceRimLight)]
        _RimLightWidth ("Rim Light Width",Range(0,5)) = 0.2
        _RimOffset("RimOffset",range(0,1)) = 0.5
        _RimThreshold("RimThreshold",range(-1,1)) = 0.5

        [Header(Outline)]
        [Space(5)]
        _OutlineColor("OutLine Color",Color) = (0,0,0,1)
        _OutlineWidth("Outline Width",Range(-1,1)) = 0.1

        [Header(Emission)]
        [Space(5)]
        _EmissionIntensity("Emission Intensity",Range(0,255)) = 1
        [HDR]_EmissionColor("Emission Color",Color) = (1,1,1,1)


        _ScreenOffsetScaleX("ScreenOffsetScaleX", Range(-2, 2)) 		= 1
        _ScreenOffsetScaleY("ScreenOffsetScaleY", Range(-2, 2)) 		= 1
        //[Title(Shadow Caster Stencil)]
        [Enum(UnityEngine.Rendering.Universal.Internal.StencilUsage)]_FriStencil("Stencil ID", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_FriStencilComp("Stencil Comparison", Float) = 6
        [Enum(UnityEngine.Rendering.StencilOp)]_FriStencilOp("Stencil Operation", Float) = 0
        [Enum(UnityEngine.Rendering.Universal.Internal.StencilUsage)]_FriStencilWriteMask("Stencil Write Mask", Float) = 0
        [Enum(UnityEngine.Rendering.Universal.Internal.StencilUsage)]_FriStencilReadMask("Stencil Read Mask", Float) = 0
        _FriColorMask("Color Mask", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }
        LOD 100

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
        

        #pragma target 4.5
        // GPU Instancing
        #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        //#include_with_pragmas "Packages/com.unity.render-pipelines.danbaidong/ShaderLibrary/DOTS.hlsl"

        #pragma shader_feature _SHADERENUM_PBR_BASE _SHADERENUM_FACE _SHADERENUM_HAIR _SHADERENUM_CLOTH _SHADERENUM_EYE

        // Material Keywords
        //#pragma shader_feature_local_fragment _UseRampTex
        #pragma shader_feature_local _UseRampTex
        #pragma shader_feature_local _INDIRECT_CUBEMAP
        #pragma shader_feature_local _USE_NORMALTEX
        #pragma shader_feature_local _ONLY_INDIRECT
         #pragma shader_feature_local _ONLY_DIRECT

        // Universal Pipeline keywords
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

    
        #pragma vertex vert
        #pragma fragment frag

        CBUFFER_START(UnityPerMaterial) //缓冲区
        float4 _MainTex_ST;

        //Ramp
        uniform float _RampYRange;
        uniform float _RampIntensity;

        uniform float _RampOffset;
        uniform float4 _ShadowColor;
        uniform float _ShadowSmooth;
        uniform float _ShadowStrength;

        //RimLight
        uniform float _RimIntensity;
        uniform float _RimRadius;

        uniform float _RimLightWidth;
        uniform float _RimLightSNBlend;
        uniform float4 _RimColor;
        half _RimOffset;
        half _RimThreshold;

        //Emission
        uniform float _EmissionIntensity;
        uniform float4 _EmissionColor;

        //Sihouetting
        uniform float4 _OutlineColor;
        uniform float _OutlineWidth;

        // PBR
        uniform float _AO;
        uniform float _DirectOcclusion;
        uniform float _Metallic;
        uniform float _Roughness;
        uniform float _NormalScale;

        // Indirect 
        uniform float _IndirectSpecLerp;
        uniform float4 _EnvironmentColor;

        //Noise 
        // Specular
        half4 	_NoseSpecColor;
        half	_NoseSpecMin;
        half	_NoseSpecMax;
        half3 _NoseSpecular;//TODO:temp for storing specular

        // HairSpec
        half4 _BaseSpecColor;
        half _AnisotropicSlide;
        half _AnisotropicOffset;
        half _BlinnPhongPow;
        half _SpecMinimum;

        //Eye parallax
        half _ParallaxScale;
        half _ParallaxMaskEdge;
        half _ParallaxMaskEdgeOffset;
        CBUFFER_END


        TEXTURE2D(_MainTex);        //要注意在CG中只声明了采样器 sampler2D _MainTex,
        SAMPLER(sampler_MainTex); //而在HLSL中除了采样器还有纹理对象，分成了两部分
        TEXTURE2D(_LightMap);     
        SAMPLER(sampler_LightMap);
        TEXTURE2D(_RampTex);     
        SAMPLER(sampler_RampTex);
        TEXTURE2D(_NormalTex);     
        SAMPLER(sampler_NormalTex);
        TEXTURE2D(_EmissionTex);     
        SAMPLER(sampler_EmissionTex);
        TEXTURE2D(_MaskTex);     
        SAMPLER(sampler_MaskTex);

        TEXTURECUBE(_IndirSpecCubemap);
        TEXTURE2D(_IndirSpecMatcap);
        SAMPLER(sampler_IndirSpecMatcap);

        TEXTURE2D(_FaceLightMap);     
        SAMPLER(sampler_FaceLightMap);

        TEXTURE2D(_HairSpecTex);
        SAMPLER(sampler_LinearClamp);

        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 uv : TEXCOORD0;
            float4 tangent : TANGENT;
            float4 vertexColor: COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID 
        };
        struct VertexOutput //输出结构
        {
            float4 pos : SV_POSITION; // Clip Space Pos,这个语义通常用于输出顶点的裁剪空间位置，指示顶点的最终屏幕空间位置
            float4 uv : TEXCOORD0;
            float4 vertexColor: COLOR;
            float3 nDirWS : TEXCOORD1;
            float3 nDirVS : TEXCOORD2;
            float3 vDirWS : TEXCOORD3;
            float3 worldPos : TEXCOORD4;
            float3 lightDirWS : TEXCOORD5;
            float4 positionSS : TEXCOORD6;
            float3 tangentDirWS : TANGENT;
            float clipW : TEXCOORD7;

            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };


        #include "PBRLibrary.hlsl"//TODO: location is important

        //from: https://zhuanlan.zhihu.com/p/95986273
        float sigmoid(float x, float center, float sharp) {
		    float s;
		    s = 1 / (1 + pow(100000, (-3 * sharp * (x - center))));
		    return s;   
	    }

        half4 SampleDirectShadowRamp(TEXTURE2D_PARAM(RampTex, RampSampler), float lightRange)
        {
            float2 shadowRampUV = float2(lightRange, 0.125);
            half4 shadowRampCol = SAMPLE_TEXTURE2D(RampTex, RampSampler, shadowRampUV);
            return shadowRampCol;
        }

        float3 GetAdditionalLightResult(half3 V,half3 N,CustomBRDFData brdfData,float3 posWS)
        {
            float roughness = brdfData.roughness;
            float albedo = brdfData.albedo;
            
            // 次级光源（Additional light）
            float3 additionalDiffColor = 0;
            float3 additionalSpecColor = 0;
            #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    // Prepare Vectors
                    Light light = GetAdditionalLight(lightIndex, posWS);
                    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                    half3 L = light.direction;

                    float3 H = normalize(L + V);
                    float NdotH = saturate(dot(N,H));
                    float NdotL = saturate(dot(N,L));
                    
                    //diffuse: base lambert
                    additionalDiffColor += NdotL * attenuatedLightColor;
                    
                    //specular: 
                    additionalSpecColor += DistributionGGX(N,H,roughness) * attenuatedLightColor * NdotL;
                }
            #endif
            float3 addLightResult = additionalDiffColor * albedo + additionalSpecColor;
            return addLightResult;
        }

        // SDF Face
        float NPRSDF_Face(float4 baseColor,float3 lightDirWS,float2 uv1)
        {
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
            float4 faceLightMap = SAMPLE_TEXTURE2D(_FaceLightMap,sampler_FaceLightMap,uv1);

            //阴影贴图左右正反切换
            float faceShadow = lerp(1- faceLightMap.g, 1 - faceLightMap.r, switchShadow);

            //脸部阴影切换的阈值
            float FaceShadowRange = dot(normalize(Front.xz), normalize(lightDirWS.xz));
            //使用阈值来计算阴影 _FaceShadowOffset
            float lightAttenuation = 1 - smoothstep(FaceShadowRange - 0.05,
                FaceShadowRange + 0.05, faceShadow);

            //float faceShadow = step(lightAtten, faceLightMap.r);
            float2 faceDotLight = float2(dot(normalize(Right.xz), lightDirWS.xz),FaceShadowRange);
            // Nose Specular
            float faceSpecStep = clamp(faceDotLight.y, 0.001, 0.999);
            float noseSpecArea1 = step(faceSpecStep, faceLightMap.g);
            float noseSpecArea2 = step(1 - faceSpecStep, faceLightMap.b);
            float noseSpecArea = noseSpecArea1 * noseSpecArea2 * smoothstep(_NoseSpecMin, _NoseSpecMax, 1 - faceDotLight.y);
            half3 noseSpecColor = _NoseSpecColor.rgb * _NoseSpecColor.a * noseSpecArea;
            _NoseSpecular = noseSpecColor;

            return lightAttenuation;
        }

        float3 NPR_SimpleRimLight(float ndotV,float ndotL,float3 albedo)
        {
            return (1 - smoothstep(_RimRadius,_RimRadius + 0.03,ndotV)) * _RimIntensity * (1 - (ndotL)) * albedo;
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
            ZWrite On

            HLSLPROGRAM
            VertexOutput vert (VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_TRANSFER_INSTANCE_ID(v,o); 
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                VertexOutput o = (VertexOutput)0; // 新建输出结构
                ZERO_INITIALIZE(VertexOutput, o); //初始化顶点着色器
                o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.uv = v.uv;
                //o.uv = float2(o.uv.x, 1 - o.uv.y);
                o.nDirWS = TransformObjectToWorldDir(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.positionSS = ComputeScreenPos(o.pos);
                o.tangentDirWS = TransformObjectToWorldDir(v.tangent);
                o.vertexColor = v.vertexColor;

                o.clipW = o.pos.w;

                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                //====================================================================
                //==================PREPAREATION FOR COMPUTE==========================
                Light mainLight = GetMainLight();
                //Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.worldPos));

                float3 nDirWS = normalize(i.nDirWS);
                //float3 lightColor = mainLight.color;
                float3 lightDirWS = normalize(mainLight.direction);
                float3 vDirWS = normalize(GetCameraPositionWS().xyz - i.worldPos);
                float3 halfDirWS = normalize(lightDirWS + vDirWS);
                float3 tangentDirWS = normalize(i.tangentDirWS);
                float3 bitangentWS = normalize(cross(nDirWS.xyz, i.tangentDirWS.xyz));

                // Normal贴图
                half4 normalTex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv.xy);
                half3 normalTS = UnpackNormalScale(normalTex, _NormalScale);
                normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
                float3x3 T2W = { tangentDirWS, bitangentWS.xyz, nDirWS };
                T2W = transpose(T2W);
                half3 N = NormalizeNormalPerPixel(mul(T2W, normalTS));
                //TODO:TEMP
                #if _USE_NORMALTEX
                nDirWS = N;
                #endif

                //保存context
                //LightingContext context = InitLightingContext(nDirWS,lightDirWS,nDirSS);

                //prepare dot product
                float ndotL = max(0,dot(nDirWS,lightDirWS)); 
                float ndotH = max(0,dot(nDirWS,halfDirWS));
                float ndotV = saturate(dot(nDirWS,vDirWS));
                float hdotT = max(dot(halfDirWS,tangentDirWS),0); //切线点乘半角
                float halfLambert = dot(nDirWS,lightDirWS) * 0.5 + 0.5;

                //prepare pbr texture
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,i.uv.xy);
                float4 rampColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halfLambert, _RampYRange));

                half3 emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, i.uv.xy).rgb;
                half3 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.xy).rgb;
                // Girls Frontline2 少前rmo贴图 roughness,metallic,occlusion
                lightMap.rgb = mask;// TODO:to be removed

                emission = 1 - baseColor.r; //TODO: Temp
                half smoothness = 1 - mask.r;
                half metallic = mask.g * _Metallic;//lerp(1, mask.g, _AO);
                half ao = mask.b * _AO; // occlusion
                half directOcclusion  	= lerp(1 - _DirectOcclusion, 1, mask.b);
                half roughness = (1 - smoothness) * _Roughness;

                
                //==================Start Computing=====================                
                halfLambert = dot(N,lightDirWS) * 0.5 + 0.5; 
                // NPR diffuse
                float shadowArea = sigmoid(1 - halfLambert, _RampOffset, _ShadowSmooth * 10) * _ShadowStrength;
                half3 shadowRamp = lerp(1, _ShadowColor.rgb, shadowArea);

                //Remap NdotL for PBR Spec
                half specArea = 1 - shadowArea;
                #if _UseRampTex
                    shadowRamp = SampleDirectShadowRamp(TEXTURE2D_ARGS(_RampTex, sampler_RampTex), specArea);
                    //rampColor = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(halfLambert,halfLambert));
                    //shadowRamp *= rampColor;
                #endif

                Light light=GetMainLight();
                float3 worldLightDir= light.direction;
                float3 reflectDir=normalize(reflect(-worldLightDir,i.nDirWS));

                //half4 envCol = texCUBE(_CubeMap, reflectDir);
                //half3 envHDRCol = DecodeHDREnvironment(envCol, unity_SpecCube0_HDR);
                
                float3 extraSpecular = float3(0,0,0);
                _NoseSpecular = half3(0,0,0);
                float faceSdfFactor = 0.0f;
                #if _SHADERENUM_FACE
                    float faceShadowFactor = NPRSDF_Face(baseColor,lightDirWS,i.uv.zw);
                    //return float4(faceShadowFactor,faceShadowFactor,faceShadowFactor,faceShadowFactor);
                    shadowArea = (faceShadowFactor + _RampOffset)* _ShadowStrength;
                    //shadowArea = smoothstep(faceShadowFactor, _RampOffset, _ShadowSmooth * 10) * _ShadowStrength;
                    //return float4(faceShadowColor,1.0);
                    faceSdfFactor = faceShadowFactor;
                    shadowRamp*=faceShadowFactor;
                #elif _SHADERENUM_CLOTH
                #elif _SHADERENUM_HAIR
                    // Hair Spec
                    float anisotropicOffsetV = - vDirWS.y * _AnisotropicSlide + _AnisotropicOffset;
                    half3 hairSpecTex = SAMPLE_TEXTURE2D(_HairSpecTex, sampler_LinearClamp, float2(i.uv.z, i.uv.w + anisotropicOffsetV));
                    float hairSpecStrength = _SpecMinimum + pow(ndotH, _BlinnPhongPow) * specArea;
                    half3 hairSpecColor = hairSpecTex * _BaseSpecColor * hairSpecStrength;
                    extraSpecular = hairSpecColor;
                #elif _SHADERENUM_EYE
                //TODO:Parallax
                float3 viewDirOS = TransformWorldToObjectDir(vDirWS);
                viewDirOS = normalize(viewDirOS);
                float2 parallaxOffset = viewDirOS.xy;
                parallaxOffset.y *= -1;
                float2 parallaxUV = i.uv + _ParallaxScale * parallaxOffset;
                //parallaxMask
                float2 centerVec = i.uv - float2(0.5, 0.5);
                half centerDist = dot(centerVec, centerVec);
                half parallaxMask = smoothstep(_ParallaxMaskEdge, _ParallaxMaskEdge + _ParallaxMaskEdgeOffset, 1 - centerDist);
                baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, lerp(i.uv, parallaxUV, parallaxMask));
                #endif

                float4 albedo = baseColor;

                float3 nprPart = float3(0,0,0);
                float3 pbrBase = float3(0,0,0);
                float3 tempAdditional = float3(0,0,0);
                
                CustomBRDFData customBRDFData = InitBRDFData(albedo,float3(0,0,0),ao,metallic,roughness,smoothness);
                pbrBase = BasePBR_Light(halfDirWS,lightDirWS,vDirWS,nDirWS,specArea,shadowRamp,customBRDFData,mainLight,_IndirectSpecLerp,extraSpecular,faceSdfFactor);
                tempAdditional = GetAdditionalLightResult(vDirWS,nDirWS,customBRDFData,i.worldPos);


                //============Screen Space Rim Light===================
                // ref: https://zhuanlan.zhihu.com/p/139290492
                float2 screenPos= i.positionSS.xy / i.positionSS.w;

                // 屏幕空间UV(视口坐标)SV_Position
                float2 screenParams01 = float2(i.pos.x/_ScreenParams.x,i.pos.y/_ScreenParams.y);
                float2 offectSamplePos = screenParams01-float2(_RimOffset/i.clipW,0);
                float offcetDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture, offectSamplePos);
                float trueDepth   = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,screenParams01);
                float linear01EyeOffectDepth = Linear01Depth(offcetDepth,_ZBufferParams);
                float linear01EyeTrueDepth = Linear01Depth(trueDepth,_ZBufferParams);
                float depthDiffer = linear01EyeOffectDepth-linear01EyeTrueDepth;
                float rimIntensity = step(_RimThreshold,depthDiffer);
                float4 col = float4(rimIntensity,rimIntensity,rimIntensity,1);

                float3 fresnelRimLight = NPR_SimpleRimLight(ndotV,ndotL,albedo);
                
                //return float4(fresnelRimLight,1.0);
                
                //return float4(col.rgb,1.0);
                half3 emissResult = emission * albedo * _EmissionColor.rgb;

                return float4(pbrBase * directOcclusion + tempAdditional + emissResult + fresnelRimLight,1.0);
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
                // ===========问题提出============
                // 【注】法线变换时，需要注意是否有非统一缩放，顶点几个分量缩放比例不同会导致变形，这时如果使用变换顶点的矩阵来变换法线，法线结果会出错
                // =======以下是推导矩阵 G 来实现法线变换=====
                // 简单推导：
                // 设 1. 从A Space 到 B Space 顶点变换矩阵为 M(A->B) 2. A空间顶点切线为T_a，以此类推
                // 1) T_b = mul(M,T_a)
                // 2）mul(G, N_a) * T_b = 0
                // 将1) 代入2),结果为 3) mul(G, N_a) * mul(M,T_a) = 0 
                // 对 3) 进行变形 4) mul(T(mul(G, N_a)), mul(M,T_a)) = 0 
                // 结果 G = T(I(M)) 时，4) 成立，这个式子是恒成立的，为了减少计算，分为以下情况
                // ===========Conclusion===========
                // 1. G为正交矩阵，可以直接使用顶点变换矩阵变换法线
                // 2. G只包含旋转变换，正交矩阵，直接用
                // 3. G只包含旋转和统一缩放，T(I(M)) = 1/k * M
                // 4. G包含非统一缩放，使用逆转置T(I(M))
                // ================================
                float4 pos = TransformObjectToHClip(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                //将法线变换到NDC空间
                float3 ndcNormal = normalize(mul(UNITY_MATRIX_P,viewNormal.xyz)) * pos.w;// * clamp(pos.w, 0, 1);//clamp(0,1)加上后当相机拉远后会减弱看上去全是黑色描边明显问题，也可以不加

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
                //罪恶装备vertexcolor.a存储了描边宽度
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

        //Depth Only
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

        /*
        Pass
        {
            Name "FaceDepthOnly"
            Tags { "LightMode" = "UniversalForward" }
            
            ColorMask 0
            ZTest LEqual
            ZWrite On
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct a2v
            {
                float4 positionOS: POSITION;
            };
            
            struct v2f
            {
                float4 positionCS: SV_POSITION;
            };
            
            
            v2f vert(a2v v)
            {
                v2f o;
                
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }
            
            half4 frag(v2f i): SV_Target
            {
                return(0, 0, 0, 1);
            }
            ENDHLSL
            
        }*/
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        /*
        // FringeShadowCaster
        Pass
        {
            Name "FringeShadowCaster"

			Tags
            {
                "LightMode" = "GBufferFringeShadowCaster"
            }

			Stencil
			{
				Ref[_FriStencil]
				Comp[_FriStencilComp]
				Pass[_FriStencilOp]
				ReadMask[_FriStencilReadMask]
				WriteMask[_FriStencilWriteMask]
			}

            Cull Back
            ZWrite Off
			ColorMask [_FriColorMask]

            HLSLPROGRAM
			#pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore

			// -------------------------------------
            // Shader Stages
            #pragma vertex FringeShadowCasterVert
            #pragma fragment FringeShadowCasterFrag

			// -------------------------------------
            // Material Keywords


			// -------------------------------------
            // Universal Pipeline keywords

			//--------------------------------------
            // GPU Instancing
			#pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer
            /*#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"*/

			// -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"


            struct FringeShadowCaster_a2v
            {
                float4 vertex   :POSITION;
                float3 normal   :NORMAL;
            };

            struct FringeShadowCaster_v2f
            {
                float4 positionHCS   :SV_POSITION;
            };

			struct FringeShadowCaster_fragOut
			{
				half4 GBuffer0 : SV_Target0;
			};
			float _ScreenOffsetScaleX;
			float _ScreenOffsetScaleY;
            FringeShadowCaster_v2f FringeShadowCasterVert(FringeShadowCaster_a2v v)
            {
                FringeShadowCaster_v2f o;

				Light mainLight = GetMainLight();
				float3 lightDirWS = normalize(mainLight.direction);
				float3 lightDirVS = normalize(TransformWorldToViewDir(lightDirWS));

				// Cam is Upward: let shadow close to face.
				float3 camDirOS = normalize(TransformWorldToObject(GetCameraPositionWS()));
				float camDirFactor = 1 - smoothstep(0.1, 0.9, camDirOS.y);

				float3 positionVS = TransformWorldToView(TransformObjectToWorld(v.vertex));
				
				positionVS.x -= 0.0045 * lightDirVS.x * _ScreenOffsetScaleX;
				positionVS.y -= 0.0075 * _ScreenOffsetScaleY * camDirFactor;
                o.positionHCS = TransformWViewToHClip(positionVS);

                return o;
            }

            FragmentOutput FringeShadowCasterFrag(FringeShadowCaster_v2f i):SV_Target
            {
				FragmentOutput output;
				output.GBuffer0 = half4(0, 0, 0, 0);
				
                return output;
            }

            ENDHLSL
        }

        Pass{
            Name "FringeShadowReceiver"
            Tags
            {
                "LightMode" = "GBufferFringeShadowReceiver"
            }
            Stencil
            {
                    Ref[_FriStencil]//MaterialCharacterLit
                    Comp[_FriStencilComp]//Equal
                    Pass[_FriStencilOp]//Keep
                    ReadMask[_FriStencilReadMask]//MaterialFringeShadow
                    WriteMask[_FriStencilWriteMask]//MaterialFringeShadow
            }
            Cull Back
            ZWrite Off
            ColorMask [_FriColorMask]
        }*/


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
    }

     FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
