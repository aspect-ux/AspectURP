Shader "AspectURP/Cases/Silk"
{
    // 黑丝效果，丝袜(尼龙袜...)由纤维制成
    // 1. Denier 丹尼尔值，丹尼尔越大，穿透性越差(越黑)
    // 2. Density 疏密度，由于腿部中央疏密度Density低，所以能够隐约看到皮肤。
    Properties
    {
        _MainTex("Base Map",2D) = "white"{}
        _Denier("Denier", Range(5,120)) = 25.0
        _DenierTex("Density Texture", 2D) = "black"{}
        [Enum(Strong,6,Normal,12,Weak,20)] _RimPower("Rim Power", float) = 12
        _SkinTint("Skin Color Tint", Color) = (1,0.9,0.8,1)
        _SkinTex("Skin Color", 2D) = "white" {}
        _StockingTint("Stocking Color Tint", Color) = (1,1,1,1)
        _StockingTex("Stocking Color", 2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);

                /*float4 skinColor = tex2D(_SkinTex, i.uv) * _SkinTint;
                float4 stockingColor = tex2D(_StockingTex, i.uv) * _StockingTint;
                float rim = pow(1 - dot(normalize(IN.viewDir), o.Normal), _RimPower / 10);
                float denier = (_Denier - 5) / 115;
                float density = max(rim, (denier * (1 - tex2D(_DenierTex, IN.uv_DenierTex))));*/

                return col;
            }
            ENDHLSL
        }
    }
}
