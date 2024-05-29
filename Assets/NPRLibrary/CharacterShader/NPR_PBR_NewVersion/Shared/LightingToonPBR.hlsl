// this is a pbr func file accustomed to toon shading
#pragma once


struct ToonBRDFData
{
    float4 albedo;
    float3 specular;
    float ao;
    float metallic;
    float roughness;
    float smoothness;

    float3 F0;
};

ToonBRDFData InitBRDFData(float4 albedo, float3 specular, float ao, float metallic, float roughness,float smoothness)
{
    ToonBRDFData toonBRDFData;
    // BRDF Data
    toonBRDFData.albedo = albedo;
    toonBRDFData.specular = specular; // initialize in DirectLightPBR
    toonBRDFData.ao = ao;
    toonBRDFData.metallic = metallic;
    toonBRDFData.roughness = roughness;
    toonBRDFData.smoothness = smoothness;
    return toonBRDFData;
}

// 光照计算上下文
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
    float a  = roughness * roughness;
    float roughnessSquare = max(a, HALF_MIN); // custmomed trick
    float a2 = a * a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

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

// 更改ndotl
float GeometrySmith1(float NdotL,float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    //float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// 直接光：directional light/ spot light/ point light/ ambient light
half3 DirectPBR(half3 albedo, half metallic, half roughness, half3 N, half3 H, half3 L, half3 V, half F0,
    float attenuation, float3 radiance)
{
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

//---------------------------Indirect START-----------------------------------
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
    // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行，为4 次方，这里 5 次方
    return lerp(F0, GrazingTSection, fre) * SurReduction;
}
//---------------------------END Indirect-----------------------------------


// Indirect Light PBR
float4 IndirectLightPBR(AspectToonSurfaceData surfaceData, AspectToonLightingData lightingData, ToonPBRContext toonPBRContext,
    float indirectSpecLerp)
{
    // Prepare Context
    half albedo = surfaceData.albedo;
    half metallic = surfaceData.metallic;
    half roughness = surfaceData.roughness;
    half AO = surfaceData.occlusion;

    float3 F0 = toonPBRContext.F0;
    float3 specular = toonPBRContext.specular;

    half3 N = lightingData.normalWS;
    half3 V = lightingData.viewDirectionWS;
    half NdotV = saturate(dot(N,V)) + _NdotVOffset; 

    //================Indirect diffuse===================
    // Sphererical Harmonics 球谐函数求环境光照；（另外有prefilter diffuse cubemap的方法）
    // ref: https://zhuanlan.zhihu.com/p/144910975
    // 最小化实时计算开销的方法
    // 这里需要外加一个环境光变量让SHColor本身更亮一些
    float3 SHNormal = lerp(N, float3(0,1,0), 0.6);
	float3 SHColor = SampleSH(SHNormal);
    float3 envColor = lerp(SHColor, _EnvironmentColor.rgb, _EnvironmentColor.a);

    // another shColor
    //half3 shColor = SH_IndirectionDiff(N) * AO;
    half3 indirect_KS = Indirect_F_Function(NdotV, F0, roughness);// schlick fresnel
    half3 indirect_KD = (1 - indirect_KS) * (1 - metallic);
    half3 indirectDiffColor = indirect_KD * albedo * envColor * AO;//补充的环境光很关键，不然颜色会很浅


    //================Indirect specular==================
    // 反射探针的间接光
    half3 indirectSpeCubeColor = IndirectSpeCube(N, V, roughness, AO);
    half3 indirectSpeCubeFactor = IndirectSpeFactor(roughness, 1 - roughness, specular, F0, NdotV);
    half3 indirectSpeColor = indirectSpeCubeColor * indirectSpeCubeFactor;

    // Custom Cubemap or Matcap
    half3 additionalIndirSpec = 0;
    #if _INDIRECT_CUBEMAP // Additional cubemap
        float3 reflectDirWS = reflect(-V, N);
        roughness = roughness * (1.7 - 0.7 * roughness);
        float mipLevel= roughness * 6;
        additionalIndirSpec = SAMPLE_TEXTURECUBE_LOD(_IndirSpecCubemap, sampler_LinearRepeat, reflectDirWS, mipLevel);
    #elif _INDIR_MATCAP // Additional matcap
        float3 normalVS = TransformWorldToViewNormal(normalWS);
        normalVS = SafeNormalize(normalVS);
        float2 matcapUV = (normalVS.xy * _IndirSpecMatcapTile) * 0.5 + 0.5;
        additionalIndirSpec = SAMPLE_TEXTURE2D(_IndirSpecMatcap, sampler_IndirSpecMatcap, matcapUV);
    #endif /* _INDIR_CUBEMAP _INDIR_MATCAP */
    // or reflection probe...
    // 如果没有反射探针，直接就返回Custom Cubemap
    //return float4(additionalIndirSpec,1.0);
    indirectSpeColor = lerp(indirectSpeColor, additionalIndirSpec, indirectSpecLerp) * indirectSpeCubeFactor;
    // //Specular IBL(基于图像的光照)
    // float3 indirSpeCubeColor=IndirSpeCube(normalWS,viewDirWS,roughness,occlusion);// prefilterMap => specCube_0
    // float2 envBRDF = SAMPLE_TEXTURE2D(_IblBrdfLut, sampler_IblBrdfLut, float2(NdotV, roughness)).xy;
    // float3 indirSpecColor = indirSpeCubeColor * (indirKs * envBRDF.x + envBRDF.y);

    //---------------Indirect Result--------------------

    half3 indirectColor = indirectDiffColor * _IndirectDiffIntensity + indirectSpeColor * _IndirectSpecIntensity;
    return half4(indirectColor, 1);

}

// indirect diffuse,seperate func
/*float3 IndirectDiffuse(float3 normalWS, half upDirLerp, half4 selfEnvColor, half3 albedo, float3 F0, float NdotV, float roughness, float metallic, float occlusion)
{
    float3 SHNormal = lerp(lightingData.normalWS, float3(0,1,0), upDirLerp);
	float3 SHColor = SampleSH(SHNormal);
    float3 envColor = lerp(SHColor, selfEnvColor.rgb, selfEnvColor.a);
	
	float3 indirKs = fresnelSchlickIndirect(NdotV, F0, roughness);
	float3 indirKd = (1 - indirKs) * (1 - metallic);
	float3 indirDiffColor = envColor * indirKd * albedo * occlusion;

    return indirDiffColor;
}*/


// Direct Light + Indirect Light
float3 ToonPBR_SingleDirectLight(AspectToonSurfaceData surfaceData, AspectToonLightingData lightingData, Light light,
    bool isAdditionalLight, ToonPBRContext toonPBRContext)
{  
    // ---------------------Prepare Part------------------------------
    // Prepare BRDF Data: this is the same as AspectToonSurfaceData in ToonLitBase.cs, but we use a new struct to store data here.
    half3 albedo = surfaceData.albedo;
    half metallic = surfaceData.metallic;
    half roughness = surfaceData.roughness;
    half directOcclusion = lerp(1 - _DirectOcclusion, 1, surfaceData.occlusion);

    // Prepare LightingData
    half3 N = lightingData.normalWS;
    half3 L = light.direction;
    half3 V = lightingData.viewDirectionWS;
    half3 H = normalize(L + V);

    half NdotL = dot(N,L);
    half NdotV = saturate(dot(N,V));
    NdotV += _NdotVOffset;

    // Prepare Toon PBR Context, a little of ugly code...
    //toonPBRContext.NdotL = NdotL;
    //toonPBRContext.NdotV = NdotV;

    // -------------------- Toon Shading -----------------------------
    // Prepare Toon Rendering Data
    
    // Diffuse
    // Cel shading
    // 最终计算结果用shadowRamp表示阴影(光照)的范围和渐变，多个部分分类讨论
    // 由于参数可变，litArea等同于shadowArea; use smoothstep to get smooth area
    //[#0] simple ver.
    //half shadowArea = smoothstep(_CelShadeMidPoint -_ShadowOffset,_CelShadeMidPoint + _ShadowOffset, NdotL);
    //[#1] halflambert
    float halfLambert = NdotL * 0.5 + 0.5; 
    float shadowArea = sigmoid(1 - halfLambert, _ShadowOffset, _ShadowSmooth * 10) * _ShadowStrength;
    //[#2] 简单二分影阴影(simple dichotomy)
    //float isShadow = step(halfLambert,0.5);//光照覆盖区域小的部分强行设置为shadow
    //float3 diffuse = albedo * lerp(_ShadowColor,baseColor,1 - isShadow);
    
    // occlusion
    shadowArea *= surfaceData.occlusion;

    // face ignore celshade since it is usually very ugly using NdotL method
    //shadowArea = _IsFace? lerp(0.5,1,shadowArea) : shadowArea;

    // light's shadow map
    shadowArea *= lerp(1,light.shadowAttenuation,_LightShadowMapAtten);

    // used to add extra specular
     half extraSpecular = 0;
    // shadow ramp calculate
    half3 shadowRamp = 0;
    // 非面部区域没有nose specular
    half3 NoseSpecular = 0;
    // There're some jags with face shadow
    #if _SHADERENUM_FACE
        //float stepFactor = toonPBRContext.sdfFactor > 0 ? 1 : 0.8;
        //Lo = lerp(albedo, albedo * stepFactor, stepFactor);
        //return float4(Lo  + NoseSpecular * specArea * albedo,1.0);
        shadowArea = NPRSDF_Face1(albedo, L, toonPBRContext.uv1, toonPBRContext); // 存储了面部shadowArea
        extraSpecular = toonPBRContext.noseSpecular;
    #endif

    // customed specular 
    // if you have a ilm,you can use it to extract special specular.here we only use non shadow area as specular area or 
    // confirm it with physically based formulas...
    half specArea = 1 - shadowArea;

    half3 shadowColor = lerp(1,_ShadowColor, shadowArea);

    // TODO fix this ugly code, this is for socks shadow texture
    half4 lightMap = GetLightMap(toonPBRContext.uv);

    shadowRamp = shadowColor;

    //half lightAttenuation = 1;

    // light's distance & angle fade for point light & spot light (see GetAdditionalPerObjectLight(...) in Lighting.hlsl)
    // Lighting.hlsl -> https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl
    half distanceAttenuation = min(4,light.distanceAttenuation); //clamp to prevent light over bright if point/spot light too close to vertex

    half3 lightAttenuation = shadowColor * distanceAttenuation;

    // saturate() light.color to prevent over bright
    // additional light reduce intensity since it is additive
    half3 radiance = saturate(light.color) * lightAttenuation * (isAdditionalLight ? 0.25 : 1);

   
    // Shade by different parts of character
    // Face,Skin: npr+pbr
    // Cloth,Weapon: pbr
    // Hair, Fur: pbr
    // Outline
    //[Others] Eyes, Nose, Fringe Shadow, FOV Fix
    // ...
    #if _SHADERENUM_HAIR
        // Hair Spec
        float2 hairUV = toonPBRContext.uv;
        float anisotropicOffsetV = -V.y * _AnisotropicSlide + _AnisotropicOffset;
        half3 hairSpecTex = SAMPLE_TEXTURE2D(_HairSpecTex, sampler_LinearClamp, float2(hairUV.x, hairUV.y + anisotropicOffsetV));
        float hairSpecStrength = _SpecMinimum + pow(saturate(dot(N,H)), _BlinnPhongPow) * specArea;
        half3 hairSpecColor = hairSpecTex * _BaseSpecularColor * hairSpecStrength;
        return (albedo * shadowRamp + (hairSpecColor) * PI * specArea * albedo) * radiance;
    #elif _SHADERENUM_EYE
        // we process eye rendering solely
        // Parallax Eye
        float3 viewDirOS = normalize(TransformWorldToObjectDir(V));
        float2 parallaxOffset = float2(viewDirOS.x, -viewDirOS.y);
        float2 parallaxUV = toonPBRContext.uv + _ParallaxScale * parallaxOffset;

        //parallaxMask
        float2 centerVec = toonPBRContext.uv - float2(0.5, 0.5);
        half centerDist = dot(centerVec, centerVec);
        half parallaxMask = smoothstep(_ParallaxMaskEdge, _ParallaxMaskEdge + _ParallaxMaskEdgeOffset, 1 - centerDist);

        return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, lerp(toonPBRContext.uv, parallaxUV, parallaxMask));;
    #endif


    // --------------------PBR Shading -----------------------------
    // Trick
    // process roughness
    roughness = pow(roughness + 1.0, 2.0) / 8.0;
    surfaceData.roughness = roughness;// fix roughness

    float3 F0 =  float3(0.04, 0.04, 0.04); 
    F0 = lerp(F0, albedo, metallic);
    toonPBRContext.F0 = F0;

    // cook-torrance brdf
    float NDF = DistributionGGX(N, H, roughness);        
    // origin GeometrySmith Func: float G = GeometrySmith(N, V, L, roughness);  
    float G = GeometrySmith1(specArea,N,V,L,roughness);    
    float3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);       

    float3 kS = F;
    float3 kD =  float3(1,1,1) - kS;

    // kD
    kD = kD * 0.5 + 0.5;
    kD *= 1.0 - metallic;     

    // 高光(分子DFG/分母)
    float3 nominator = NDF * G * F;
    //float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001; 
    float denominator = 4.0 * NdotV * max(NdotL, 0.0) * specArea + 0.001; 

    // 直接光高光部分, PBR风格高光
    #if defined(_KALOS_G_FACTOR_ON)
        float3 specular = nominator / (4* max(0,dot(L,H)) + 0.001);
    #else
        float3 specular  = nominator / denominator;
    #endif

    // conbine pbr style with ramp texture
    #if _USE_RAMPTEX
        // diffuse
        shadowRamp = SampleDirectShadowRamp(TEXTURE2D_ARGS(_RampTex, sampler_RampTex), 1 - shadowArea);
        // specular
        float specRange= saturate(NDF * G / denominator);
        half4 specRampCol = SampleDirectSpecularRamp(TEXTURE2D_ARGS(_RampTex, sampler_RampTex), specRange);
        specular = clamp(specRampCol.rgb * 3 + specular * PI / F, 0, 10) * F;// * shadowRamp;
    #endif

    // store specular for indirect calculate
    toonPBRContext.specular = specular;

    //float NdotL = max(dot(N, L), 0.0) + 0.5; // lambert + offset
    // Light output
    float3 Lo = 0;      

    // completely PBR
    //Lo += (kD * albedo / PI + specular) * radiance * NdotL;
    //ref: https://zhuanlan.zhihu.com/p/29837458
    // Li = PI * Lo, PBR中，为了能量守恒，需要对Lambert漫反射除以PI
    // 这里为了整体都能亮起来，则对Lo乘以PI
    specArea = IsSocks?(specArea * lightMap.r):specArea;//lerp(_SkinColor * albedo,albedo,_SocksBaseLerp * lightMap.r)
    // ramp lambert diffuse + ramp Cook-Torrance specular
    // face has no specular...
    Lo += (kD * albedo * shadowRamp + (specular + extraSpecular) * PI * specArea * albedo * (1-_IsFace)) * radiance;
 
    //-----------------Indirect Light Part------------------------
    // 间接光只算一次
    half needCalculate = isAdditionalLight?0:1;
    float4 indirectPBR = needCalculate * IndirectLightPBR(surfaceData, lightingData, toonPBRContext, _IndirectSpecLerp);

    float3 res = 0;
    #if _ONLY_INDIRECT
        res = indirectPBR.rgb;
    #elif _ONLY_DIRECT
        res = Lo;
    #else
        res =  Lo * directOcclusion + indirectPBR.rgb * albedo;
    #endif

    return float4(res,1.0);

}