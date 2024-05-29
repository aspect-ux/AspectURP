//曲面细分Demo1
Shader "Demo/Tessllation/Tess"
{
    Properties
    {
        _TessellationUniform("TessellationUniform",Range(1,64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            CGPROGRAM
            //定义2个函数 hull domain
            #pragma hull hullProgram
            #pragma domain ds
           
            #pragma vertex tessvert
            #pragma fragment frag

            #include "UnityCG.cginc"
            //引入曲面细分的头文件
            #include "Tessellation.cginc" 

            #pragma target 5.0
            
            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct VertexOutput
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            //这个函数应用在domain函数中，用来空间转换的函数
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.tangent = v.tangent;
                o.normal = v.normal;
                return o;
            }

            //有些硬件不支持曲面细分着色器，定义了该宏就能够在不支持的硬件上不会变粉，也不会报错
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                //顶点着色器结构的定义
                struct TessVertex{
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv : TEXCOORD0;
                };

                struct OutputPatchConstant { 
                    //不同的图元，该结构会有所不同
                    //该部分用于Hull Shader里面
                    //定义了patch的属性
                    //Tessellation Factor和Inner Tessellation Factor
                    float edge[3] : SV_TESSFACTOR; // 细分影响因子：决定一条线分成几部分
                    float inside  : SV_INSIDETESSFACTOR;
                };

                TessVertex tessvert (VertexInput v){
                    //顶点着色器函数
                    TessVertex o;
                    o.vertex  = v.vertex;
                    o.normal  = v.normal;
                    o.tangent = v.tangent;
                    o.uv      = v.uv;
                    return o;
                }

                float _TessellationUniform;
                OutputPatchConstant hsconst (InputPatch<TessVertex,3> patch){
                    //定义曲面细分的参数
                    OutputPatchConstant o;
                    o.edge[0] = _TessellationUniform;
                    o.edge[1] = _TessellationUniform;
                    o.edge[2] = _TessellationUniform;
                    o.inside  = _TessellationUniform;
                    return o;
                }

                [UNITY_domain("tri")]//确定图元，quad,triangle等
                [UNITY_partitioning("fractional_odd")]//拆分edge的规则，equal_spacing,fractional_odd,fractional_even
                [UNITY_outputtopology("triangle_cw")]
                [UNITY_patchconstantfunc("hsconst")]//一个patch一共有三个点，但是这三个点都共用这个函数
                [UNITY_outputcontrolpoints(3)]      //不同的图元会对应不同的控制点
              
                TessVertex hullProgram (InputPatch<TessVertex,3> patch,uint id : SV_OutputControlPointID){
                    //定义hullshaderV函数
                    return patch[id];
                }

                [UNITY_domain("tri")]//同样需要定义图元
                VertexOutput ds (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3>patch,float3 bary :SV_DOMAINLOCATION)
                {
                    VertexInput v;
                    v.vertex = patch[0].vertex*bary.x + patch[1].vertex*bary.y + patch[2].vertex*bary.z;
			        v.tangent = patch[0].tangent*bary.x + patch[1].tangent*bary.y + patch[2].tangent*bary.z;
			        v.normal = patch[0].normal*bary.x + patch[1].normal*bary.y + patch[2].normal*bary.z;
			        v.uv = patch[0].uv*bary.x + patch[1].uv*bary.y + patch[2].uv*bary.z;

                    VertexOutput o = vert (v);
                    return o;
                }
            #endif

            float4 frag (VertexOutput i) : SV_Target
            {

                return float4(1.0,1.0,1.0,1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
