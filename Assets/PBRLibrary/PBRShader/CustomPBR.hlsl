
#ifndef __ASPECT_PBR_H__
#define __ASPECT_PBR_H__

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define PI 3.1415926

struct a2v
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    float2 lightmapUV : TEXCOORD1;
};
struct v2f
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0; // xy: base map uv, zw: lightmap uv
    float4 normalWS : TEXCOORD1; // w: posWS.x
    float4 tangentWS : TEXCOORD2; // w: posWS.y
    float4 bitangentWS : TEXCOORD3; // w: posWS.z
    float3 positionWS : TEXCOORD4;
};

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
TEXTURE2D(_EmissiveMap); SAMPLER(sampler_EmissiveMap);

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half _Metallic;
half _AO;
half _Roughness;
half _NormalScale;
half _Emissive;
half _EmissiveTwinkleFrequence;
CBUFFER_END

// ============Direct Light Part: directional light/spot light/point light/ambient light =========
//============ Indirect Light Part: extra emission light===============
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
half4 FragPBR(v2f i) : SV_Target
{
    // 采样贴图
    half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy).rgb * _BaseColor.rgb;
    half3 emissive = SAMPLE_TEXTURE2D(_EmissiveMap, sampler_EmissiveMap, i.uv.xy).rgb;
    half3 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy).rgb;
    half metallic = mask.r * _Metallic;
    half ao = lerp(1, mask.g, _AO);
    half smoothness = mask.b;
    half roughness = (1 - smoothness) * _Roughness;
    // Normal贴图
    half4 normalTex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv.xy);
    half3 normalTS = UnpackNormalScale(normalTex, _NormalScale);
    normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
    float3x3 T2W = { i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz };
    T2W = transpose(T2W);
    half3 N = NormalizeNormalPerPixel(mul(T2W, normalTS));

    // 顶点着色器中向量长度一般不会改变，无需normalize,但是片元着色器中向量可能因为插值改变，所以需要规范化
    //float3 N = normalize(i.normalWS);
    float3 V = SafeNormalize(_WorldSpaceCameraPos - i.positionWS);

    float3 F0 =  float3(0.04,0.04,0.04); 
    F0 = lerp(F0, albedo, metallic);

    // reflectance equation
    float3 Lo =  float3(0,0,0);
    // 暂时只有一个主光源
    //for(int i = 0; i < 4; ++i) 
    {
        // calculate per-light radiance
        Light mainLight = GetMainLight();
        half3 L = normalize(mainLight.direction);
        float3 H = normalize(V + L);

        /*
        float distance    = length(mainLight.position - i.positionWS);
        float attenuation = 1.0 / (distance * distance);*/
        float attenuation = mainLight.distanceAttenuation;
        float3 radiance     = mainLight.color * attenuation;        

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
        float3 specular     = nominator / denominator;

        // add to outgoing radiance Lo
        float NdotL = max(dot(N, L), 0.0);                
        Lo += (kD * albedo / PI + specular) * radiance * NdotL; 
    }   

    float3 ambient =  float3(0.03,0.03,0.03) * albedo * ao;
    float3 color = ambient + Lo;

    color = color / (color +  float3(1.0,1.0,1.0));
    color = pow(color,  float3(1.0/2.2,1.0/2.2,1.0/2.2));  
    return float4(color, 1.0); 
}

//======================= From Learnopengl END========================================

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

// 模拟 G项:Kelemen-Szirmay-Kalos Geometry Factor
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

// ========== vert START ===========
v2f vert(a2v i)
{
    v2f o = (v2f)0;
    float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
    o.positionCS = TransformWorldToHClip(positionWS);
    o.uv.xy = TRANSFORM_TEX(i.uv, _BaseMap);
    o.uv.zw = i.lightmapUV;
    o.positionWS = positionWS;
    o.normalWS.xyz = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));
    o.tangentWS.xyz = normalize(TransformObjectToWorldDir(i.tangentOS.xyz));
    o.bitangentWS.xyz = cross(o.normalWS.xyz, o.tangentWS.xyz) * i.tangentOS.w * unity_WorldTransformParams.w;
    o.normalWS.w = positionWS.x;
    o.tangentWS.w = positionWS.y;
    o.bitangentWS.w = positionWS.z;
    return o;
}
// ========== vert END ===========

// ========== frag START ===========
half4 frag(v2f i) : SV_Target
{
    half4 normalTex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv.xy);
    half3 normalTS = UnpackNormalScale(normalTex, _NormalScale);
    normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
    float3x3 T2W = { i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz };
    T2W = transpose(T2W);
    half3 N = NormalizeNormalPerPixel(mul(T2W, normalTS));
    // return half4(N, 1);
    Light mainLight = GetMainLight();
    half3 L = normalize(mainLight.direction);
    // return half4(L, 1);
    float3 positionWS = float3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w);
    half3 V = SafeNormalize(_WorldSpaceCameraPos - positionWS);
    // return half4(V, 1);
    half3 H = normalize(L + V);
    // return half4(H, 1);
    half HdotN = max(dot(H, N), 1e-5);
    half NdotL = max(dot(N, L), 1e-5);
    half NdotV = max(dot(N, V), 1e-5);
    half HdotL = max(dot(H, L), 1e-5);

    // ======= Direct START ======

    half3 albedoTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy).rgb * _BaseColor.rgb;
    half3 emissiveTex = SAMPLE_TEXTURE2D(_EmissiveMap, sampler_EmissiveMap, i.uv.xy).rgb;
    half3 maskTex = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy).rgb;
    half metallic = maskTex.r * _Metallic;
    half AO = lerp(1, maskTex.g, _AO);
    half smoothness = maskTex.b;
    half roughness = (1 - smoothness) * _Roughness;

    // direct specular
    half Direct_D = NormalDistributionFunction(HdotN, roughness);
        //return Direct_D;

    // jave.lin : 使用 Kelemen-Szirmay-Kalos Geometry Factor 优化（可以减少一个 sub G func）
    // 参考：http://renderwonk.com/publications/s2010-shading-course/hoffman/s2010_physically_based_shading_hoffman_b.pdf - 搜索：Kelemen-Szirmay-Kalos Geometry Factor
#if defined(_KALOS_G_FACTOR_ON)
    half Direct_G = Direct_G_Function_Kalos(HdotL, roughness);
#else
    half Direct_G = GeometryFunction(NdotL, NdotV, roughness);
#endif
        //return Direct_G;

    half3 F0 = Direct_F0_Function(albedoTex, metallic);
    //return half4(F0, 1);
    half3 Direct_F = Direct_F_Function(HdotL, F0);
        //return half4(Direct_F, 1);

#if defined(_KALOS_G_FACTOR_ON)
    half3 BRDFSpecSection = (Direct_D * Direct_G) * Direct_F / (4 * HdotL);
#else
    half3 BRDFSpecSection = (Direct_D * Direct_G) * Direct_F / (4 * NdotL * NdotV);
#endif
    //return half4(BRDFSpecSection, 1);

    half3 DirectSpeColor = BRDFSpecSection * mainLight.color * (NdotL * PI * AO);
        //return half4(DirectSpeColor, 1);

    // direct diffuse
    half3 KS = Direct_F;
    half3 KD = (1 - KS) * (1 - metallic);
    // return half4(KD, 1);

    half3 emissionColor = emissiveTex * pow(2, _Emissive);
#if defined(_EMISSIVE_TWINKLE_ON)
emissionColor *= sin(_Time.y * _EmissiveTwinkleFrequence * 10) * 0.5 + 0.5;
#endif
    half3 DirectDiffColor = KD * albedoTex * mainLight.color * NdotL + emissionColor;

    // direct lights
    half3 DirectColor = DirectDiffColor + DirectSpeColor;
    //return half4(DirectColor,1.0);

    // ======= Direct END ======

    // ======= Indirect START ======
    
    // indirect diffuse
    half3 shColor = SH_IndirectionDiff(N) * AO;
    half3 Indirect_KS = Indirect_F_Function(NdotV, F0, roughness);
    half3 Indirect_KD = (1 - Indirect_KS) * (1 - metallic);
    half3 IndirectDiffColor = shColor * Indirect_KD * albedoTex;
    //return half4(IndirectDiffColor, 1); // jave.lin : 添加一个 反射探针 即可看到效果：reflection probe

    // indirect specular

    // 反射探针的间接光
    half3 IndirectSpeCubeColor = IndirectSpeCube(N, V, roughness, AO);
    //return half4(IndirectSpeCubeColor, 1);

    half3 IndirectSpeCubeFactor = IndirectSpeFactor(roughness, smoothness, BRDFSpecSection, F0, NdotV);
        //return half4(IndirectSpeCubeFactor, 1);

    half3 IndirectSpeColor = IndirectSpeCubeColor * IndirectSpeCubeFactor;
    // return half4(IndirectSpeColor, 1);

    half3 IndirectColor = IndirectDiffColor + IndirectSpeColor;
    // return half4(IndirectColor, 1);

    // ======= Indirect END ======

    half3 finalCol = DirectColor + IndirectColor;
    return half4(finalCol, 1);
}
// ========== frag END ===========


#endif
