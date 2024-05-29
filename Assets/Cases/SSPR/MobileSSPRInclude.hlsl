//see README here: https://github.com/ColinLeung-NiloCat/UnityURP-MobileScreenSpacePlanarReflection
#ifndef MobileSSPRInclude
#define MobileSSPRInclude

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

//textures         
TEXTURE2D(_ReflectColor);
sampler LinearClampSampler;

struct ReflectionInput
{
    float3 posWS;
    float4 screenPos;
    float2 screenSpaceNoise;
    float roughness;
    float SSPR_Usage;
	float Opacity;
};
half3 GetResultReflection(ReflectionInput data) 
{ 
    //sample scene's reflection probe
	half3 viewWS = (GetAbsolutePositionWS(data.posWS) - GetAbsolutePositionWS(_WorldSpaceCameraPos));//half3 viewWS = (data.posWS - _WorldSpaceCameraPos);
    viewWS = normalize(viewWS);

    half3 reflectDirWS = viewWS * half3(1,-1,1);//reflect at horizontal plane

    //call this function in Lighting.hlsl-> half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion)
    half3 reflectionProbeResult = GlossyEnvironmentReflection(reflectDirWS,data.roughness,1);               
    half4 SSPRResult = 0;

    half2 screenUV = data.screenPos.xy/data.screenPos.w;
    SSPRResult = SAMPLE_TEXTURE2D(_ReflectColor, LinearClampSampler, screenUV + data.screenSpaceNoise); //use LinearClampSampler to make it blurry

    //final reflection
	half3 finalReflection = lerp(reflectionProbeResult,SSPRResult.rgb, SSPRResult.a * data.SSPR_Usage * data.Opacity);//combine reflection probe and SSPR

	return finalReflection;
}
#endif
