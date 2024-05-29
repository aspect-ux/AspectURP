// NPR + PBR Shader reference from girls frontline
// description: a npr + pbr shader
// made by aspect-ux

Shader "AspectURP/NPBR_new"
{
    Properties
    {
        [Enum(OFF,0,FRONT,1,BACK,2)] _Cull ("Cull Mode",int) = 1
        [KeywordEnum(Base,Skin,Cloth,Face,Hair,Eye)] _ShaderEnum ("Shader Enum",int) = 0
        _MainTex ("Main Tex", 2D) = "white" {}
        _BaseColor ("Base Color",Color) = (1,1,1,1)

        _IsFace("Hide direct Specular?",Int) = 0 // is skin...
        // TODO skin has no specular now, maybe add sss later or just toon shading

        _Cutoff ("Cutoff", RANGE(0,1)) = 0.5
        [Toggle(_USE_NORMALMAP)]_USE_NORMALMAP("_USE_NORMALMAP", Float) = 0
        _NormalTex ("Normal Tex", 2D) = "white" {}
        _NormalScale ("Normal Scale",Range(0,10)) = 1
        _MaskTex ("Mask Tex", 2D) = "white" {}
        _Metallic ("Metallic",RANGE(0,1)) = 0.01
        _Occlusion ("Ambient Occlusion",RANGE(0,1)) = 0.01
        _DirectOcclusion ("Directional Occlusion",RANGE(0,1)) = 0.1
        _Roughness ("Roughness",RANGE(0,1)) = 0.01

        [Toggle(_ONLY_INDIRECT)]_ONLY_INDIRECT("_ONLY_INDIRECT", Int) = 0
        [Toggle(_ONLY_DIRECT)]_ONLY_DIRECT("_ONLY_DIRECT", Int) = 0

        [Toggle(INDIRECT_CUBEMAP)]_INDIRECT_CUBEMAP("_INDIRECT_CUBEMAP", Int) 		= 0
        [NoScaleOffset]_IndirSpecCubemap("Indirect Specular Cube", cube) 	= "black" {}
        _IndirectSpecLerp ("Indirect Sepcular Lerp",RANGE(0,1)) = 0.1
        _IndirectDiffIntensity("Indirect Diffuse Intensity",Range(0,1)) = 1
        _IndirectSpecIntensity ("Indirect Specular Intensity",Range(0,1)) = 1
        _EnvironmentColor ("Env Color",COLOR) = (1,1,1,1)

        [Space(5)]
        [Header(Parallax)]
        _ParallaxScale("ParallaxScale", Range(0, 1))        = 1.0
        _ParallaxMaskEdge("MaskEdge", Range(0, 1))          = 0.8
        _ParallaxMaskEdgeOffset("MaskEdgeOffset", Range(0, 1))         = 0.2

        [Space(5)]
        [Toggle(USE_RAMPTEX)]_USE_RAMPTEX("_USE_RAMPTEX", Int) = 0
        _RampTex ("Ramp Tex",2D) = "white"{}
        _RampYRange("Rame Y Range",Range(-1,1)) = 1
        _RampIntensity ("Ramp Intensity",Range(0,1)) = 0.3
        _CelShadeMidPoint("_CelShadeMidPoint", Range(-1,1)) = -0.5
        _ShadowColor ("Shadow Color",Color) = (1,1,1,1)
        _ShadowOffset ("Shadow Offset",RANGE(-1,1)) = 0.1
        _ShadowSmooth ("ShadowSmooth", Range(0,1)) = 0.0
        _ShadowStrength("ShadowStrength", Range(0,1)) = 1.0
        _LightShadowMapAtten("Shadow Map Atten",Range(0,1)) = 1.0
		[Space(10)]

        //[Title(Specular)]
        _NdotVOffset("NdotV Offset",Range(-1,1)) = 0
        [HDR]_NoseSpecColor	("NoseSpecColor", Color) = (1,1,1,1)
        _NoseSpecSlider("Nose Spe Slider", Range(0, 1)) = 0
        _NoseSpecMin("NoseSpecMin", float) = 0
        _NoseSpecMax("NoseSpecMax", float) = 0.5

        // Hair Specular
        [NoScaleOffset]_HairSpecTex	("HairSpecTex", 2D)          			= "black" {}
        [HDR]_BaseSpecularColor		("Hair SpecColor", color)					= (0.5, 0.5, 0.5, 0)
        _AnisotropicSlide			("AnisotropicSlide", Range(-0.5, 0.5))	= 0.3
        _AnisotropicOffset			("AnisotropicOffset", Range(-1.0, 1.0))	= 0.0
        _BlinnPhongPow				("BlinnPhongPow", Range(1, 50))			= 5
        _SpecMinimum				("SpecMinimum", Range(0, 0.5))			= 0.1

        [Space(5)]
        [Toggle(UseFaceLightMap)]_USE_FACELIGHTMAP("_USE_FACELIGHTMAP", Float) = 0
        _FaceLightMap("Face Light Map(SDF)",2D) = "white"{}
        [Toggle(USE_LIGHTMAP)]_USE_LIGHTMAP("_USE_LIGHTMAP", Float) = 0
        _LightMap ("Light Map(for specular :gloss or metal)",2D) = "grey"{}
        [Toggle(IsSocks)]IsSocks("IsSocks", Float) = 0
        _SocksBaseLerp("Socks shadow lerp with base color",Range(0,1)) = 1
        _SkinColor("Skin Color",Color) = (1,1,1,1)

        [Header(NdotVRimLight)]
        [Space(5)]
        _RimIntensity ("Rim Light Intensity",Range(0,10)) = 8
        _RimRadius ("Rim Light Radius",Range(0,20)) = 0
        _RimColor ("Rim Color",Color) = (1,1,1,1)
        [Header(ScreenSpaceRimLight)]
        _RimLightWidth ("Rim Light Width",Range(0,5)) = 0.2
        _RimOffset("RimOffset",range(0,1)) = 0.5
        _RimThreshold("RimThreshold",range(-1,1)) = 0.5

        [Header(Outline)]
        [Space(5)]
        _OutlineColor("OutLine Color",Color) = (0,0,0,1)
        _OutlineWidth("Outline Width",Range(-1,1)) = 0.1

        [Header(Emission)]
        [Space(5)]
        _EmissionIntensity("Emission Intensity",Range(0,255)) = 1
        [HDR]_EmissionColor("Emission Color",Color) = (1,1,1,1)


        _ScreenOffsetScaleX("ScreenOffsetScaleX", Range(-2, 2)) 		= 1
        _ScreenOffsetScaleY("ScreenOffsetScaleY", Range(-2, 2)) 		= 1
        //[Title(Shadow Caster Stencil)]
        [Enum(UnityEngine.Rendering.Universal.Internal.StencilUsage)]_FriStencil("Stencil ID", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_FriStencilComp("Stencil Comparison", Float) = 6
        [Enum(UnityEngine.Rendering.StencilOp)]_FriStencilOp("Stencil Operation", Float) = 0
        [Enum(UnityEngine.Rendering.Universal.Internal.StencilUsage)]_FriStencilWriteMask("Stencil Write Mask", Float) = 0
        [Enum(UnityEngine.Rendering.Universal.Internal.StencilUsage)]_FriStencilReadMask("Stencil Read Mask", Float) = 0
        _FriColorMask("Color Mask", Float) = 0
    }
    SubShader
    {
        Tags
        {
            // the tag value is "UniversalPipeline", not "UniversalRenderPipeline", be careful!
            // https://github.com/Unity-Technologies/Graphics/pull/1431/
            "RenderPipeline" = "UniversalPipeline"

            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
        }
        LOD 100

        HLSLINCLUDE
        // all Passes will need this keyword
        #pragma shader_feature_local_fragment _UseAlphaClipping

        // Character use, you cannot delete anyone of them
        //#pragma shader_feature _SHADERENUM_PBR_BASE _SHADOWENUM_SKIN _SHADERENUM_CLOTH _SHADERENUM_FACE _SHADERENUM_HAIR _SHADERENUM_EYE 


        ENDHLSL

        // Pass [ForwardLit], GI,Emission,Fog
        // 相比较内置渲染管线的前向渲染，URP能够以更少的代价渲染大规模光源
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // explict render state to avoid confusion
            // you can expose these render state to material inspector if needed (see URP's Lit.shader)
            Cull [_Cull]
            ZTest LEqual
            ZWrite On
            Blend One Zero

            HLSLPROGRAM

            // Universal Pipeline keywords：接受阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            // Unity defined keywords
            #pragma multi_compile_fog

            // Character Shading Parts
            #pragma shader_feature_local _SHADERENUM_BASE _SHADOWENUM_SKIN _SHADERENUM_CLOTH _SHADERENUM_FACE _SHADERENUM_HAIR _SHADERENUM_EYE

            // Material Keywords
            //#pragma shader_feature_local_fragment _UseRampTex
            #pragma shader_feature_local _USE_NORMALMAP _USE_RAMPTEX _INDIRECT_CUBEMAP _USE_LIGHTMAP
            //#pragma shader_feature_local _USE_FACELIGHTMAP 
            //#pragma shader_feature_local _ONLY_INDIRECT
            //#pragma shader_feature_local _ONLY_DIRECT
           
            #pragma vertex VertexToonLit
            #pragma fragment FragmentToonLit
            #include "./Shared/ToonLitBase.hlsl"
            ENDHLSL
        }

        // [#1 Pass - Outline]
        // Same as the above "ForwardLit" pass, but 
        // -vertex position are pushed out a bit base on normal direction
        // -also color is tinted
        // -Cull Front instead of Cull Back because Cull Front is a must for all extra pass outline method
        Pass 
        {
            Name "Outline"
            Tags 
            {
                // IMPORTANT: don't write this line for any custom pass! else this outline pass will not be rendered by URP!
                //"LightMode" = "UniversalForward" 

                // [Important CPU performance note]
                // If you need to add a custom pass to your shader (outline pass, planar shadow pass, XRay pass when blocked....),
                // (0) Add a new Pass{} to your shader
                // (1) Write "LightMode" = "YourCustomPassTag" inside new Pass's Tags{}
                // (2) Add a new custom RendererFeature(C#) to your renderer,
                // (3) write cmd.DrawRenderers() with ShaderPassName = "YourCustomPassTag"
                // (4) if done correctly, URP will render your new Pass{} for your shader, in a SRP-batcher friendly way (usually in 1 big SRP batch)
                //TODO: SRP Batcher Friendly
                // For tutorial purpose, current everything is just shader files without any C#, so this Outline pass is actually NOT SRP-batcher friendly.
                // If you are working on a project with lots of characters, make sure you use the above method to make Outline pass SRP-batcher friendly!
            }

            Cull Front // Cull Front is a must for extra pass outline method

            HLSLPROGRAM

            // Direct copy all keywords from "ForwardLit" pass
            // ---------------------------------------------------------------------------------------------
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // ---------------------------------------------------------------------------------------------
            #pragma multi_compile_fog
            // ---------------------------------------------------------------------------------------------

            #pragma vertex VertexToonLit
            #pragma fragment FragmentToonLit
            
            // because this is an Outline pass, define "ToonShaderIsOutline" to inject outline related code into both VertexShaderWork() and ShadeFinalColor()
            #define ToonShaderIsOutline

            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "./Shared/ToonLitBase.hlsl"

            ENDHLSL
        }

        /*
        Pass
        {
            Name "Outline"
            Cull Front
            Tags
            {
                // TODO: this code style is not srp-friendly
                //"LightMode"="SRPDefaultUnlit"
                //"RenderType"="Opaque"
            }
   

            HLSLPROGRAM
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                // 1. 普通法线外扩 View Space 也称作三角面扩张法 过程式几何描边
                //float4 pos = mul (UNITY_MATRIX_MV , v.vertex);
                //注意法线空间变换的特殊性
                //float3 normal= mul((float3x3)UNITY_MATRIX_IT_MV, v.normal); 
                //normal.z = -0.5 ; 
                //pos = pos + float4(normalize(normal) , 0) * _OutlineWidth ; 
                //o.pos = mul(UNITY_MATRIX_P , pos);

                // 2. NDC空间法线方向外扩
                // ===========问题提出============
                // 【注】法线变换时，需要注意是否有非统一缩放，顶点几个分量缩放比例不同会导致变形，这时如果使用变换顶点的矩阵来变换法线，法线结果会出错
                // =======以下是推导矩阵 G 来实现法线变换=====
                // 简单推导：
                // 设 1. 从A Space 到 B Space 顶点变换矩阵为 M(A->B) 2. A空间顶点切线为T_a，以此类推
                // 1) T_b = mul(M,T_a)
                // 2）mul(G, N_a) * T_b = 0
                // 将1) 代入2),结果为 3) mul(G, N_a) * mul(M,T_a) = 0 
                // 对 3) 进行变形 4) mul(T(mul(G, N_a)), mul(M,T_a)) = 0 
                // 结果 G = T(I(M)) 时，4) 成立，这个式子是恒成立的，为了减少计算，分为以下情况
                // ===========Conclusion===========
                // 1. G为正交矩阵，可以直接使用顶点变换矩阵变换法线
                // 2. G只包含旋转变换，正交矩阵，直接用
                // 3. G只包含旋转和统一缩放，T(I(M)) = 1/k * M
                // 4. G包含非统一缩放，使用逆转置T(I(M))
                // ================================
                float4 pos = TransformObjectToHClip(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                //将法线变换到NDC空间
                float3 ndcNormal = normalize(mul(UNITY_MATRIX_P,viewNormal.xyz)) * pos.w;// * clamp(pos.w, 0, 1);//clamp(0,1)加上后当相机拉远后会减弱看上去全是黑色描边明显问题，也可以不加

                //将近裁剪面右上角位置的顶点变换到观察空间
                float4 nearUpperRight = mul(unity_CameraInvProjection,
                    float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
            
                //求得屏幕宽高比
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);
                ndcNormal.x *= aspect;
                pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
                o.pos = pos;
               
                // 3. 平滑法线存在tangent中, Object Space外扩
                //罪恶装备strive
                //罪恶装备vertexcolor.a存储了描边宽度
                //v.vertex.xyz += v.tangent.xyz  * _OutlineWidth * 0.01 * v.vertexColor.a;
                //o.pos = TransformObjectToHClip(v.vertex);
                
                return o;
            }
            float4 frag (VertexOutput i) : SV_Target
            {
                return float4(_OutlineColor.rgb,1);
            }
            ENDHLSL
        }*/

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

        //Customed ShadowCaster Pass
        // ShadowCaster pass. Used for rendering URP's shadowmaps
        /*Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            // more explict render state to avoid confusion
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            // the only keywords we need in this pass = _UseAlphaClipping, which is already defined inside the HLSLINCLUDE block
            // (so no need to write any multi_compile or shader_feature in this pass)

            #pragma vertex VertexShaderWork
            #pragma fragment BaseColorAlphaClipTest // we only need to do Clip(), no need shading

            // because it is a ShadowCaster pass, define "ToonShaderApplyShadowBiasFix" to inject "remove shadow mapping artifact" code into VertexShaderWork()
            #define ToonShaderApplyShadowBiasFix

            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "SimpleURPToonLitOutlineExample_Shared.hlsl"

            ENDHLSL
        }*/

        //Depth Only, offscreen depth prepass
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

        /*
        Pass
        {
            Name "FaceDepthOnly"
            Tags { "LightMode" = "UniversalForward" }
            
            ColorMask 0
            ZTest LEqual
            ZWrite On
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct a2v
            {
                float4 positionOS: POSITION;
            };
            
            struct v2f
            {
                float4 positionCS: SV_POSITION;
            };
            
            
            v2f vert(a2v v)
            {
                v2f o;
                
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }
            
            half4 frag(v2f i): SV_Target
            {
                return(0, 0, 0, 1);
            }
            ENDHLSL
            
        }*/
        
        
        
        /*
        // FringeShadowCaster
        Pass
        {
            Name "FringeShadowCaster"

			Tags
            {
                "LightMode" = "GBufferFringeShadowCaster"
            }

			Stencil
			{
				Ref[_FriStencil]
				Comp[_FriStencilComp]
				Pass[_FriStencilOp]
				ReadMask[_FriStencilReadMask]
				WriteMask[_FriStencilWriteMask]
			}

            Cull Back
            ZWrite Off
			ColorMask [_FriColorMask]

            HLSLPROGRAM
			#pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore

			// -------------------------------------
            // Shader Stages
            #pragma vertex FringeShadowCasterVert
            #pragma fragment FringeShadowCasterFrag

			// -------------------------------------
            // Material Keywords


			// -------------------------------------
            // Universal Pipeline keywords

			//--------------------------------------
            // GPU Instancing
			#pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer
            /*#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"*/

			// -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"


            struct FringeShadowCaster_a2v
            {
                float4 vertex   :POSITION;
                float3 normal   :NORMAL;
            };

            struct FringeShadowCaster_v2f
            {
                float4 positionHCS   :SV_POSITION;
            };

			struct FringeShadowCaster_fragOut
			{
				half4 GBuffer0 : SV_Target0;
			};
			float _ScreenOffsetScaleX;
			float _ScreenOffsetScaleY;
            FringeShadowCaster_v2f FringeShadowCasterVert(FringeShadowCaster_a2v v)
            {
                FringeShadowCaster_v2f o;

				Light mainLight = GetMainLight();
				float3 lightDirWS = normalize(mainLight.direction);
				float3 lightDirVS = normalize(TransformWorldToViewDir(lightDirWS));

				// Cam is Upward: let shadow close to face.
				float3 camDirOS = normalize(TransformWorldToObject(GetCameraPositionWS()));
				float camDirFactor = 1 - smoothstep(0.1, 0.9, camDirOS.y);

				float3 positionVS = TransformWorldToView(TransformObjectToWorld(v.vertex));
				
				positionVS.x -= 0.0045 * lightDirVS.x * _ScreenOffsetScaleX;
				positionVS.y -= 0.0075 * _ScreenOffsetScaleY * camDirFactor;
                o.positionHCS = TransformWViewToHClip(positionVS);

                return o;
            }

            FragmentOutput FringeShadowCasterFrag(FringeShadowCaster_v2f i):SV_Target
            {
				FragmentOutput output;
				output.GBuffer0 = half4(0, 0, 0, 0);
				
                return output;
            }

            ENDHLSL
        }

        Pass{
            Name "FringeShadowReceiver"
            Tags
            {
                "LightMode" = "GBufferFringeShadowReceiver"
            }
            Stencil
            {
                    Ref[_FriStencil]//MaterialCharacterLit
                    Comp[_FriStencilComp]//Equal
                    Pass[_FriStencilOp]//Keep
                    ReadMask[_FriStencilReadMask]//MaterialFringeShadow
                    WriteMask[_FriStencilWriteMask]//MaterialFringeShadow
            }
            Cull Back
            ZWrite Off
            ColorMask [_FriColorMask]
        }*/


        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GlossnessINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }
    }

     FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
