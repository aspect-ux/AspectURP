// @Author: Aspect-ux
// Refs:
// 1. 曲面细分： https://zhuanlan.zhihu.com/p/42550699
// 2. https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/
// 3  https://zhuanlan.zhihu.com/p/359999755
Shader "AspectURP/SnowShader" 
{
	//============================= A Snow Shader=================================
	// Points:
	// 1. Tessellation 曲面细分分成三个部分(Three Parts)
	//  Hull Shader (Tessellation Control Shader,TCS),用于控制细分
	//  Tessellation Primitive Generator,不可编程
	//  Domain Shader,(Tessellation Shader,TES),用于曲面细分的计算
	// 2. Pipeline
	//    Vertex Shader        -> Tessellation Shader -> Geometry Shader             -> Fragment Shader
	//    确定顶点位置和传递数据 -> 曲面细分            ->  将基本图元转换/生成为其它图元 -> 计算着色
	Properties 
	{
		[Title(Main Textures)]
        [Main(GroupBasic, _KEYWORD, on)] _group1 ("Textures", float) = 1
        [Sub(GroupBasic)] _MainTex ("Main(Groud) Tex", 2D) = "white" {}
		[Sub(GroupBasic)] _MaskTex("Mask(Splatmap)", 2D) = "white"{}
		[Sub(GroupBasic)] _SnowTex ("Snow (RGB)", 2D) = "white" {}
		[Sub(GroupBasic)]_SnowNormal("SnowNormal", 2D) = "bump"{}

		[Title(Tessellation Part)]
		[Main(GroupTES),_KEYWORD,on] _group2 ("Tessellation", float) = 1
		[Sub(GroupTES)]_Tessellation("Tessellation", Range(1,64)) = 4
		[Sub(GroupTES)]_MaxTessDistance("Max Tess Distance", Range(1, 32)) = 20
        [Sub(GroupTES)]_MinTessDistance("Min Tess Distance", Range(1, 32)) = 1
		[Sub(GroupTES)]_Displacement("Displacement", Range(0, 1.0)) = 0.3
		

		[Title(Shading Part)]
		[Main(GroupShade),_KEYWORD,on] _group3 ("Shading", float) = 1
		[Sub(GroupShade)] _SnowColor ("Snow Color", Color) = (1,1,1,1)
		[Sub(GroupShade)]_GroundColor("Ground Color", Color) = (1,1,1,1)
		[Space(5)]
		[Sub(GroupShade)]_Glossiness ("Smoothness", Range(8,256)) = 8
		[Sub(GroupShade)]_Metallic ("Metallic", Range(0,1)) = 0.0
		[Sub(GroupShade)]_SpecColor("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		[Sub(GroupShade)]_FresnelFactor("Fresnel", Range(0, 5)) = 0.1

		[Title(Preset Part)]
        [Main(Preset, _, on, off)] _PresetGroup ("Preset", float) = 0
		[Preset(Preset, LWGUI_BlendModePreset)] _BlendMode ("Blend Mode Preset", float) = 0
		[SubEnum(Preset, UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
		[SubEnum(Preset, UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1
		[SubEnum(Preset, UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 0
		[SubToggle(Preset)] _ZWrite ("ZWrite ", Float) = 1
		[SubEnum(Preset, UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4 // 4 is LEqual
		[SubEnum(Preset, RGBA, 15, RGB, 14)] _ColorMask ("ColorMask", Float) = 15 // 15 is RGBA (binary 1111)
	}
	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
		LOD 300
	
		//URP Tessellation ref: https://zhuanlan.zhihu.com/p/594265500
		Pass
		{

			Name "Snow"
			Tags {"LightMode" = "UniversalForward"}
			//LOD 150
			Cull [_Cull]
			ZWrite [_ZWrite]
			Blend [_SrcBlend] [_DstBlend]
			ColorMask [_ColorMask] // write channels into current pass

			HLSLPROGRAM

			#pragma require tessellation
            #pragma require geometry
			#pragma vertex tessvert // vert has been called by domain shader
			//#pragma vertex vert
			//#pragma require geometry
			//#pragma geometry geom
			#pragma hull hull
			#pragma domain domain
        	#pragma fragment frag

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 4.6


			// Macors
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

			#pragma shader_feature_local _ DISTANCE_DETAIL

			// Headers
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
			//#include "Tessellation.hlsl" // for grass

			// 每材质常量缓冲区，由于该缓冲区在GPU,频繁更改缓冲区性能消耗大，不同物体相同材质属性渲染过程中值保持不变适合放在这里
			CBUFFER_START(UnityPerMaterial)
			half _Glossiness;
			half _Metallic;
			
			float _MaxTessDistance;
            float _MinTessDistance;
			CBUFFER_END

			//TEXTURE2D (_MainTex);//Groud
			//SAMPLER(sampler_MainTex);

			sampler2D _MaskTex; // SplatMap
            sampler2D _SnowTex;
			sampler2D _MainTex;
			sampler2D _SnowNormal;

			float4 _SnowTex_ST;
            float4 _MaskTex_ST;;

			half4 _SnowColor;
			half4 _GroundColor;
			half4 _SpecColor;
			float _Tessellation;
			float _Displacement;
			float _FresnelFactor;

			//为了方便操作 定义预定义
            #define smp SamplerState_Point_Repeat
            // SAMPLER(sampler_MainTex); 默认采样器
            SAMPLER(smp);

			struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;

				float4 tangent : TANGENT;
            };

			// 随着距相机的距离减少细分数
            float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
            {
                float3 worldPosition = TransformObjectToWorld(vertex.xyz);
                float dist = distance(worldPosition,  GetCameraPositionWS());
                float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
                return (f);
            }

			/* Old code
			// [obsoleted]From "Tessellation.cginc"
			float UnityCalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess)
			{
				float3 wpos = mul(UNITY_MATRIX_M,vertex).xyz;
				float dist = distance (wpos, _WorldSpaceCameraPos);
				float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
				return f;
			}
			//[obsoleted]
			float4 UnityCalcTriEdgeTessFactors (float3 triVertexFactors)
			{
				float4 tess;
				tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
				tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
				tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
				tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
				return tess;
			}

			//[obsoleted]"Tessellation.cginc"中我们找到了UnityDistanceBasedTess函数
			float4 UnityDistanceBasedTess (float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tess)
			{
				float3 f;
				f.x = UnityCalcDistanceTessFactor (v0,minDist,maxDist,tess);
				f.y = UnityCalcDistanceTessFactor (v1,minDist,maxDist,tess);
				f.z = UnityCalcDistanceTessFactor (v2,minDist,maxDist,tess);
				return UnityCalcTriEdgeTessFactors(f);
			}
			
			float4 tessDistance(appdata v0, appdata v1, appdata v2) {
				float minDist = 100.0;
				float maxDist = 250.0;
				return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tessellation);
			}

			void disp(inout appdata v)
			{
			 	//urp no tex2dlod
				float d = SAMPLE_TEXTURE2D(_Splatmap,sampler_Splatmap,float4(v.uv.xy, 0, 0)).r * _Displacement;
				v.vertex.xyz -= v.normal * d;
				v.vertex.xyz += v.normal * _Displacement;
			}
			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
			};
			*/

			//==================From Built-In=======================
			struct appdata_base {
				float4 vertex : POSITION;//顶点位置
				float3 normal : NORMAL;//发现
				float4 texcoord : TEXCOORD0;//纹理坐标
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			//==================From Built-In=======================

			struct VertexOutput
			{
				float4 color : COLOR;
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normalDirWS : NORMAL_WS;

				float3 positionWS : POSITION_WS;
				float4 tangentWS : TANGENT_WS;
			};		


			half4 ShadeSingleLight(half4 albedo, half3 viewDirectionWS, half3 normalWS, Light light, bool isAdditionalLight)
            {
                half3 h = SafeNormalize(viewDirectionWS + normalize(light.direction));
                half4 diffuse = saturate(dot(normalWS, normalize(light.direction))) * light.shadowAttenuation * half4(light.color, 1) * albedo; // 漫反射
                half4 specular = pow(saturate(dot(h, normalWS)), _Glossiness) * half4(light.color, 1) * saturate(_SpecColor) * light.shadowAttenuation; // 高光
                return (diffuse + specular) * (isAdditionalLight ? 0.25 : 1);
            }


			

			// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
			// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
			// #pragma instancing_options assumeuniformscaling
			//UNITY_INSTANCING_BUFFER_START(Props)
				// put more per-instance properties here
			//UNITY_INSTANCING_BUFFER_END(Props)

			VertexOutput vert(VertexInput v)
			{
				const VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
				const VertexNormalInputs   vertexNormalInput = GetVertexNormalInputs(v.normal, v.tangent);
				real sign = v.tangent.w * GetOddNegativeScale();

				VertexOutput o;

				o.positionCS = TransformObjectToHClip(v.vertex);
				o.positionWS = float4(TransformObjectToWorld(v.vertex), 0);
				o.uv = TRANSFORM_TEX(v.uv, _SnowTex);
				o.normalDirWS = vertexNormalInput.normalWS;
				o.tangentWS = real4(vertexNormalInput.tangentWS, sign);
				o.positionWS = TransformObjectToWorld(v.vertex);

				// 1. 简单在Groud和Snow之间Lerp在片元shader得到结果,使用踩陷(splatmap)的深度作为权重
				// 2. 使用Groud和Snow之间的差值，在Object Space直接让顶点沿法线方向内陷

				// urp has no tex2dlod, use SAMPLE_TEXTURE2D instead
				// Ref from may
				// 获取Ground和Mask的R通道
				//float mask_Param_R = tex2Dlod(_MaskTex, float4(o.uv,0,0)).r;
				//float main_Param_R = tex2Dlod(_MainTex, float4(o.uv,0,0)).r;
				
				// 雪地向下陷,mask贴图R通道作为权重,TODO: change the value 0.7
				//float3 offset =  (mask_Param_R + main_Param_R - 0.7) * v.normal * _Displacement;
				//v.vertex -= float4(offset,0);

				float4 fallin = tex2Dlod(_MaskTex, float4(v.uv.xy, 0, 0));
                o.positionCS.y += (fallin.r) * _Displacement - _Displacement;
                o.positionCS.y -= (saturate(fallin.g - fallin.r)) * _Displacement * 0.4;
				
				

				// 得到屏幕空间下的 齐次 坐标 【0，w】
				//o.screenPos = ComputeScreenPos(o.positionCS);
				return o;
			}

			//============= Tessellation Shader =====================
			// 不是所有平台都支持Tessellation Shader
			//#ifdef UNITY_CAN_COMPILE_TESSELLATION
				// just used for tes
				/*struct TessVertex {
					float4 vertex : POSITION;
					float4 tangent : TANGENT;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};*/

				// 该结构的其余部分与VertexInput相同，只是使用INTERNALTESSPOS代替POSITION语意，否则编译器会报位置语义的重用
				struct TessVertex
				{
					float4 vertex : INTERNALTESSPOS;
					float2 uv : TEXCOORD0;
					float4 color : COLOR;
					float3 normal : NORMAL;

					float4 tangent : TANGENT;
				};

				// 细分因子由三条边+一个内部因子 共计4个
				struct OutputPatchConstant
				{
					float edge[3] : SV_TessFactor;
					float inside  : SV_InsideTessFactor;
					/*float3 vTangent[4] : TANGENT;
					float2 vUV[4] : TEXCOORD0;
					float3 vTanUCorner[4] : TANUCORNER;
					float3 vTanVCorner[4] : TANVCORNER;
					float vCWts : TANWEIGHTS;*/
				};

				TessVertex tessvert(VertexInput v)
				{
					TessVertex o;
					o.vertex = v.vertex;
					o.normal = v.normal;
					o.tangent = v.tangent;
					o.uv = v.uv;
					return o;
				}
				/*[obsoleted]
				float4 Tessellation (TessVertex v,TessVertex v1,TessVertex v2)
				{
					float minDist = 1.0;
					float maxDist = 25.0;
					// 控制细分距离
					return UnityDistanceBasedTess(v.vertex,v1.vertex,v2.vertex,minDist,maxDist,_Tessellation);
				}

				float Tessellation (TessVertex v)
				{
					return _Tessellation;
				}*/

				// 细分不对距离进行处理
				//float4 Tessellation (TessVertex v,TessVertex v1,TessVertex v2)
				//{
					//float tv = Tessellation(v);
					//float tv1 = Tessellation(v1);
					//float tv2 = Tessellation(v2);
					//return float4(tv1 + tv2, tv2 + tv, tv + tv1, tv + tv1 + tv2) / float4(2,2,2,3);
				//}

				OutputPatchConstant hullconst (InputPatch<TessVertex, 3> patch)
				{
					//OutputPatchConstant o = (OutputPatchConstant)0;
					// 调用细分距离控制
					// old version
					//float4 ts = Tessellation(v[0],v[1],v[2]);
					//o.edge[0] = ts.x;
					//o.edge[1] = ts.y;
					//o.edge[2] = ts.z;
					//o.inside = ts.w;

					float minDist = _MinTessDistance;
					float maxDist = _MaxTessDistance;
				
					OutputPatchConstant f;
				
					float edge0 = CalcDistanceTessFactor(patch[0].vertex, minDist, maxDist, _Tessellation);
					float edge1 = CalcDistanceTessFactor(patch[1].vertex, minDist, maxDist, _Tessellation);
					float edge2 = CalcDistanceTessFactor(patch[2].vertex, minDist, maxDist, _Tessellation);
				
					// make sure there are no gaps between different tessellated distances, by averaging the edges out.
					f.edge[0] = (edge1 + edge2) / 2;
					f.edge[1] = (edge2 + edge0) / 2;
					f.edge[2] = (edge0 + edge1) / 2;
					f.inside = (edge0 + edge1 + edge2) / 3;
                	return f;
				}

				// 每一个顶点都会调用一次
				[domain("tri")] // 定义特性，表示输入Hull shader的图元为Triangle
				[partitioning("fractional_odd")] // 分割方式，如何切割补丁Patch
				[outputtopology("triangle_cw")] // 图元朝向,顺时针环绕
				[patchconstantfunc("hullconst")] // 补丁常量缓存函数名
				[outputcontrolpoints(3)] // 三个控制点
				TessVertex hull (InputPatch<TessVertex, 3> patch, uint id : SV_OutputControlPointID)
				{
					return patch[id];
				}

				[domain("tri")]
				VertexOutput domain(OutputPatchConstant tessFactor, OutputPatch<TessVertex, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
				{
					VertexInput v;//= (VertexInput)0;

					//为了找到该顶点的位置，我们必须使用重心坐标在原始三角形范围内进行插值。
					//X，Y和Z坐标确定第一，第二和第三控制点的权重。
					//以相同的方式插值所有顶点数据。让我们为此定义一个方便的宏，该宏可用于所有矢量大小。
					#define DomainInterpolate(fieldName) v.fieldName = \
							patch[0].fieldName * barycentricCoordinates.x + \
							patch[1].fieldName * barycentricCoordinates.y + \
							patch[2].fieldName * barycentricCoordinates.z;
    
                    //对位置、颜色、UV、法线等进行插值
                    DomainInterpolate(vertex)
                    DomainInterpolate(uv)
                    DomainInterpolate(color)
                    DomainInterpolate(normal)
					DomainInterpolate(tangent)

					return vert(v);
				}
			//#endif
			//============= Tessellation Shader =====================

			float4 frag(VertexOutput i) : SV_Target
			{
				//将Groud和Snow直接根据 ·脚印· 进行LerpSplatmap = mask
				//float4 mask = tex2Dlod(_MaskTex ,float4(TRANSFORM_TEX(i.uv,_MaskTex),0,0));
				//float4 groud = tex2D(_MainTex, i.uv) * _GroundColor;
				//float4 snow = tex2D(_SnowTex, i.uv) * _SnowColor;
				//float4 c = lerp(groud, snow, mask.r);

				half amount = tex2Dlod(_MaskTex, float4(i.uv.xy, 0, 0)).x;
                half4 albedo = lerp(tex2D(_SnowTex, i.uv)*_SnowColor, tex2D(_MainTex, i.uv)*_GroundColor, amount); //纹理采样结果

				half3 normalTS = UnpackNormal(tex2D(_SnowNormal, i.uv));
				half sgn = i.tangentWS.w;
				half3 bitangent = sgn * cross(i.normalDirWS.xyz, i.tangentWS.xyz);
				half3 normalWS  = mul(normalTS, real3x3(i.tangentWS.xyz, bitangent.xyz, i.normalDirWS.xyz)); // 转换至世界空间

                half3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - i.positionWS); // safe防止分母为0
				
				// 主光源
				Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS)); // 主光源
                mainLight.shadowAttenuation = MainLightRealtimeShadow(TransformWorldToShadowCoord(i.positionWS));
				//half4 lightColor = real4(mainLight.color, 1.0); // 主光源颜色
				//half3 lightDir = normalize(mainLight.direction); // 主光源方向

				// 次级光源
                half4 additionalLightSumResult = half4(0,0,0,0);
                int additionalLightsCount = GetAdditionalLightsCount(); //获得附加光源然后遍历应用
                for (int index = 0; index < additionalLightsCount; ++index)
                {
                    int perObjectLightIndex = GetPerObjectLightIndex(index); //对附加光源i进行初始化
                    Light light = GetAdditionalPerObjectLight(perObjectLightIndex, i.positionWS.xyz);
                    light.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, i.positionWS.xyz, light.direction);

                    // Different function used to shade additional lights.
                    additionalLightSumResult += ShadeSingleLight(albedo, viewDirectionWS, normalWS, light, true); //diffuse+specular
                }
                additionalLightSumResult += ShadeSingleLight(albedo, viewDirectionWS, normalWS, mainLight, false); //diffuse+specular

				real4 ambient = albedo; // 环境光

				//diffuse = saturate(dot(lightDir, normalWS)) * mainLight.shadowAttenuation * lightColor * albedo; // 漫反射
				//h = SafeNormalize(viewDirectionWS + lightDir);
				//specular = pow(saturate(dot(h, normalWS)), _Glossiness) * lightColor * saturate(_SpecColor) * mainLight.shadowAttenuation; // 高光

				half fresnel = _FresnelFactor + (1 - _FresnelFactor)*pow(1 - dot(viewDirectionWS, normalWS), 5); //菲涅尔系数
				
				return (ambient * UNITY_LIGHTMODEL_AMBIENT + lerp(additionalLightSumResult, half4(1,1,1,1), fresnel)) ; //环境光+漫反射+高光反射+菲涅尔

			}
			ENDHLSL
		}


		//把上个Pass中和顶点相关的部分移进来，只写入深度不管颜色
		Pass
		{
			Name "DepthOnly"
			Tags{"LightMode" = "DepthOnly"}

			// more explict render state to avoid confusion
			ZWrite On // the only goal of this pass is to write depth!
			ZTest LEqual // early exit at Early-Z stage if possible            
			ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
			Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

			HLSLPROGRAM

			#pragma require tessellation
			#pragma require geometry

			#pragma vertex BeforeTessVertProgram
			#pragma hull HullProgram
			#pragma domain DomainProgram
			#pragma fragment FragmentProgram

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 4.6

			// Includes
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float _Tess;
			float _MaxTessDistance;
			float _MinTessDistance;
			CBUFFER_END

			sampler2D _Splat;
			sampler2D _SnowNormal;
			float _Displacement;
			float4 _SplatTex_ST;

			//为了方便操作 定义预定义
			#define smp SamplerState_Point_Repeat
			// SAMPLER(sampler_MainTex); 默认采样器
			SAMPLER(smp);

			// 顶点着色器的输入
			struct Attributes
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;

				float4 tangentOS : TANGENT;
			};

			// 片段着色器的输入
			struct Varyings
			{
				float4 color : COLOR;
				float3 normal : NORMAL;
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;

				float3 positionWS : POSITION_WS;
				float3 normalWS : NORMAL_WS;
				float4 tangentWS : TANGENT_WS;
			};

			// 为了确定如何细分三角形，GPU使用了四个细分因子。三角形面片的每个边缘都有一个因数。
			// 三角形的内部也有一个因素。三个边缘向量必须作为具有SV_TessFactor语义的float数组传递。
			// 内部因素使用SV_InsideTessFactor语义
			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			// 该结构的其余部分与Attributes相同，只是使用INTERNALTESSPOS代替POSITION语意，否则编译器会报位置语义的重用
			struct ControlPoint
			{
				float4 vertex : INTERNALTESSPOS;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				float3 normal : NORMAL;

				float4 tangentOS : TANGENT;
			};

			// 顶点着色器，此时只是将Attributes里的数据递交给曲面细分阶段
			ControlPoint BeforeTessVertProgram(Attributes v)
			{
				ControlPoint p;

				p.vertex = v.vertex;
				p.uv = v.uv;
				p.normal = v.normal;
				p.tangentOS = v.tangentOS;
				return p;
			}

			// 随着距相机的距离减少细分数
			float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
			{
				float3 worldPosition = TransformObjectToWorld(vertex.xyz);
				float dist = distance(worldPosition,  GetCameraPositionWS());
				float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
				return (f);
			}

			// Patch Constant Function决定Patch的属性是如何细分的。这意味着它每个Patch仅被调用一次，
			// 而不是每个控制点被调用一次。这就是为什么它被称为常量函数，在整个Patch中都是常量的原因。
			// 实际上，此功能是与HullProgram并行运行的子阶段。
			// 三角形面片的细分方式由其细分因子控制。我们在MyPatchConstantFunction中确定这些因素。
			// 当前，我们根据其距离相机的位置来设置细分因子
			TessellationFactors MyPatchConstantFunction(InputPatch<ControlPoint, 3> patch)
			{
				float minDist = _MinTessDistance;
				float maxDist = _MaxTessDistance;

				TessellationFactors f;

				float edge0 = CalcDistanceTessFactor(patch[0].vertex, minDist, maxDist, _Tess);
				float edge1 = CalcDistanceTessFactor(patch[1].vertex, minDist, maxDist, _Tess);
				float edge2 = CalcDistanceTessFactor(patch[2].vertex, minDist, maxDist, _Tess);

				// make sure there are no gaps between different tessellated distances, by averaging the edges out.
				f.edge[0] = (edge1 + edge2) / 2;
				f.edge[1] = (edge2 + edge0) / 2;
				f.edge[2] = (edge0 + edge1) / 2;
				f.inside = (edge0 + edge1 + edge2) / 3;
				return f;
			}

			//细分阶段非常灵活，可以处理三角形，四边形或等值线。我们必须告诉它必须使用什么表面并提供必要的数据。
			//这是 hull 程序的工作。Hull 程序在曲面补丁上运行，该曲面补丁作为参数传递给它。
			//我们必须添加一个InputPatch参数才能实现这一点。Patch是网格顶点的集合。必须指定顶点的数据格式。
			//现在，我们将使用ControlPoint结构。在处理三角形时，每个补丁将包含三个顶点。此数量必须指定为InputPatch的第二个模板参数
			//Hull程序的工作是将所需的顶点数据传递到细分阶段。尽管向其提供了整个补丁，
			//但该函数一次仅应输出一个顶点。补丁中的每个顶点都会调用一次它，并带有一个附加参数，
			//该参数指定应该使用哪个控制点（顶点）。该参数是具有SV_OutputControlPointID语义的无符号整数。
			[domain("tri")]//明确地告诉编译器正在处理三角形，其他选项：
			[outputcontrolpoints(3)]//明确地告诉编译器每个补丁输出三个控制点
			[outputtopology("triangle_cw")]//当GPU创建新三角形时，它需要知道我们是否要按顺时针或逆时针定义它们
			[partitioning("fractional_odd")]//告知GPU应该如何分割补丁，现在，仅使用整数模式
			[patchconstantfunc("MyPatchConstantFunction")]//GPU还必须知道应将补丁切成多少部分。这不是一个恒定值，每个补丁可能有所不同。必须提供一个评估此值的函数，称为补丁常数函数（Patch Constant Functions）
			ControlPoint HullProgram(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			//把这个函数的当成顶点函数即可
			Varyings AfterTessVertProgram(Attributes v)
			{
				const VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
				const VertexNormalInputs   vertexNormalInput = GetVertexNormalInputs(v.normal, v.tangentOS);
				real sign = v.tangentOS.w * GetOddNegativeScale();

				Varyings o;

				o.vertex = TransformObjectToHClip(v.vertex);
				o.positionWS = float4(TransformObjectToWorld(v.vertex), 0);
				o.uv = TRANSFORM_TEX(v.uv, _SplatTex);
				o.normalWS = vertexNormalInput.normalWS;
				o.tangentWS = real4(vertexNormalInput.tangentWS, sign);
				o.positionWS = TransformObjectToWorld(v.vertex);
				float4 fallin = tex2Dlod(_Splat, float4(v.uv.xy, 0, 0));
				o.vertex.y += (fallin.r) * _Displacement - _Displacement;
				o.vertex.y -= (saturate(fallin.g - fallin.r)) * _Displacement * 0.4;
				return o;
			}

			//HUll着色器只是使曲面细分工作所需的一部分。一旦细分阶段确定了应如何细分补丁，
			//则由Domain着色器来评估结果并生成最终三角形的顶点。
			//Domain程序将获得使用的细分因子以及原始补丁的信息，原始补丁在这种情况下为OutputPatch类型。
			//细分阶段确定补丁的细分方式时，不会产生任何新的顶点。相反，它会为这些顶点提供重心坐标。
			//使用这些坐标来导出最终顶点取决于域着色器。为了使之成为可能，每个顶点都会调用一次域函数，并为其提供重心坐标。
			//它们具有SV_DomainLocation语义。
			//在Demain函数里面，我们必须生成最终的顶点数据。
			[domain("tri")]//Hull着色器和Domain着色器都作用于相同的域，即三角形。我们通过domain属性再次发出信号
			Varyings DomainProgram(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
			{
				Attributes v;

				//为了找到该顶点的位置，我们必须使用重心坐标在原始三角形范围内进行插值。
				//X，Y和Z坐标确定第一，第二和第三控制点的权重。
				//以相同的方式插值所有顶点数据。让我们为此定义一个方便的宏，该宏可用于所有矢量大小。
				#define DomainInterpolate(fieldName) v.fieldName = \
                        patch[0].fieldName * barycentricCoordinates.x + \
                        patch[1].fieldName * barycentricCoordinates.y + \
                        patch[2].fieldName * barycentricCoordinates.z;

					//对位置、UV、法线等进行插值
					DomainInterpolate(vertex)
					DomainInterpolate(uv)
					DomainInterpolate(normal)
					DomainInterpolate(tangentOS)

						//现在，我们有了一个新的顶点，该顶点将在此阶段之后发送到几何程序或插值器。
						//但是这些程序需要Varyings数据，而不是Attributes。为了解决这个问题，
						//我们让域着色器接管了原始顶点程序的职责。
						//这是通过调用其中的AfterTessVertProgram（与其他任何函数一样）并返回其结果来完成的。
						return AfterTessVertProgram(v);
				}

			// 片段着色器
			half4 FragmentProgram(Varyings i) : SV_TARGET
			{
				return half4(1,1,1,0);
			}

			ENDHLSL
		}
	}
	CustomEditor "LWGUI.LWGUI"
}
