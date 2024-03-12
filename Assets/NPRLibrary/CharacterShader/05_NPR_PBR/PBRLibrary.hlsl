#ifndef __PBR_LIBRARY_H__
#define __PBR_LIBRARY_H__

struct CustomBRDFData
{
    float4 albedo;
    float3 specular;
    float ao;
    float metallic;
    float roughness;
    float smoothness;

    float3 F0;
};

CustomBRDFData InitBRDFData(float4 albedo, float3 specular, float ao, float metallic, float roughness,float smoothness)
{
    CustomBRDFData customBRDFData;
    // BRDF Data
    customBRDFData.albedo = albedo;
    customBRDFData.specular = specular; // initialize in DirectLightPBR
    customBRDFData.ao = ao;
    customBRDFData.metallic = metallic;
    customBRDFData.roughness = roughness;
    customBRDFData.smoothness = smoothness;
    return customBRDFData;
}

// 世界空间向量上下文
struct LightingContext
{
    // WS Data
    float3 L;
    float3 N;
    float2 SN;

    // SS Data
    float3 posSS;
    float linearDepth;

    // Vertex Data
    float4 vertexColor;
};

LightingContext InitLightingContext(float3 nDirWS,float3 lightDirWS,float3 nDirSS)
{
    LightingContext temp;

    // World Space Data
    temp.L = lightDirWS;
    temp.N = nDirWS;
    temp.SN = nDirSS;

    // Screen Space Data
    //temp.posSS = positionSS;
    //temp.linearDepth = linearDepth;
}

// ====================From Learnopengl Start ==============================
// ======================Cook-Torrance Specular=============================

// F term (Fresnel)
float3 fresnelSchlick(float cosTheta, float3 F0)
{
    // F0 是0度入射反射率(垂直观察反射多少光线)
    // 大多数绝缘体在F0 = 0.4时认为视觉上正确
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}  
// D term (Normal Distribution Function)
float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}
// G term
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}
float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// 直接光：directional light/ spot light/ point light/ ambient light
half3 DirectPBR(half3 albedo, half metallic, half roughness, half3 N, half3 H, half3 L, half3 V, half F0,
    float attenuation, float3 radiance)
{
    // calculate per-light radiance
    //Light mainLight = GetMainLight();
    //half3 L = normalize(mainLight.direction);
    //float3 H = normalize(V + L);

    /*float distance    = length(mainLight.position - i.positionWS);
    float attenuation = 1.0 / (distance * distance);*/
    //float attenuation = mainLight.distanceAttenuation;
    //float3 radiance     = mainLight.color * attenuation;

    // cook-torrance brdf
    float NDF = DistributionGGX(N, H, roughness);        
    float G   = GeometrySmith(N, V, L, roughness);      
    float3 F  = fresnelSchlick(max(dot(H, V), 0.0), F0);       

    float3 kS = F;
    float3 kD =  float3(1,1,1) - kS;
    kD *= 1.0 - metallic;     

    // 高光(分子DFG/分母)
    float3 nominator    = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001; 
    float3 specular   = nominator / denominator;

    // add to outgoing radiance Lo
    float NdotL = max(dot(N, L), 0.0);                

    float3 diffuse = kD * albedo / PI;

    float3 finalColor = (diffuse + specular) * radiance * NdotL;
    return half4(finalColor,1.0);
}
//====================END From Learnopengl Start ==============================

// ========== 直接光照 D项 START =============
// D项 法线微表面分布函数
half NormalDistributionFunction(half NdotH, half roughness)
{
    half a2 = Pow4(roughness);
    half d = (NdotH * NdotH * (a2 - 1.0) + 1.0);
    d = d * d;// *PI;
    return saturate(a2 / d);
}
// G项
inline real Direct_G_subSection(half dot, half k)
{
    return dot / lerp(dot, 1, k);
}
// 几何遮蔽函数
half GeometryFunction(half NdotL, half NdotV, half roughness)
{
    // method1-k:
    // // half k = pow(1 + roughness, 2) / 8.0;

    // // method2-k:
    // const half d = 1.0 / 8.0;
    // half k = pow(1 + roughness, 2) * d;

    // method3-k:
    half k = pow(1 + roughness, 2) * 0.5;
    return Direct_G_subSection(NdotL, k) * Direct_G_subSection(NdotV, k);
}

// G项:Kelemen-Szirmay-Kalos Geometry Factor
// http://renderwonk.com/publications/s2010-shading-course/hoffman/s2010_physically_based_shading_hoffman_b.pdf
// 搜索：Kelemen-Szirmay-Kalos Geometry Factor
inline half Direct_G_Function_Kalos(half LdotH, half roughness)
{
    half k = pow(1 + roughness, 2) * 0.5;
    return Direct_G_subSection(LdotH, k);
}

// F项 菲涅尔方程 Fresnel
// method1:
// 直接光照 F项
half3 Direct_F_Function(half HdotL, half3 F0)
{
    half Fre = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
    return lerp(Fre, 1, F0);
}

// // method2:
// // 直接光照 F项
// half3 Direct_F_Function(half HdotL, half3 F0)
// {
    //     half Fre = pow(1 - HdotL, 5);
    //     return lerp(Fre, 1, F0);
// }
// ========== 直接光照 F项 END =============

// ========== 直接光照 F0 START =============
inline half3 Direct_F0_Function(half3 albedo, half metallic)
{
    return lerp(0.04, albedo, metallic);
}
// ========== 直接光照 F0 END =============


// ========== Direct END =============


// ========== Indirect START =============
real3 SH_IndirectionDiff(real3 normalWS)
{
    return  SampleSH(normalWS);
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;
    real3 color = SampleSH9(SHCoefficients, normalWS);
    return max(0, color);
}

half3 Indirect_F_Function(half NdotV, half3 F0, half roughness)
{
    half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
    return F0 + fre * saturate(1 - roughness - F0);
}

// 使用反射探针的间接高光
half3 IndirectSpeCube(half3 normalWS, half3 viewWS, float roughness, half AO)
{
    half3 reflectDirWS = reflect(-viewWS, normalWS);
    roughness = roughness * (1.7 - 0.7 * roughness); // unity 内部不是线性 调整下 拟合曲线求近似，可以再 GGB 可视化曲线
    half mipmapLevel = roughness * 6; // 把粗糙度 remap 到 0~6 的 7个阶段，然后进行 texture lod 采样
    half4 specularColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, mipmapLevel); // 根据不同的 mipmap level 等级进行采样
    #if !defined(UNITY_USE_NATIVE_HDR)
    // 用 DecodeHDREnvironment 将解码 HDR 颜色值。
    // 可以看到采样出的 RGBM 是一个 4 通道的值
    // 最后的一个 M 存的是一个参数
    // 解码时将前三个通道表示的颜色乘上 x*(M^y)
    // x y 都是有环境贴图定义的系数
    // 存储在 unity_SpecCube0_HDR 这个结构中
    return DecodeHDREnvironment(specularColor, unity_SpecCube0_HDR) * AO;
    #else
    return specularColor.rgb * AO;
    #endif
}

half3 IndirectSpeFactor(half roughness, half smoothness, half3 BRDFspe, half3 F0, half NdotV)
{
    #ifdef UNITY_COLORSPACE_GAMMA
    half SurReduction = 1 - 0.28 * roughness * roughness;
    #else
    half SurReduction = 1 / (roughness * roughness + 1);
    #endif
    #if defined(SHADER_API_GLES) // Lighting.hlsl 261 行
    half Reflectivity = BRDFspe.x;
    #else
    half Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
    #endif
    half GrazingTSection = saturate(Reflectivity + smoothness);
    half fre = Pow4(1 - NdotV); // Lighting.hlsl 第 501 行
    // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行，他是 4 次方，我们是 5 次方
    return lerp(F0, GrazingTSection, fre) * SurReduction;
}

// ========== Indirect END =============


//========================== COMPITE PBR ===============================

half4 SampleDirectSpecularRamp(TEXTURE2D_PARAM(RampTex, RampSampler), float specRange)
{
    float2 specRampUV = float2(specRange, 0.375);
    half4 specRampCol = SAMPLE_TEXTURE2D(RampTex, RampSampler, specRampUV);
    return specRampCol;
}
// Indirect Light PBR
float4 IndirectLightPBR(float3 H,float3 L,float3 V,float3 N,float NdotV,CustomBRDFData brdfData,Light mainLight,float indirectSpecLerp)
{
    // Prepare PBR Data
    float4 albedo = brdfData.albedo;
    float3 specular = brdfData.specular;
    float metallic = brdfData.metallic;
    float roughness = brdfData.roughness;
    float smoothness = brdfData.smoothness;
    float AO = brdfData.ao;
    float3 F0 = brdfData.F0;

    //================Indirect diffuse===================
    // Sphererical Harmonics 球谐函数求环境光照；（另外有prefilter diffuse cubemap的方法）
    // ref: https://zhuanlan.zhihu.com/p/144910975
    // 最小化实时计算开销的方法

    // 这里需要外加一个环境光变量让SHColor本身更亮一些
    float3 SHNormal = lerp(N, float3(0,1,0), 0.6);
	float3 SHColor = SampleSH(SHNormal);
    float3 envColor = lerp(SHColor, _EnvironmentColor.rgb, _EnvironmentColor.a);

    half3 shColor = SH_IndirectionDiff(N) * AO;
    half3 indirect_KS = Indirect_F_Function(NdotV, F0, roughness);
    half3 indirect_KD = (1 - indirect_KS) * (1 - metallic);
    half3 indirectDiffColor = indirect_KD * albedo * envColor;//补充的环境光很关键，不然颜色会很浅

    //return float4(indirectDiffColor,1.0);


    //================Indirect specular==================
    // 反射探针的间接光
    half3 indirectSpeCubeColor = IndirectSpeCube(N, V, roughness, AO);
    half3 indirectSpeCubeFactor = IndirectSpeFactor(roughness, smoothness, specular, F0, NdotV);
    half3 indirectSpeColor = indirectSpeCubeColor * indirectSpeCubeFactor;

    // Custom Cubemap
    half3 additionalIndirSpec = 0;
    #if _INDIRECT_CUBEMAP // Additional cubemap
        float3 reflectDirWS = reflect(-vDirWS, nDirWS);
        roughness = roughness * (1.7 - 0.7 * roughness);
        float mipLevel= roughness * 6;
        additionalIndirSpec = SAMPLE_TEXTURECUBE_LOD(_IndirSpecCubemap, sampler_LinearRepeat, reflectDirWS, mipLevel);
    #endif 
    // 如果没有反射探针，直接就返回Custom Cubemap
    //return float4(additionalIndirSpec,1.0);
    indirectSpeColor = lerp(indirectSpeColor, additionalIndirSpec, indirectSpecLerp) * indirectSpeCubeFactor;


    // //Specular IBL(基于图像的光照)
    // float3 indirSpeCubeColor=IndirSpeCube(normalWS,viewDirWS,roughness,occlusion);// prefilterMap => specCube_0
    // float2 envBRDF = SAMPLE_TEXTURE2D(_IblBrdfLut, sampler_IblBrdfLut, float2(NdotV, roughness)).xy;
    // float3 indirSpecColor = indirSpeCubeColor * (indirKs * envBRDF.x + envBRDF.y);

    //================Indirect Result==================

    half3 indirectColor = indirectDiffColor + indirectSpeColor;

    return half4(indirectColor, 1);

}
// Direct Light + Indirect Light
float4 BasePBR_Light(float3 H,float3 L,float3 V,float3 N,float specAreaRamp,float3 shadowRamp,CustomBRDFData brdfData,Light mainLight,float indirectSpecLerp,float3 extraSpecular,float sdfFactor)
{
    // ===================Main Light PBR Part=======================
    // Prepare BRDF Data
    float4 albedo = brdfData.albedo;
    float metallic = brdfData.metallic;
    float roughness = brdfData.roughness;

    // TODO: Wrap or Remap operation
    roughness = pow(roughness + 1.0, 2.0) / 8.0;


    float3 F0 =  float3(0.04,0.04,0.04); 
    F0 = lerp(F0, albedo, metallic);
    brdfData.F0 = F0;

    float attenuation = mainLight.distanceAttenuation;
    float3 radiance  = mainLight.color * attenuation;  
    // cook-torrance brdf
    float NDF = DistributionGGX(N, H, roughness);        
    float G   = GeometrySmith(N, V, L, roughness);      
    float3 F  = fresnelSchlick(max(dot(H, V), 0.0), F0);       

    float3 kS = F;
    float3 kD =  float3(1,1,1) - kS;
    //TODO: rempap KD
    kD = kD*0.5+0.5;
    kD *= 1.0 - metallic;     

    // 高光(分子DFG/分母)
    float3 nominator    = NDF * G * F;
    //float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001; 
    float denominator = 4.0 * max(dot(N, V), 0.0) * specAreaRamp + 0.001; 

    // 直接光高光部分
    #if defined(_KALOS_G_FACTOR_ON)
        float3 specular = nominator / (4* max(0,dot(L,H)) + 0.001);
    #else
        float3 specular  = nominator / denominator;
    #endif

    // TODO: to be removed
    #if _UseRampTex
        float specRange= saturate(NDF * G / denominator);
        half4 specRampCol = SampleDirectSpecularRamp(TEXTURE2D_ARGS(_RampTex, sampler_RampTex), specRange);
        specular = clamp(specRampCol.rgb * 3 + specular * PI / F, 0, 10) * F * shadowRamp;
        //specular = directSpecColor;
    #endif

    brdfData.specular = specular; // set specular

    //float NdotL = max(dot(N, L), 0.0) +0.5;  lambert + offset

    float3 Lo = 0;      
    
    // completely PBR
    //Lo += (kD * albedo / PI + specular) * radiance * NdotL;

    //ref: https://zhuanlan.zhihu.com/p/29837458
    // Li = PI * Lo, PBR中，为了能量守恒，需要对Lambert漫反射除以PI

    // ramp lambert diffuse + ramp Cook-Torrance specular
    Lo += (kD * albedo / PI * shadowRamp + (specular + _NoseSpecular) * specAreaRamp + extraSpecular) * radiance;

    // There're some jags 适应各个身体部位
    #if _SHADERENUM_FACE
    float stepFactor = sdfFactor > 0 ? 1 : 0.8;
    Lo = lerp(albedo,albedo * stepFactor,stepFactor);
    return float4(Lo + _NoseSpecular * specAreaRamp * albedo,1.0);
    #endif

    // ==================Indirect Light Part========================
    float NdotV = max(0,dot(N,L));
    float4 indirectPBR = IndirectLightPBR(H,L,V,N,NdotV,brdfData,mainLight,indirectSpecLerp);

    float3 res = 0;
    #if _ONLY_INDIRECT
    res = indirectPBR.rgb;
    #elif _ONLY_DIRECT
    res = Lo;
    #else
    res =  Lo + indirectPBR.rgb;
    #endif

    return float4(res,1.0);

}



#endif