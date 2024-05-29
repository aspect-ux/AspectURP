Shader "ScreenSpacePlaneReflectionShader"
{
    Properties
    {
        /*[MainColor]*/_BaseColor("BaseColor", Color) = (1,1,1,1)
        /*[MainTexture]*/_BaseMap("BaseMap", 2D) = "white" {}
		_SplatMap("SplatMap", 2D) = "white"{}

        _Roughness("_Roughness", range(0,1)) = 0.25 
        [NoScaleOffset]_SSPR_UVNoiseTex("_SSPR_UVNoiseTex", 2D) = "gray" {}
        _SSPR_NoiseIntensity("_SSPR_NoiseIntensity", range(-0.2,0.2)) = 0.0

        _UV_MoveSpeed("_UV_MoveSpeed (xy only)(for things like water flow)", Vector) = (0,0,0,0)

		_Opacity("_Opacity of plane", range(0.01, 1)) = 1

        [NoScaleOffset]_ReflectionAreaTex("_ReflectionArea", 2D) = "white" {}
    }

    SubShader
    {
		Pass
        {
            //================================================================================================
            //if "LightMode"="SSPR", this shader will only draw if MobileSSPRRendererFeature is on
            Tags { "LightMode"="SSPR" "Queue"="Transparent"}
            //================================================================================================
			//Blend OneMinusDstColor One
			Blend SrcAlpha OneMinusSrcAlpha
        
			HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
			
			#include "./MobileSSPRInclude.hlsl"
            //================================================================================================
            
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //================================================================================================

            struct Attributes
            {
                float4 positionOS   : POSITION;
				half3 normal        : NORMAL;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 screenPos    : TEXCOORD1;
                float3 posWS        : TEXCOORD2;
				float3 normalWS     : TEXCOORD3;
                float4 positionHCS  : SV_POSITION;
            };

            //textures
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            TEXTURE2D(_SSPR_UVNoiseTex);
            SAMPLER(sampler_SSPR_UVNoiseTex);
            TEXTURE2D(_ReflectionAreaTex);
            SAMPLER(sampler_ReflectionAreaTex);

			TEXTURE2D(_SplatMap);
			SAMPLER(sampler_SplatMap);

            //cbuffer
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _SSPR_NoiseIntensity;
            float2 _UV_MoveSpeed;
            half _Roughness;
			float _Opacity;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap) + _Time.y*_UV_MoveSpeed;
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                OUT.posWS = TransformObjectToWorld(IN.positionOS.xyz);
				OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normal));
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            { 
				half3 splat = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap, IN.uv);
				clip(pow(splat.r/4, 3) - 0.0001);

                //base color
                half3 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor.rgb;

                //noise texture
                float2 noise = SAMPLE_TEXTURE2D(_SSPR_UVNoiseTex,sampler_SSPR_UVNoiseTex, IN.uv);
                noise = noise *2-1;
                noise.y = -abs(noise); //hide missing data, only allow offset to valid location
                noise.x *= 0.25;
                noise *= _SSPR_NoiseIntensity;

                //================================================================================================
                //GetResultReflection from SSPR

                ReflectionInput reflectionData;
                reflectionData.posWS = IN.posWS;
                reflectionData.screenPos = IN.screenPos;
                reflectionData.screenSpaceNoise = noise;
                reflectionData.roughness = _Roughness;
                reflectionData.SSPR_Usage = _BaseColor.a;
				reflectionData.Opacity = _Opacity;

				half3 resultReflection = GetResultReflection(reflectionData);
                //================================================================================================

                //decide show reflection area
                half reflectionArea = SAMPLE_TEXTURE2D(_ReflectionAreaTex,sampler_ReflectionAreaTex, IN.uv);

				half3 finalRGB = lerp(baseColor, resultReflection, 1);

				half3 viewWS = (GetAbsolutePositionWS(_WorldSpaceCameraPos) - GetAbsolutePositionWS(IN.posWS));//设置为视角相关，垂直时更加透明
				viewWS = normalize(viewWS);
				half viewOpacity = saturate(0.05 + 0.95*dot(1-viewWS,IN.normalWS)); //垂直为0，平行为1
				half edgeOpacity = pow(splat.b, 3); //边缘透明度+时间过度透明度
				return half4(resultReflection, _Opacity*viewOpacity*edgeOpacity);
            }

            ENDHLSL
        }
    }
}