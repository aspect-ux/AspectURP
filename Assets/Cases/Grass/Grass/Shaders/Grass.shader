Shader "Demo/Geometry/Grass"
{
    Properties
    {
		[Header(shading)]
		_TopColor("上部颜色",color) = (1.0,1.0,1.0,1.0)
		_BottomColor("下部颜色",color) = (1.0,1.0,1.0,1.0)
		_TranslucentGain("半透明", Range(0, 1)) = 0.5
		_BladeWidth("基础宽度",float) = 0.05
		_BladeWidthRandom("随机宽度系数",float) = 0.02
		_BladeHeight("基础高度",float) = 0.5
		_BladeHeightRandom("随机高度系数",float) = 0.3
    }
	
    SubShader
    {	
		Tags { "RenderType"="Opaque" }
        LOD 100
		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geo  //定义一个几何着色器

            #include "UnityCG.cginc"

			uniform float4 _TopColor;
			uniform float4 _BottomColor;
			uniform float _TranslucentGain;
			uniform float _BladeHeight;
			uniform float _BladeHeightRandom;
			uniform float _BladeWidth;
			uniform float _BladeWidthRandom;
		   
			 float rand(float3 co)
			{
				float f = frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
				return f;
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
					t * x * x + c, t * x * y - s *z, t * x * z + s * y,
					t * x * x + s * z, t * y * y + c, t * y * z - s * x,
					t * x * z - s * y, t * y * z + s * x, t * z * z + c);
			}

			struct vertexInput{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct vertexOutput{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			vertexOutput vert(vertexInput v)
			{
				vertexOutput o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.tangent = v.tangent;
				return o;
			}

			struct geometryOutput
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			geometryOutput CreateGeoOutput(float3 pos, float2 uv)
			{
				geometryOutput o;
				o.pos = UnityObjectToClipPos(pos); //几何着色器函数中进行空间转换操作
				o.uv = uv;
				return o;
			}


			[maxvertexcount(3)] //定义最多顶点数
			void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream){
			     float3 pos = IN[0].vertex;
				 float3 vNormal = IN[0].normal;
				 float4 vTangent = IN[0].tangent;
				 float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;
				
				 float height = (rand(pos.xyz) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
				 float width = (rand(pos.xyz) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
			 
				//构建矩阵 构建了TBN矩阵，并且与旋转矩阵相乘，获得转换矩阵
			     float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0,0,1));
				 float3x3 TBN = float3x3(
				    vTangent.x, vBinormal.x, vNormal.x,
				    vTangent.y, vBinormal.y, vNormal.y,
				    vTangent.z, vBinormal.z, vNormal.z
				 );
			    float3x3 transformationMat = mul(TBN,facingRotationMatrix);
                geometryOutput o;
			    //"TriangleStream"类似用来装配三角形的工具,用来输出图元
			    triStream.Append(CreateGeoOutput(pos+mul(transformationMat,float3(width,0,0)),float2(0,0)));
			    triStream.Append(CreateGeoOutput(pos+mul(transformationMat,float3(-width,0,0)),float2(1,0)));
				triStream.Append(CreateGeoOutput(pos+mul(transformationMat,float3(0,0,height)),float2(0.5,1)));
			 }


            fixed4 frag (geometryOutput i) : SV_Target
            {
                fixed4 color = lerp(_BottomColor, _TopColor, i.uv.y);
				return color;
            }
            ENDCG
			}
		}
 }    

