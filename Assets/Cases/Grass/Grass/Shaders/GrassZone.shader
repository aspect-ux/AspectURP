Shader "Demo/GS/GSTest"
{
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		[Space]
		_TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
		[Header(Blades)]
		_BladeWidth("Blade Width", Float) = 0.05
		_BladeWidthRandom("Blade Width Random", Float) = 0.02
		_BladeHeight("Blade Height", Float) = 0.5
		_BladeHeightRandom("Blade Height Random", Float) = 0.3
		_BladeForward("Blade Forward Amount", Float) = 0.38
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
		[Header(Wind)]
		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindStrength("Wind Strength", Float) = 1
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
    }
	
    CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#include "CustomTessellation.cginc"


	uniform float4 _TopColor;
	uniform float4 _BottomColor;
	uniform float _TranslucentGain;
	uniform float _BladeHeight;
	uniform float _BladeHeightRandom;
	uniform float _BladeWidth;
	uniform float _BladeWidthRandom;
	uniform float _BendRotationRandom;
	uniform sampler2D _WindDistortionMap;
	uniform float4 _WindDistortionMap_ST;
	uniform float2 _WindFrequency;
	uniform float _WindStrength;
	uniform float _BladeForward;
	uniform float _BladeCurve;


	#define BLADE_SEGMENTS 3


	struct geometryOutput
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
		unityShadowCoord4 _ShadowCoord : TEXCOORD1;
	};

	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	geometryOutput VertexOutput(float3 pos, float3 normal, float2 uv)
	{
		geometryOutput o;

		UNITY_INITIALIZE_OUTPUT(geometryOutput, o);

		o.pos = UnityObjectToClipPos(pos);

	#if UNITY_PASS_FORWARDBASE
		o.normal = UnityObjectToWorldNormal(normal);
		o.uv = uv;
		// 阴影从屏幕空间阴影贴图纹理中采样
		o._ShadowCoord = ComputeScreenPos(o.pos);
	#elif UNITY_PASS_SHADOWCASTER
		// Applying the bias prevents artifacts from appearing on the surface.
		o.pos = UnityApplyLinearShadowBias(o.pos);
	#endif

		return o;
	}

	geometryOutput GenerateGrassVertex(float3 vertexPosition, float width, float height, float forward, float2 uv, float3x3 transformMatrix)
	{
		float3 tangentPoint = float3(width, forward, height);

		float3 tangentNormal = normalize(float3(0, -1, forward));

		float3 localPosition = vertexPosition + mul(transformMatrix, tangentPoint);
		float3 localNormal = mul(transformMatrix, tangentNormal);
		return VertexOutput(localPosition, localNormal, uv);
	}


	[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
	void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
	{
		float3 pos = IN[0].vertex;
		float3 vNormal = IN[0].normal;
		float4 vTangent = IN[0].tangent;

		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;
				
		//构建矩阵
		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));

		float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));

		//草表面滚动风纹理
		float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
		//控制风强度
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
		//构造一个表示风向的归一化向量
		float3 wind = normalize(float3(windSample.x, windSample.y, 0));
		//构造一个矩阵
		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);

		float3x3 TBN = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
		);

		float3x3 transformationMatrix = mul(mul(mul(TBN, windRotation), facingRotationMatrix), bendRotationMatrix);
		//整个叶片都在旋转，导致底座不再固定在地面上。该矩阵将不包括windRotation或bendRotationMatrix矩阵，以确保底部保持附着在其表面上。
		float3x3 transformationMatrixFacing = mul(TBN, facingRotationMatrix);

		float height = (rand(pos.xyz) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
		float width = (rand(pos.xyz) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
		float forward = rand(pos.yyz) * _BladeForward;
		
		for (int i = 0; i < BLADE_SEGMENTS; i++)
		{
			float t = i / (float)BLADE_SEGMENTS;

			float segmentHeight = height * t;
			float segmentWidth = width * (1 - t);
			float segmentForward = pow(t, _BladeCurve) * forward;

			// Select the facing-only transformation matrix for the root of the blade.
			float3x3 transformMatrix = i == 0 ? transformationMatrixFacing : transformationMatrix;

			triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentHeight, segmentForward, float2(0, t), transformMatrix));
			triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentHeight, segmentForward, float2(1, t), transformMatrix));
		}

		// Add the final vertex as the tip.
		triStream.Append(GenerateGrassVertex(pos, 0, height, forward, float2(0.5, 1), transformationMatrix));
	}

	ENDCG
    SubShader
    {
		Cull Off	
		Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma vertex vert
			#pragma geometry geo
            #pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_fwdbase
            
			#include "Lighting.cginc"

			float4 frag (geometryOutput i,  fixed facing : VFACE) : SV_Target
			{
				float3 normal = facing > 0 ? i.normal : -i.normal;
				float shadow = SHADOW_ATTENUATION(i);
				float NdotL = saturate(saturate(dot(normal, _WorldSpaceLightPos0)) + _TranslucentGain) * shadow;

				float3 ambient = ShadeSH9(float4(normal, 1));
				float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);
				float4 col = lerp(_BottomColor, _TopColor * lightIntensity, i.uv.y);

				return col;
			}
			ENDCG
		}
		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_shadowcaster
			float4 frag(geometryOutput i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}	
	}
 }
