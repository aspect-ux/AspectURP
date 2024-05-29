// functions for toon character rendering
#pragma once

// SDF Face
float NPRSDF_Face(half3 baseColor,half3 lightDirWS,float2 uv1)
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
    float4 faceLightMap = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, uv1);

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

float NPRSDF_Face1(half3 baseColor,half3 lightDirWS,float2 uv1,ToonPBRContext toonPBRContext)
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
    float4 faceLightMap = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, uv1);

    //脸部阴影切换的阈值
    float FaceShadowRange = dot(normalize(Front.xz), normalize(lightDirWS.xz));
    float2 faceDotLight = float2(dot(normalize(Right.xz), lightDirWS.xz),FaceShadowRange);

    half faceSDF = faceLightMap.r;
    half faceShadowArea = faceLightMap.a;

    float faceMapShadow = sigmoid(faceSDF, faceDotLight.y, _ShadowSmooth * 10) * faceShadowArea;
    float shadowArea = (1 - faceMapShadow) * _ShadowStrength;

    // we store Nose Specular to _NoseSpecular Here
    // Nose Specular
    float faceSpecStep = clamp(faceDotLight.y, 0.001, 0.999);
    float noseSpecArea1 = step(faceSpecStep, faceLightMap.g);
    float noseSpecArea2 = step(1 - faceSpecStep, faceLightMap.b);
    float noseSpecArea = noseSpecArea1 * noseSpecArea2 * smoothstep(_NoseSpecMin, _NoseSpecMax, 1 - faceDotLight.y);
    half3 noseSpecColor = _NoseSpecColor.rgb * _NoseSpecColor.a * noseSpecArea;
    toonPBRContext.noseSpecular = noseSpecColor;

    return shadowArea;
}


