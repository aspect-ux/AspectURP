#ifndef __HELPERS_H__
#define __HELPERS_H__
float3 fresnel(float cosTheta, float3 R0)
{
    return R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);
}

//利用shlick做近似计算
void fresnel(const float3 I, const float3 N, const float3 ior, inout float kr)
{
    float cosi = clamp(-1, 1, dot(I, N));
    float etai = 1, etat = ior;
    if (cosi > 0)
    {

        float temp = etai;
        etai = etat;
        etat = temp;
    }
    //折射定律
    float sint = etai / etat * sqrt(max(0.f, 1 - cosi * cosi));

    if (sint >= 1)
    {
        kr = 1;
    }
    else
    {
        float cost = sqrt(max(0.f, 1 - sint * sint));
        cosi = abs(cosi);
        float Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost));
        float Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost));
        kr = (Rs * Rs + Rp * Rp) / 2;
    }

}

//-------------------------------------
//- UTILITY

float sdot(float3 x, float3 y, float f = 1.0f)
{
    return saturate(dot(x, y) * f);
}

float energy(float3 color)
{
    return dot(color, 1.0f / 3.0f);
}
//-------------------------------------
//- RANDOMNESS

float2 _Pixel;
float _Seed;

float rand()
{
    float result = frac(sin(_Seed / 100.0f * dot(_Pixel, float2(12.9898f, 78.233f))) * 43758.5453f);
    _Seed += 1.0f;
    return result;
}
/*
//-------------------------------------
//- SAMPLING
float3x3 GetTangentSpace(float3 normal)
{
    // Choose a helper vector for the cross product
    float3 helper = float3(1, 0, 0);
    if (abs(normal.x) > 0.99f)
        helper = float3(0, 0, 1);

    // Generate vectors
    float3 tangent = normalize(cross(normal, helper));
    float3 binormal = normalize(cross(normal, tangent));
    return float3x3(tangent, binormal, normal);
}

float3 SampleHemisphere(float3 normal, float alpha)
{
    // Sample the hemisphere, where alpha determines the kind of the sampling
    float cosTheta = pow(rand(), 1.0f / (alpha + 1.0f));
    float sinTheta = sqrt(1.0f - cosTheta * cosTheta);
    float phi = 2 * PI * rand();
    float3 tangentSpaceDir = float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);

    // Transform direction to world space
    return mul(tangentSpaceDir, GetTangentSpace(normal));
}*/
#endif