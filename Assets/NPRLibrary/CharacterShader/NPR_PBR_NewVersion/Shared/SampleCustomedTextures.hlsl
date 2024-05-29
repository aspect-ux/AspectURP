// you can edit this file to sample your own textures
#pragma once

//TEXTURE2D_ARGS(MainTex, samplerMainTex); 一种宏定义，可以更清楚地组织代码和参数
half4 SampleDirectSpecularRamp(TEXTURE2D_PARAM(RampTex, RampSampler), float specRange)
{
    // 这里使用gf2 中的spa高光贴图
    float2 specRampUV = float2(specRange, _RampYRange);
    half4 specRampCol = SAMPLE_TEXTURE2D(RampTex, RampSampler, specRampUV) * _RampIntensity;
    return specRampCol;
}


half4 SampleDirectShadowRamp(TEXTURE2D_PARAM(RampTex, RampSampler), float lightRange)
{
    float2 shadowRampUV = float2(lightRange, 0.125 + _RampYRange);
    half4 shadowRampCol = SAMPLE_TEXTURE2D(RampTex, RampSampler, shadowRampUV) * _RampIntensity;
    return shadowRampCol;
}


// current case is a replicate of Girls Frontline
// _LightMap
// _MaskTex中RGB 分别为 rmo
half GetMetallicValue(Varyings input)
{
    return SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.uv).g * _Metallic;
}

half GetRoughnessValue(Varyings input)
{
    return SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.uv).r * _Roughness;
}

// GF2 have no lightmap
// but we have a socks addon-texture,so we use this to lighting the socks...
half4 GetLightMap(float2 uv)
{
    //#if _USE_LIGHTMAP
    return SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, uv);
    //#endif
    //return half4(1,1,1,1);
}
/*
half4 GetSpecularMap(float2 uv)
{
    //#if _USE_LIGHTMAP
    return SAMPLE_TEXTURE2D(_SPAMap, sampler_SPAMap, uv);
    //#endif
    //return half4(1,1,1,1);
}
*/
