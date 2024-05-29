Shader "Test/URP_PBR_Emissive"
{
    Properties
    {
        _BaseColor ("Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Albedo", 2D) = "white" {}
        [NoScaleOffset] _MaskMap ("Mask: Metalic(R), AO(G), Smoothness(B)", 2D) = "black" {}
        [NoScaleOffset] [Normal] _NormalMap ("Normal (RGB)", 2D) = "bump" {}
        [NoScaleOffset] _EmissiveMap ("Emission (RGB)", 2D) = "black" {}
        _Metallic ("Metallic", Range(0, 1)) = 1
        _AO ("AO", Range(0, 1)) = 1
        _Roughness ("Roughness", Range(0, 1)) = 1
        _NormalScale("NormalScale", Range(0, 1)) = 1
        _Emissive ("Emission", Range(0, 100)) = 1
        [Toggle(_EMISSIVE_TWINKLE_ON)] _Emissve_Twinkle("Emissive Twinkle", Int) = 1
        _EmissiveTwinkleFrequence ("Emissive Twinkle Frequence", Range(0, 1)) = 1
        [Toggle(_KALOS_G_FACTOR_ON)] _Kalos_G_Factor ("Optimize with Kalos G Factor", Int) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ _EMISSIVE_TWINKLE_ON
            #pragma shader_feature _ _KALOS_G_FACTOR_ON
            #include "CustomPBR.hlsl"
            ENDHLSL
        }
    }
}

