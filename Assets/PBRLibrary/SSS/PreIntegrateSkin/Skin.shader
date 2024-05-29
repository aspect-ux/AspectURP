Shader "Unlit/Skin"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
                "RenderType"="Opaque"
            }
            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LitSkinFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

            half _CuvratureOffset;
            TEXTURE2D(_Scattering);       SAMPLER(sampler_Scattering);
            TEXTURE2D(_ScatterLUT);       SAMPLER(sampler_ScatterLUT);

            half3 LightingSkinBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half scatter)
            {
                half NdotL = saturate(dot(normalWS, light.direction));
                float lutU = NdotL * 0.5 + 0.5;
                float lutV = scatter + _CuvratureOffset;
                half3 lut = SAMPLE_TEXTURE2D(_ScatterLUT, sampler_ScatterLUT, float2(lutU, lutV)).rgb;
                half3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation * lut;
                return DirectBDRF(brdfData, normalWS, light.direction, viewDirectionWS) * radiance;
            }
            half4 UniversalSkinPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
                half smoothness, half occlusion, half3 emission, half alpha, half scatter)
            {
                BRDFData brdfData;
                InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

                Light mainLight = GetMainLight(inputData.shadowCoord);
                MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

                half3 color = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
                color += LightingSkinBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, scatter);

            #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
                    color += LightingSkinBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, scatter);
                }
            #endif

            #ifdef _ADDITIONAL_LIGHTS_VERTEX
                color += inputData.vertexLighting * brdfData.diffuse;
            #endif

                color += emission;
                return half4(color, alpha);
            }
            half4 LitSkinFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, surfaceData);

                half scatter = SAMPLE_TEXTURE2D(_Scattering, sampler_Scattering, input.uv);				

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

                half4 color = UniversalSkinPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, 
                    surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha, scatter);

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }
            ENDHLSL
        }
    }
}
