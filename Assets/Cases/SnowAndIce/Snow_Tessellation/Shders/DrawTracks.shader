Shader "Unlit/DrawTracks"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Coordinate("Coordinate", Vector) = (0,0,0,0)
        _Color("Draw Color", Color) = (1,0,0,0)
        _Size("Size", Range(1,16)) = 1
        _Strength("Strength", Range(0,1)) = 1
		_Atten("Atten", Range(0.9, 1)) = 0.98
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
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
            half4 _Coordinate;
            half4 _Color;
            half _Size, _Strength, _Atten;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float draw = pow(saturate(1 - distance(i.uv, _Coordinate.xy)), (1200 / _Size));
                float drawEdge = pow(saturate(1 - distance(i.uv, _Coordinate.xy)), (1200 / _Size)/1.5 );
                half4 drawCol = _Color * (draw * _Strength) + half4(0, drawEdge , 0, 0);
				drawCol.b = pow(saturate(1 - distance(i.uv, _Coordinate.xy)), (1200 / _Size) * 1.2);
                return saturate(col*_Atten + drawCol);
            }
            ENDCG
        }
    }
}
