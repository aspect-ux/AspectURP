// header file guard, avoid multi include conflict (unty 2020.x +)
#pragma once

// Required by all Universal Render Pipeline shaders.
// It will include Unity built-in shader variables (except the lighting variables)
// (https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
// It will also include many utilitary functions. 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// Include this if you are doing a lit shader. This includes lighting shader variables,
// lighting and shadow functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


#include "./AspectCommonUtils.hlsl"

// app to vertex
struct Attributes
{
    float3 positionOS   : POSITION;
    half3 normalOS      : NORMAL;
    half4 tangentOS     : TANGENT;
    float2 uv           : TEXCOORD0;
};

// vertex shader to fragment shader
struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float4 positionWSAndFogFactor   : TEXCOORD1; // xyz: positionWS, w: vertex fog factor
    half3 normalWS                  : TEXCOORD2;
    half4 tangentWS                 : TEXCOORD3;
    float4 positionCS               : SV_POSITION;
};

///////////////////////////////////////////////////////////////////////////////////////
// CBUFFER and Uniforms 
// (you should put all uniforms of all passes inside this single UnityPerMaterial CBUFFER! else SRP batching is not possible!)
///////////////////////////////////////////////////////////////////////////////////////

// 采用URP内置的声明方式
// all sampler2D don't need to put inside CBUFFER 
//sampler2D _BaseMap; 
//sampler2D _EmissionMap;
//sampler2D _OcclusionMap;
//sampler2D _OutlineZOffsetMaskTex;
TEXTURE2D(_MainTex);        //要注意在CG中只声明了采样器 sampler2D _MainTex,
SAMPLER(sampler_MainTex); //而在HLSL中除了采样器还有纹理对象，分成了两部分
TEXTURE2D(_LightMap);     
SAMPLER(sampler_LightMap);
TEXTURE2D(_RampTex);     
SAMPLER(sampler_RampTex);
TEXTURE2D(_NormalMap);     
SAMPLER(sampler_NormalMap);
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

sampler2D _OutlineZOffsetMaskTex;

// put all your uniforms(usually things inside .shader file's properties{}) inside this CBUFFER, in order to make SRP batcher compatible
// see -> https://blogs.unity3d.com/2019/02/28/srp-batcher-speed-up-your-rendering/
CBUFFER_START(UnityPerMaterial)
    // my code
    // settings
    float _IsFace;

    // base
    float4 _MainTex_ST;
    half4 _BaseColor;

    //Ramp & litorshadow
    float _RampYRange;
    float _RampIntensity;
    float _ShadowOffset;
    float _CelShadeMidPoint;
    float _LightShadowMapAtten;

    //?
    float4 _ShadowColor;
    float _ShadowSmooth;
    float _ShadowStrength;
    float _SocksBaseLerp;
    float IsSocks;
    half4 _SkinColor;

    //Rim light
    float _RimIntensity;
    float _RimRadius;
    float _RimLightWidth;
    float _RimLightSNBlend;
    float4 _RimColor;
    half _RimOffset;
    half _RimThreshold;

    //Emission
    float _EmissionIntensity;
    float4 _EmissionColor;
    half _EmissionBaseColorLerp;

    //Outline
    half4 _OutlineColor;
    float _OutlineWidth;

    float   _OutlineZOffset;
    float   _OutlineZOffsetMaskRemapStart;
    float   _OutlineZOffsetMaskRemapEnd;

    // PBR
    float _Occlusion;
    float _DirectOcclusion;
    float _Metallic;
    float _Roughness;
    float _NormalScale;
    half3 _IndirectLightDefaultColor;

    // Indirect 
    float _IndirectSpecLerp;
    float4 _EnvironmentColor;
    half _IndirectDiffIntensity;
    half _IndirectSpecIntensity;

    // Specular
    half _NdotVOffset;
    half4 _BaseSpecularColor;
    //Nose 
    half4 	_NoseSpecColor;
    half	_NoseSpecMin;
    half	_NoseSpecMax;
    half3 _NoseSpecular;//TODO:temp for storing specular

    // Hair Specular
    half4 _SpecularColor;
    half _AnisotropicSlide;
    half _AnisotropicOffset;
    half _BlinnPhongPow;
    half _SpecMinimum;

    //Eye parallax
    half _ParallaxScale;
    half _ParallaxMaskEdge;
    half _ParallaxMaskEdgeOffset;

    half _Cutoff;

CBUFFER_END

//a special uniform for applyShadowBiasFixToHClipPos() only, it is not a per material uniform, 
//so it is fine to write it outside our UnityPerMaterial CBUFFER
float3 _LightDirection;

// 计算过程中主要有两种数据，一种是用于PBR风格的Surface Data, 一种是正常光照计算的坐标向量数据
struct AspectToonSurfaceData
{
    half3   albedo;
    half    alpha;
    half3   emission;
    half    occlusion;

    // PBR Part
    //#ifdef _PBRFUNC_ON
        half metallic;
        half roughness;
    //#endif
};
struct AspectToonLightingData
{
    half3   normalWS;
    half4   tangentWS;
    float3  positionWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
};

// Customed Context to pass rendering temp data, you can add your own context according to your strategy
struct ToonPBRContext
{
    // Pbr
    float3 specular;
    float3 F0;

    // Toon LitOrShadow Ramp
    float3 faceShadowArea; // area + ramp
    float sdfFactor;
    float3 specAreaRamp;

    float3 shadowArea;

    // nose
    half3 noseSpecular;

    // uv
    float2 uv;
    float2 uv1;

    // in order to calculate lighting easier, here we store some intermediate variables of lightingData Patch
    //half NdotL,NdotH;
};

///////////////////////////////////////////////////////////////////////////////////////
// vertex shared functions
///////////////////////////////////////////////////////////////////////////////////////

// 针对outline单独计算positionWS
float3 TransformPositionWSToOutlinePositionWS(float3 positionWS, float positionVS_Z, float3 normalWS)
{
    // TODO: Outline处理
    //you can replace it to your own method! Here we will write a simple world space method for tutorial reason, it is not the best method!
    float outlineExpandAmount = _OutlineWidth * GetOutlineCameraFovAndDistanceFixMultiplier(positionVS_Z);
    return positionWS + normalWS * outlineExpandAmount; 
}

Varyings VertexToonLit(Attributes input)
{
    Varyings output;

    // VertexPositionInputs contains position in multiple spaces (world, view, homogeneous clip space, ndc)
    // Unity compiler will strip all unused references (say you don't use view space).
    // Therefore there is more flexibility at no additional cost with this struct.
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);

    // Similar to VertexPositionInputs, VertexNormalInputs will contain normal, tangent and bitangent
    // in world space. If not used it will be stripped.
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float3 positionWS = vertexInput.positionWS;
    

#ifdef ToonShaderIsOutline
    positionWS = TransformPositionWSToOutlinePositionWS(vertexInput.positionWS, vertexInput.positionVS.z, vertexNormalInput.normalWS);
#endif

    // Computes fog factor per-vertex.
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    // TRANSFORM_TEX is the same as the old shader library.
    output.uv = TRANSFORM_TEX(input.uv,_MainTex);

    // packing positionWS(xyz) & fog(w) into a vector4
    output.positionWSAndFogFactor = float4(positionWS, fogFactor);
    output.normalWS = vertexNormalInput.normalWS; //normlaized already by GetVertexNormalInputs(...) NormalizeNormalPerVertex(normalInput.normalws);

    real sign = input.tangentOS.w * GetOddNegativeScale();
    // get tangent WS: 在顶点着色器计算TBN一个顶点只用计算一次，消耗小但是效果不够精细，这里传递切线到片元进行计算
    output.tangentWS = half4(vertexNormalInput.tangentWS, sign);


    output.positionCS = TransformWorldToHClip(positionWS);

#ifdef ToonShaderIsOutline
    // [Read ZOffset mask texture]
    // ddx & ddy difference value of neighbors
    // we can't use tex2D() in vertex shader because ddx & ddy is unknown before rasterization, 
    // so use tex2Dlod() with an explict mip level 0, put explict mip level 0 inside the 4th component of param uv)
    float outlineZOffsetMaskTexExplictMipLevel = 0;
    float outlineZOffsetMask = tex2Dlod(_OutlineZOffsetMaskTex, float4(input.uv,0,outlineZOffsetMaskTexExplictMipLevel)).r; //we assume it is a Black/White texture

    // [Remap ZOffset texture value]
    // flip texture read value so default black area = apply ZOffset, because usually outline mask texture are using this format(black = hide outline)
    outlineZOffsetMask = 1-outlineZOffsetMask;
    outlineZOffsetMask = invLerpClamp(_OutlineZOffsetMaskRemapStart,_OutlineZOffsetMaskRemapEnd,outlineZOffsetMask);// allow user to flip value or remap

    // [Apply ZOffset, Use remapped value as ZOffset mask]
    output.positionCS = GetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset * outlineZOffsetMask + 0.03 * _IsFace);
#endif
    
    // TODO: Shadow Part
    // ShadowCaster pass needs special process to positionCS, else shadow artifact will appear
    //--------------------------------------------------------------------------------------
#ifdef ToonShaderApplyShadowBiasFix
    // see GetShadowPositionHClip() in URP/Shaders/ShadowCasterPass.hlsl
    // https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, output.normalWS, _LightDirection));

    #if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    output.positionCS = positionCS;
#endif
    //--------------------------------------------------------------------------------------    

    return output;
}

//Sample Textures
#include "./SampleCustomedTextures.hlsl"


///////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (Step1: prepare data structs for lighting calculation)
///////////////////////////////////////////////////////////////////////////////////////
half4 GetBaseColor(Varyings input)
{
    return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, input.uv) * _BaseColor;
}
half3 SampleNormalMap(Varyings input)
{
    // Normal Mapping
    // Ref: GetVertexNormalInputs
    // Maybe directly pass GetVertexNormalInputs:TBN from vert to frag?  
    // For high quality calculation we calculate tbn in fragment shader
    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap, input.uv),_NormalScale);
    half sgn = input.tangentWS.w;
    half3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    float3x3 TBN = float3x3(input.tangentWS.xyz, bitangent, input.normalWS);

    // use func to translate
    // TODO: i have a problem with mul sequence
    // mul(normalTS, real3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
    return TransformTangentToWorld(normalTS,TBN);
   // return SafeNormalize(TransformTangentToWorld(normalTS,TBN));

}
half3 GetFinalEmissionColor(Varyings input)
{
    half3 result = 0;
    #if _UseEmission
        result = SAMPLE_TEXTURE2D(_EmissionMap,sampler_EmissionMap, input.uv) * _EmissionMapChannelMask * _EmissionColor.rgb;
        return result;
    #endif
    // have no texture, use basecolor.a
    return (1 - GetBaseColor(input).a) * _EmissionColor.rgb * _EmissionColor.a;
}
half GetFinalOcculsion(Varyings input)
{
    half result = 1;
    #if _USE_OCCLUSIONMAP
    #endif
    // 这里以少前2为例，RMO贴图的B通道
    half occlusionBChannel = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex, input.uv).b;
    return lerp(1 - _Occlusion, 1, occlusionBChannel);  

    // TODO: Occlusion
    /*if(_UseOcclusion)
    {
        half4 texValue = tex2D(_OcclusionMap, input.uv);
        half occlusionValue = dot(texValue, _OcclusionMapChannelMask);
        occlusionValue = lerp(1, occlusionValue, _OcclusionStrength);
        occlusionValue = invLerpClamp(_OcclusionRemapStart, _OcclusionRemapEnd, occlusionValue);
        result = occlusionValue;
    }*/

}
void DoClipTestToTargetAlphaValue(half alpha) 
{
#if _UseAlphaClipping
    clip(alpha - _Cutoff);
#endif
}

AspectToonSurfaceData InitializeSurfaceData(Varyings input)
{
    AspectToonSurfaceData output;

    // albedo & alpha
    float4 baseColor = GetBaseColor(input);
    output.albedo = baseColor.rgb;
    output.alpha = baseColor.a;

    // Alpha Test
    DoClipTestToTargetAlphaValue(output.alpha);// early exit if possible

    // emission
    output.emission = GetFinalEmissionColor(input) * output.albedo;

    // occlusion
    output.occlusion = GetFinalOcculsion(input);

    //#ifdef _PBRFUNC_ON
    output.metallic = GetMetallicValue(input);
    output.roughness = GetRoughnessValue(input);
    //#endif

    return output;
}

// Initialize lightData and sample textures for lighting calculation
AspectToonLightingData InitializeLightingData(Varyings input)
{
    AspectToonLightingData lightingData;

    // position & viewDir
    lightingData.positionWS = input.positionWSAndFogFactor.xyz;
    lightingData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);  

    // normal
    #ifdef _USE_NORMALMAP
        lightingData.normalWS = SampleNormalMap(input);
    #else
        lightingData.normalWS = normalize(input.normalWS); //interpolated normal is NOT unit vector, we need to normalize it
    #endif

    return lightingData;
}

ToonPBRContext GetCustomContext(Varyings input)
{
    ToonPBRContext toonPBRContext;

    toonPBRContext.specular = 0;
    toonPBRContext.faceShadowArea = 0;
    //toonPBRContext.shadowArea = 0;
    toonPBRContext.noseSpecular = 0;


    toonPBRContext.uv = input.uv;
    // TODO: need the second uv?
    toonPBRContext.uv1 = input.uv;
    return toonPBRContext;
}

///////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (Step2: calculate lighting & final color)
///////////////////////////////////////////////////////////////////////////////////////

// all lighting equation written inside this .hlsl,
// just by editing this .hlsl can control most of the visual result.
#include "./LightingAspectToon.hlsl"

// this function contains no lighting logic, it just pass lighting results data around
// the job done in this function is "do shadow mapping depth test positionWS offset"
half3 ShadingAllLights(AspectToonSurfaceData surfaceData, AspectToonLightingData lightingData, ToonPBRContext toonPBRContext)
{
    // Indirect lighting, in this case, we set indirectResult = 0,indirect light calculation has been moved into directLight part.
    half3 indirectResult = ShadeGI(surfaceData, lightingData);
    indirectResult = 0;

    //////////////////////////////////////////////////////////////////////////////////
    // Light struct is provided by URP to abstract light shader variables.
    // It contains light's
    // - direction
    // - color
    // - distanceAttenuation 
    // - shadowAttenuation
    //
    // URP take different shading approaches depending on light and platform.
    // You should never reference light shader variables in your shader, instead use the 
    // -GetMainLight()
    // -GetLight()
    // funcitons to fill this Light struct.
    //////////////////////////////////////////////////////////////////////////////////

    //==============================================================================================
    // Main light is the brightest directional light.
    // It is shaded outside the light loop and it has a specific set of variables and shading path
    // so we can be as fast as possible in the case when there's only a single directional light
    // You can pass optionally a shadowCoord. If so, shadowAttenuation will be computed.
    Light mainLight = GetMainLight();

    float3 shadowTestPosWS = lightingData.positionWS + mainLight.direction * (_ShadowOffset + _IsFace);
#ifdef _MAIN_LIGHT_SHADOWS
    // compute the shadow coords in the fragment shader now due to this change
    // https://forum.unity.com/threads/shadow-cascades-weird-since-7-2-0.828453/#post-5516425

    // _ShadowOffset will control the offset the shadow comparsion position, 
    // doing this is usually for hide ugly self shadow for shadow sensitive area like face
    float4 shadowCoord = TransformWorldToShadowCoord(shadowTestPosWS);
    mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
#endif 

    // Main light
    half3 mainLightResult = ShadeSingleLight(surfaceData, lightingData, mainLight, false, toonPBRContext);

    //==============================================================================================
    // All additional lights

    half3 additionalLightSumResult = 0;

#ifdef _ADDITIONAL_LIGHTS
    // Returns the amount of lights affecting the object being renderer.
    // These lights are culled per-object in the forward renderer of URP.
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        // Similar to GetMainLight(), but it takes a for-loop index. This figures out the
        // per-object light index and samples the light buffer accordingly to initialized the
        // Light struct. If ADDITIONAL_LIGHT_CALCULATE_SHADOWS is defined it will also compute shadows.
        int perObjectLightIndex = GetPerObjectLightIndex(i);
        Light light = GetAdditionalPerObjectLight(perObjectLightIndex, lightingData.positionWS); // use original positionWS for lighting
        light.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, shadowTestPosWS); // use offseted positionWS for shadow test

        // Different function used to shade additional lights.
        additionalLightSumResult += ShadeSingleLight(surfaceData, lightingData, light, true, toonPBRContext);
    }
#endif
    //==============================================================================================

    // emission
    half3 emissionResult = ShadeEmission(surfaceData, lightingData);

    return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, surfaceData, lightingData);
}

half3 ConvertSurfaceColorToOutlineColor(half3 originalSurfaceColor)
{
    return originalSurfaceColor * _OutlineColor;
}
half3 ApplyFog(half3 color, Varyings input)
{
    half fogFactor = input.positionWSAndFogFactor.w;
    // Mix the pixel color with fogColor. You can optionaly use MixFogColor to override the fogColor
    // with a custom one.
    color = MixFog(color, fogFactor);

    return color;  
}

// Fragment Shader Func
half4 FragmentToonLit(Varyings input) : SV_TARGET
{
    //////////////////////////////////////////////////////////////////////////////////////////
    // first prepare all data for lighting function
    //////////////////////////////////////////////////////////////////////////////////////////

    // 初始化表面数据
    AspectToonSurfaceData surfaceData = InitializeSurfaceData(input);

    // 初始化光照数据
    AspectToonLightingData lightingData = InitializeLightingData(input);

    // 初始化上下文, this is a editable Patch-oriented context about npr+pbr lightingData, customed texture sampling data also stored here.
    ToonPBRContext toonPBRContext = GetCustomContext(input);
 
    // 计算MainLight + AdditionalLights
    half3 color = ShadingAllLights(surfaceData, lightingData, toonPBRContext);

    // TODO: Outline特殊处理
#ifdef ToonShaderIsOutline
    color = ConvertSurfaceColorToOutlineColor(color);
#endif

    color = ApplyFog(color, input);

    return half4(color, surfaceData.alpha);
}

//////////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (for ShadowCaster pass & DepthOnly pass to use only)
//////////////////////////////////////////////////////////////////////////////////////////
void BaseColorAlphaClipTest(Varyings input)
{
    DoClipTestToTargetAlphaValue(GetBaseColor(input).a);
}

