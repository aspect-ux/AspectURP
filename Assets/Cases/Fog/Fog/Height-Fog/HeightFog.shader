Shader "My Space/Fog/HeightFog"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma shader_feature _FOG_OFF _FOG_ON

            #include "UnityCG.cginc"
            #include "Fog.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float3 worldPos : TEXCOORD1;

                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;

                float4 screenPos : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                o.bitangentWS = UnityObjectToWorldDir(cross(v.normal,v.tangent));
                o.tangentWS = UnityObjectToWorldDir(v.tangent);
                o.normalWS = UnityObjectToWorldDir(v.normal);

                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                //half3 normalTS = UnpackNormal(tex2D(_BumpMap,i.uv));
                //half3x3 TBN = half3x3(i.tangetWS,i.bitangentWS,i.normalWS);
                //由于线性变化后，法线 变成"逆矩阵" ，
                //half3 normalWS = mul(normalTS,TBN);

                half3 L = UnityWorldSpaceLightDir(i.pos);
                half NdotL = dot(i.normalWS,L) * 0.5 + 0.5;

                half4 col = tex2D(_MainTex,i.uv);

                #ifdef _FOG_ON
                    col.xyz = ExponentialHeightFog(col.xyz,i.worldPos);
                #endif
                    return half4(col.xyz,1);
            }
            ENDCG
        }
    }
}
