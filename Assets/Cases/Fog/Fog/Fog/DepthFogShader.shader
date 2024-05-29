Shader "Unlit/DepthFogShader"
{
    Properties
    {
		_MainTex("MainTex", 2D) = "white" {} //相机原结果
		_MaxOpacity("MaxOpacity", range(0, 1)) = 1
		_UseExponential("_UseExponential", int) = 0
		_FogIntensity("FogIntensity", range(-1,200)) = 1
		_LightFocus("LightFocus", float) = 1
		_FogColor("FogColor", Color) = (1,1,1,1)
		_FarPlane("FarPlane", float) = 300
		_NearPlane("NearPlane", float) = 10
		_VerticalGradient("VerticalGradient", int) = 0
		_BottomPlane("BottomPlane", float) = 10
		_TopPlane("TopPlane", float) = 300
		_CameraPos("CameraPos", Vector) = (0,0,0)
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D_X_FLOAT(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);
			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			half _MaxOpacity;
			int _UseExponential;
			half _FogIntensity;
			half _LightFocus;
			half4 _FogColor;
			half _FarPlane;
			int _VerticalGradient;
			half _NearPlane;
			half _BottomPlane;
			half _TopPlane;
			half3 _CameraPos;
			CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
				float3 worldPos = ComputeWorldSpacePosition(i.uv, depth, UNITY_MATRIX_I_VP);
				
				///////////////////////////
				//深度雾强度
				///////////////////////////
				//线性
				float linear_depthfogDensity = step(_NearPlane, length(_CameraPos-worldPos)) * (length(_CameraPos - worldPos)-_NearPlane) / (_FarPlane - _NearPlane); //强度控制：0~200 => 无~浓
				linear_depthfogDensity = saturate(linear_depthfogDensity * _FogIntensity);
			    //指数
				float exp_depthfogDensity = saturate(1 - exp(_FogIntensity * length(_CameraPos - worldPos))); //强度控制：0~-1 => 无~浓
				
				float depthfogDensity = exp_depthfogDensity * _UseExponential + linear_depthfogDensity * (1 - _UseExponential);

				//高度对雾的影响，越高越淡
				float heightfogDensity = saturate((_TopPlane - worldPos.y) / (_TopPlane-_BottomPlane));
				depthfogDensity = depthfogDensity * (step(0.5, _VerticalGradient) * heightfogDensity + step(_VerticalGradient, 0.5));

				///////////////////////////
				//平行光对雾颜色影响
				///////////////////////////
				Light mainLight = GetMainLight(TransformWorldToShadowCoord(worldPos)); // 主光源
				half3 lightDir = normalize(mainLight.direction); // 主光源方向
				half3 viewDir = normalize(worldPos - _CameraPos);
				half dirFactor = pow((dot(lightDir, viewDir)+1)/2, _LightFocus) / 2;
				dirFactor = dirFactor * saturate(length(_CameraPos - worldPos) / _FarPlane) * step(1, _LightFocus);

				//return half4(depthfogDensity, depthfogDensity, depthfogDensity, 1);
				half4 col = lerp( SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv), lerp(_FogColor, half4(mainLight.color,1), dirFactor), depthfogDensity * _MaxOpacity);
				
				return col;
            }
            ENDHLSL
        }
    }
}
