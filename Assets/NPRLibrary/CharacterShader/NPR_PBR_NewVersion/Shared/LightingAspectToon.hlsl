// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// This file is intented for you to edit and experiment with different lighting equation.
// Add or edit whatever code you want here

// #pragma once is a safe guard best practice in almost every .hlsl (need Unity2020 or up), 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#pragma once

#include "./ToonCharacterFunc.hlsl"
#include "./LightingToonPBR.hlsl"

half3 ShadeGI(AspectToonSurfaceData surfaceData, AspectToonLightingData lightingData)
{
    // hide 3D feeling by ignoring all detail SH (leaving only the constant SH term)
    // we just want some average envi indirect color only
    half3 averageSH = SampleSH(0);

    // can prevent result becomes completely black if lightprobe was not baked 
    averageSH = max(_IndirectLightDefaultColor,averageSH);

    // occlusion (maximum 50% darken for indirect to prevent result becomes completely black)
    half indirectOcclusion = lerp(1, surfaceData.occlusion, 0.5);
    return averageSH * indirectOcclusion;
}

// Most important part: lighting equation, edit it according to your needs, write whatever you want here, be creative!
// This function will be used by all direct lights (directional/point/spot)
half3 ShadeSingleLight(AspectToonSurfaceData surfaceData, AspectToonLightingData lightingData, Light light,
     bool isAdditionalLight, ToonPBRContext toonPBRContext)
{
    // ---------------Add different Shading Strategies here-------------------------
    // Prepare Surface Data
    half3 albedo = surfaceData.albedo;

    // 光照计算
    // half3 N = lightingData.normalWS;
    // half3 L = light.direction;   
    // half3 V = lightingData.viewDirectionWS;
    // half3 H = normalize(L + V);

    //----------------------------NPR + PBR Part Calculation-----------------------------------
    half3 directLight = ToonPBR_SingleDirectLight(surfaceData, lightingData, light, isAdditionalLight, toonPBRContext);
    //-----------------------------------END----------------------------------------------

    return directLight;
}

half3 ShadeEmission(AspectToonSurfaceData surfaceData, AspectToonLightingData lightingData)
{
    half3 emissionResult = lerp(surfaceData.emission, surfaceData.emission * surfaceData.albedo, _EmissionBaseColorLerp); // optional mul albedo
    return emissionResult;
}

half3 CompositeAllLightResults(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half3 emissionResult, AspectToonSurfaceData surfaceData, AspectToonLightingData lightingData)
{
    // [remember you can write anything here, this is just a simple tutorial method]
    // here we prevent light over bright,
    // while still want to preserve light color's hue
    half3 rawLightSum = max(indirectResult, mainLightResult + additionalLightSumResult); // pick the highest between indirect and direct light
    // 
    return  rawLightSum + emissionResult;
}
