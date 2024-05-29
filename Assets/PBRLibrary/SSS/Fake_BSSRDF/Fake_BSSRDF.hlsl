#ifndef UNIVERSAL_FORWARD_BSDF_PASS_INCLUDED
#define UNIVERSAL_FORWARD_BSDF_PASS_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

float _BackDistortion;
//float _FrontDistortion;
float _FrontInte;
float4 _ScattColor;
TEXTURE2D(_Matcap);        
SAMPLER(sampler_Matcap);
half4 UniversalFragmentPBR(InputData inputData, SurfaceData surfaceData, inout float4 shadowMask)
{
#if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

#if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
#endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
     shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLightLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS);

    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    {
        lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, specularHighlightsOff);
    }

#if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_CLUSTERED_LIGHTING
    for (uint lightIndex = 0; lightIndex < min(_AdditionalLightsDirectionalCount, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    }
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    LIGHT_LOOP_END
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
#endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}


inline float SubsurfaceScattering(float3 vDir,float3 lDir,float3 nDir,float distorion)
{
    float3 backDir = nDir * distorion + lDir;
    backDir = normalize(backDir);
    float result = saturate(dot(vDir, -backDir));
    return result;
    

}

float3 GetEnvColor(float3 viewDirWS,float3 normalDirWS)
{
    //----------------- Reflection:反射效果 ---------------
    float3 finalEnvColor = float3(0,0,0);
    float3 reflectDirWS = reflect(-viewDirWS, normalDirWS);

    // 这里将反射向量的xz分量旋转_EnvRotate度
    // if you want to rotate the env part, uncomment the following code
    //float theta = _EnvRotate * UNITY_PI / 180;//弧度
    //float2x2 rotation = float2x2(cos(theta),-sin(theta),sin(theta),cos(theta));

    //float2 reflectXZ = mul(rotation, reflectDirWS.xz);
    //reflectDirWS = float3(reflectXZ.x, reflectDirWS.y, reflectXZ.y);
    
    // 1. 采样CubeMap
    //float4 hdrColor = texCube(_CubeMap, reflectDirWS);
    //float4 envColor = DecodeHDR(hdrColor, _CubeMap_HDR);

    // 2. 采样Reflection Probe
    float4 envCol = SAMPLE_TEXTURECUBE(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS);
    float3 envHDRCol = DecodeHDREnvironment(envCol, unity_SpecCube0_HDR);

    // 3. 采样Matcap
    //half3 viewN = mul(UNITY_MATRIX_V, float4(normalDirWS, 0)).xyz;
    //half2 uv_matcap = viewN.xy * 0.5 + float2(0.5, 0.5);
    //half4 matcapColor = SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, uv_matcap);

    finalEnvColor = envHDRCol;
    return finalEnvColor;
}

Varyings BSDFPassVertex(Attributes input)
{
    Varyings output = (Varyings) 0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    half fogFactor = 0;
#if !defined(_FOG_FRAGMENT)
    fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
#endif

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
#endif
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
#else
    output.fogFactor = fogFactor;
#endif

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}



half4 BSDFFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if defined(_PARALLAXMAP)
#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = input.viewDirTS;
#else
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
#endif
    ApplyPerPixelDisplacement(viewDirTS, input.uv);
#endif

    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

#ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
#endif
    float4 shadowMask;
    half4 color = UniversalFragmentPBR(inputData, surfaceData);


    Light light = GetMainLight();
    float3 lightDirWS = light.direction;
    float backd = SubsurfaceScattering(inputData.viewDirectionWS, light.direction, inputData.normalWS, _BackDistortion * 10);
    float frontd = SubsurfaceScattering(inputData.viewDirectionWS, -light.direction, inputData.normalWS, _BackDistortion * 10);
    backd = backd + frontd * _FrontInte;
    color.a = OutputAlpha(color.a, _Surface);
   
    float3 sssColor = lerp(float3(0, 0, 0), light.color * _ScattColor, backd);
    color.rgb += sssColor;
    
    // Add Environment Color
    // 使用Reflection Probe计算反射的环境光
    float3 envColor = GetEnvColor(inputData.viewDirectionWS,inputData.normalWS);
    //return float4(envColor,1.0);

    
    color.rgb = MixFog(color.rgb + envColor.rgb, inputData.fogCoord);
    //return float4(sssColor, 1);
    return color;

}




#endif