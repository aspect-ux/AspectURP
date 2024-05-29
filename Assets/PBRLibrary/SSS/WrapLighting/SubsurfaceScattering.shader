Shader "AspectURP/Scattering/Subsurface Scattering"
{
	Properties {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular",Color)=(1.0,1.0,1.0,1.0)
        _SpecularPow("Shinness",Range(8,256))=128
        _Wrap("Wrap",Range(0,1))=0.5
        _ScatterWidth("_ScatterWidth",Vector)=(0,0,0,0)
        _ScatterLerp("_ScatterLerp",Range(0,1))=0.75
        _MainTex("MainTex",2D)="white"{}
        _ScatterTex("_ScatterTex",2D)="white"{}
        _EnvRotate ("Environment Color Rotate",Range(0,360)) = 0

        _DepthTexture("Depth Tex",2D) = "white"{}
    }
 
    SubShader {
    	Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }
    	Pass{
            Tags
            {
                "LightMode"="UniversalForward"
                "RenderType"="Opaque"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            // depth normal declare
		    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            #ifndef UNITY_PI
            #define UNITY_PI 3.1415926
            #endif
 
            CBUFFER_START(UnityPerMaterial) //缓冲区
            float4 _MainTex_ST;
            float4 _ScatterTex_ST;

            half4 _Diffuse;
            float _Wrap;
           
            float4 _ScatterWidth;
        	float _ScatterLerp;
        	
       		float4 _Specular;
         	float _SpecularPow;
            CBUFFER_END

            float4x4 _WolrdtoLightMatrix;
            float4x4 _LightVPMatrix;  
            float _CamNearPlane;
            float _CamFarPlane;

            float _EnvRotate;

            sampler2D _ScatterTex;

            TEXTURE2D(_MainTex);        //要注意在CG中只声明了采样器 sampler2D _MainTex,
            SAMPLER(sampler_MainTex); //而在HLSL中除了采样器还有纹理对象，分成了两部分
            TEXTURE2D(_BackDepthTex);        
            SAMPLER(sampler_BackDepthTex);

            TEXTURE2D(_CustomShadowMap);        
            SAMPLER(sampler_CustomShadowMap);

            TEXTURE2D(_DepthTexture);        
            SAMPLER(sampler_DepthTexture);

         	sampler2D _CubeMap;
            float4 _CubeMap_HDR;
         
            struct Varyings {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
                float2 texcoord:TEXCOORD0;
            };
 
            struct Attributes {
                float4 pos : SV_POSITION;
                float4 uv:TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 posWS:TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float4 normalDirVS : TEXCOORD4;
            };
 
            Attributes vert(Varyings v) {
                Attributes o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.normalWS = mul((float3x3)unity_WorldToObject,v.normal);
                o.normalDirVS = mul(UNITY_MATRIX_MV, v.normal);
               
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_ScatterTex);

                // 注意ComputeScreenPos返回的是 裁剪空间的 `齐次`坐标，既不是裁剪空间坐标，也不是NDC坐标，更不是视口坐标
                // 所以需要在片元着色器，先将 `齐次`坐标转换成裁剪空间坐标
                // 简单来说，将坐标数据从 vert传到frag会发生一系列变化，o.screenPos则是经过特殊处理的裁剪空间坐标，使得frag可以直接使用
                o.screenPos = ComputeScreenPos(o.posWS);  
 
                return o;
            }

            
            half4 frag(Attributes i) : SV_Target 
            {
                // ====================思路========================
                // 光照透过物体，传到人眼
                // 核心思路在于d_o - d_i这段距离
                // d_o可以用光照空间的顶点坐标分量z表示
                // d_i则是通过光照贴图(light texture/shadow map)得到入射点与光源的距离
                // 最终通过d_o - d_i求得penetration depth,也有直接用thickness贴图直接替代的
                //==================================================


                // i.screenPos可以看成Clip Space坐标(适用于frag),这个案例用不了
                float2 screenUV = (i.screenPos.xy / i.screenPos.w) * 0.5 + 0.5;  
            
                // 转换为屏幕像素坐标（假设_ScreenParams.xy是屏幕分辨率）  
                //float2 screenPos = screenUV * _ScreenParams.xy;

                //----------------Prepare-------------------------
                Light light = GetMainLight();
                float3 lightDirWS = light.direction; //相对于顶点或者片元的光照方向？

                float3 normalDirWS = normalize(i.normalWS);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
                //----------------Prepare-------------------------


                //--------------Scattering Part,次表面散射---------------
                // 求得光照空间顶点位置
               	float3 posLightSpace = mul(_WolrdtoLightMatrix, i.posWS).z;
                float d_o = length(posLightSpace);

                // 做一下归一化最终得到d_o
                d_o = abs(d_o);
               	d_o = (d_o-_CamNearPlane)/(_CamFarPlane-_CamNearPlane);

                // 将顶点转到光源投影空间，或者说这是以光源为中心的裁剪空间坐标
              	float4 tpos = mul(_LightVPMatrix,i.posWS);

                //TODO:is this a correct screen pos?
              	float4 scrPos = tpos * 0.5f;
				scrPos.xy = float2(scrPos.x, scrPos.y*1) + scrPos.w;
				scrPos.zw = tpos.zw;

                // 这里的screenPos是从lightCamera看去
                // temporarily screen pos
                float4 ndcPos = tpos / tpos.w; // homogeneous division 齐次裁剪
                scrPos = float4(ndcPos.xy * 0.5 + 0.5, ndcPos.z, ndcPos.w);// ndc normalize 设备归一化

                //https://docs.unity.cn/cn/2020.3/Manual/SL-BuiltinMacros.html
                //UNITY_PROJ_COORD： 给定一个 4 分量矢量，此宏返回一个适合投影纹理读取的纹理坐标。在大多数平台上，它直接返回给定值。
                // SAMPLE_DEPTH_TEXTURE得到非线性深度，由于clip/projection matrix的效果，使得其变成非线性
                // 纹理depth = Z(ndc) * 0.5 + 0.5, z(ndc) = z(clip)/w(clip)

                // 这里要注意，采样的深度是lightCamera的,而不是人眼Camera的,_CameraDepthTexture指的是当前相机渲染的Shader的深度
                // tex2Dproj自动齐次除法，输出0-1
                // _CameraDepthTexture  linear01 non-linear depth from screen pos
                // 本案例使用了单独的Depth Shader并渲染线性0-1深度到_DepthTexture，所以直接采样，无需做其它操作
                half existingDepth01 = SAMPLE_DEPTH_TEXTURE(_DepthTexture, sampler_DepthTexture,
			    scrPos.xy).r;

			    //float linear01Depth = LinearEyeDepth(existingDepth01, _ZBufferParams);

                // -use urp declaration headers to get linear01 depth
                //rawDepth = SampleSceneDepth(i.uv);
                // -eyedepth观察深度(真实深度), linearDepth = eyedepth/zfar
                // -这里使用Linear01Depth 而不是LinearEyeDepth
                //float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);

                // view space linear01Depth -> real depth
				//float d_i = -(existingDepth01 * (_CamFarPlane - _CamNearPlane) + _CamNearPlane);
				float d_i = existingDepth01;
 
                // light travel media depth，penetration depth
                // you must put object between viewDirWS with lightDir
				float penetrationDepth = d_o - d_i;

				float3 scattering = exp(-penetrationDepth * _ScatterWidth.xyz);
                //--------------END: Scattering Part,次表面散射---------------
 
                //----------------- Reflection:反射效果 ---------------
                // 采样CubeMap
                float3 reflectDirWS = reflect(-viewDirWS, normalDirWS);

                // 这里将反射向量的xz分量旋转_EnvRotate度
                float theta = _EnvRotate * UNITY_PI / 180;//弧度
                float2x2 rotation = float2x2(cos(theta),-sin(theta),sin(theta),cos(theta));

                float2 reflectXZ = mul(rotation, reflectDirWS.xz);
                reflectDirWS = float3(reflectXZ.x, reflectDirWS.y, reflectXZ.y);
                
                // 采样CubeMap
                //float4 hdrColor = texCube(_CubeMap, reflectDirWS);
                //float4 envColor = DecodeHDR(hdrColor, _CubeMap_HDR);

                // 采样Reflection Probe
                half4 envCol = SAMPLE_TEXTURECUBE(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS);
                half3 envHDRCol = DecodeHDREnvironment(envCol, unity_SpecCube0_HDR);

                // 采样Matcap
                /*half3 viewN = mul(UNITY_MATRIX_V, float4(N, 0)).xyz;
                half2 uv_matcap = viewN.xy * 0.5 + float2(0.5, 0.5);
                half4 matcapColor = SAMPLE_TEXTURE2D(_Matcap, sampler_Matcap, uv_matcap);*/

                // fresnel factor
                float fresnel = 1.0 - max(0,dot(normalDirWS,viewDirWS));
                float3 finalEnvColor = envHDRCol * fresnel;
                //----------------- Reflection ---------------
            	
 
            	float4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
            	half3 albedo = baseColor.rgb * _Diffuse.rgb * _MainLightColor.rgb;
    			half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

  				float3 halfDirWS = normalize(lightDirWS + viewDirWS);
 
                // wrap lighting(环绕光照)
                float wrap = (dot(lightDirWS,normalDirWS)+_Wrap)/(1+_Wrap);
                float wrap_diff = max(0,wrap);
                half3 diffuse = wrap_diff * albedo;
 
                // specular
                float specular = pow(max(0,dot(normalDirWS,halfDirWS)),_SpecularPow) * _MainLightColor.rgb * _Specular.rgb;
 
       			float4 finalColor = float4(0,0,0,0);
 
                // lerp scattering
       			finalColor.rgb = lerp(ambient + diffuse, scattering, _ScatterLerp) + specular;
               	finalColor.a = baseColor.a;

                // no wrap lighting(lambert)
                //diffuse = albedo * max(dot(N,L),0);
                //return float4(ambient+diffuse+specular,1.0);

                // return float4(penetrationDepth.xxx,1);

                //return float4(d_i.xxx,1.0);
                return float4(finalColor.rgb + finalEnvColor,1);
            }
 
            ENDHLSL
        }


        //Depth Only
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}