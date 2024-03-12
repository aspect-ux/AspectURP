#ifndef __TOON_BASE_H__
#define __TOON_BASE_H__
/*
float3 GetRimLight(LitToonContext context, PositionInputs posInput, FragInputs input, float mask = 1)
{
    #ifndef _RIMLIGHT_ENABLE_ON
        return(float3)0;
    #endif
    float3 c = 0;
    
    float luminance = Luminance(context.pointLightColor);
    
    if (_RimLight_Mode == 0)
    {
        float3 rimColor = GetRimLight(context.V, context.N, context.halfLambert, _RimLightLength, _RimLightWidth,
        _RimLightFeather, context.baseColor, _RimLightBlend) * (1 - context.shadowStep) * _RimLightIntensity;// 亮面
        
        float3 rimColor2 = GetRimLight(context.V, context.N, 1 - context.halfLambert, _RimLightLength, _RimLightWidth,
        _RimLightFeather, context.baseColor, _RimLightBlend2) * context.shadowStep * _RimLightIntensity2;// 暗面
        
        rimColor *= lerp(_RimLightColor.rgb, context.pointLightColor, luminance * _RimLightBlendPoint) * mask;
        rimColor2 *= lerp(_RimLightColor2.rgb, context.pointLightColor, luminance * _RimLightBlendPoint2) * mask;
        c = Max3(c, rimColor, rimColor2);
    }
    else
    {
        float2 L_View = normalize(mul((float3x3)UNITY_MATRIX_V, context.L).xy);
        float2 N_View = normalize(mul((float3x3)UNITY_MATRIX_V, context.N).xy);
        float lDotN = saturate(dot(N_View, L_View) + _RimLightLength * 0.1);
        float scale = lDotN * _RimLightWidth * input.color.b * 40 * GetSSRimScale(posInput.linearDepth);
        float2 ssUV1 = clamp(posInput.positionSS + N_View * scale, 0, _ScreenParams.xy - 1);
        
        
        float depthDiff = LinearEyeDepth(LoadCameraDepth(ssUV1), _ZBufferParams) - posInput.linearDepth;
        float intensity = smoothstep(0.24 * _RimLightFeather * posInput.linearDepth, 0.25 * posInput.linearDepth, depthDiff);
        intensity *= lerp(1, _RimLightIntInShadow, context.shadowStep) * _RimLightIntensity * mask;
        
        float3 ssColor = intensity * lerp(1, context.baseColor, _RimLightBlend)
        * lerp(_RimLightColor.rgb, context.pointLightColor, luminance * _RimLightBlendPoint);
        
        c = max(c, ssColor);
    }
    return c;
}*/

#endif