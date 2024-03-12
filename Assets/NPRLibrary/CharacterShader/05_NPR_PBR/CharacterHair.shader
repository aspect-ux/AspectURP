Shader "Mobile-Game/Hair-Prime"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MainColor("Hair Color(头发颜色)", Color) = (1,1,1,1)
		_SpecularShift("Hair Shifted Texture(头发渐变灰度图)", 2D) = "white" {}
		_SpecularColor_1("Hair Spec Color Primary(主高光颜色)", Color) = (1,1,1,1)
		//_SpecularColor_2("Hair Spec Color Seconary(次高光颜色)", Color) = (1,1,1,1)
		_SpecularWidth("Specular Width(高光收敛)", Range(0, 1)) = 1
		_PrimaryShift("Primary Shift(主高光偏移)", Range(-5, 5)) = 0
		//_SecondaryShift("Secondary Shift(次高光偏移)", Range(-5, 5)) = 0
		_SpecularScale("_Specular Scale(高光强度)", Range(0, 2)) = 1

        [Header(Outline)]
        [Space(5)]
        _OutlineColor("OutLine Color",Color) = (0,0,0,1)
        _OutlineWidth("Outline Width",Range(-1,1)) = 0.1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

        HLSLINCLUDE

        #pragma vertex vert
        #pragma fragment frag
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

        struct VertexInput //输入结构
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;
            float2 uv1 : TEXCOORD1;
            float4 tangent : TANGENT;
            float4 vertexColor: COLOR;
            UNITY_VERTEX_INPUT_INSTANCE_ID 
        };
        struct VertexOutput //输出结构
        {
            float4 pos : POSITION;
            float2 uv : TEXCOORD0;
            float2 uv1 : TEXCOORD1;
            float4 vertexColor: COLOR;
            float3 nDirWS : TEXCOORD2;
            float3 nDirVS : TEXCOORD3;
            float3 vDirWS : TEXCOORD4;
            float3 worldPos : TEXCOORD5;
            float3 lightDirWS : TEXCOORD6;
            float3 tangentDirWS : TANGENT;

            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainColor;

            float4 _SpecularColor_1;
            float4 _SpecularShift_ST;

			half _PrimaryShift;
			float _SpecularWidth;
			half _SpecularScale;

            // Outline
            float4 _OutlineColor;
            float _OutlineWidth;
        CBUFFER_END

        TEXTURE2D(_MainTex);     
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_SpecularShift);     
        SAMPLER(sampler_SpecularShift);
        ENDHLSL

		Pass
		{
            Name "Hair"
            Tags
            {
                "LightMode"="UniversalForward"
                "RenderType"="Opaque"
            }
			HLSLPROGRAM

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;

			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 tangent :TEXCOORD1;
				float3 normal : TEXCOORD2;
				float3 bitangent : TEXCOORD3;
				float3 pos : TEXCOORD4;
			};
            
			
			v2f vert (appdata v)
			{
				v2f o;
				//UNITY_INITIALIZE_OUTPUT(o);
				o.vertex = TransformObjectToHClip(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = TransformObjectToWorldDir(v.normal);
				o.tangent = TransformObjectToWorldDir(v.tangent.xyz);
				o.bitangent = cross(v.normal, v.tangent) * v.tangent.w * unity_WorldTransformParams.w;
				o.pos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			half3 ShiftedTangent(float3 t, float3 n, float shift) {
				return normalize(t + shift * n);
			}

			float StrandSpecular(float3 T, float3 V, float3 L, int exponent)
			{
				float3 H = normalize(L + V);
				float dotTH = dot(T, H);
				float sinTH = sqrt(1.0 - dotTH * dotTH);
				float dirAtten = smoothstep(-_SpecularWidth, 0, dotTH);
				return dirAtten * pow(sinTH, exponent) * _SpecularScale;
			}

			float HairSpecular(float3 t, float3 n, float3 l, float3 v, float2 uv)
			{
				float shiftTex = SAMPLE_TEXTURE2D(_SpecularShift,sampler_SpecularShift, uv * _SpecularShift_ST.xy + _SpecularShift_ST.zw) - 0.5;
				float3 t1 = ShiftedTangent(t, n, _PrimaryShift + shiftTex);
				float3 specular = _SpecularColor_1 * StrandSpecular(t1, v, l, 20);
				return specular;
			}

			float GGXAnisotropicNormalDistribution(float anisotropic, float roughness, float NdotH, float HdotX, float HdotY, float SpecularPower, float c)
			{
				float aspect = sqrt(1.0 - 0.9 * anisotropic);
				float roughnessSqr = roughness * roughness;
				float NdotHSqr = NdotH * NdotH;
				float ax = roughnessSqr / aspect;
				float ay = roughnessSqr * aspect;
				float d = HdotX * HdotX / (ax * ax) + HdotY * HdotY / (ay * ay) + NdotHSqr;
				return 1 / (3.14159 * ax * ay * d * d);
			}

			float sqr(float x) {
				return x * x;
			}

			float WardAnisotropicNormalDistribution(float anisotropic, float NdotL, float NdotV, float NdotH, float HdotX, float HdotY) {
				float aspect = sqrt(1.0h - anisotropic * 0.9h);
				float roughnessSqr = (1 - 0.5);
				roughnessSqr *= roughnessSqr;
				float X = roughnessSqr / aspect;
				float Y = roughnessSqr * aspect;
				float exponent = -(sqr(HdotX / X) + sqr(HdotY / Y)) / sqr(NdotH);
				float Distribution = 1.0 / (4.0 * 3.14159265 * X * Y * sqrt(NdotL * NdotV));
				Distribution *= exp(exponent);
				return Distribution;
			}
	
			half4 frag (v2f i) : SV_Target
			{
				//diffuse color
				half3 diff = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex ,i.uv).rgb * _MainColor;
				//specular
				float3 n = normalize(i.normal);
				//float3 t = normalize(i.tangent);
				float3 b = normalize(i.bitangent);
				float3 v = normalize(GetCameraPositionWS().xyz  - i.pos);

                // TODO: only mainlight now
                Light mainLight = GetMainLight();

				float3 l = normalize(mainLight.direction);
				//float3 h = normalize(l + v);
				float3 spec = HairSpecular(b, n, l, v, i.uv);
				//spec = GGXAnisotropicNormalDistribution(1, 0.3, dot(n, h), dot(t, h), dot(b, h), 5, 0.1);
				//spec = WardAnisotropicNormalDistribution(1, dot(n, l), dot(n, v), dot(n, h), dot(t, h), dot(b, h));
				half4 col = float4(_MainLightColor.rgb * (spec + diff), 1);
				return col;
			}
			ENDHLSL
		}

        Pass
        {
            Name "Outline"
            Cull Front
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
                "RenderType"="Opaque"
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
        }
	}
}