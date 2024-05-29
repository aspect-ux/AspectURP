Shader "My Space/Skybox/UniversalSkybox"
{
    Properties
    {
        //debug
		[Header(Debug)]
		_Test("test",  Range(0, 1000)) = 0.15
		[MaterialToggle] addSunandMoon("Add Sun And Moon", Float) = 0
		[MaterialToggle] _addGradient("Add Gradient", Float) = 0
		[Toggle(ADDCLOUD)] _addCloud("Add Cloud", Float) = 0
		[MaterialToggle] _addStar("Add Star", Float) = 0
		[MaterialToggle] _addHorizon("Add Horizon", Float) = 0
		[Toggle(MIRROR)] _MirrorMode("Mirror Mode", Float) = 0
    	
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color",Color) = (1,1,1,1)
        
        [Header(Sun and Moon)]
        _SunSize ("Sun Size",Float) = 1
        _SunInnerBoundary("Sun Inner Boundary",Range(0,1)) = 0.1
        _SunOuterBoundary("Sun Outer Boundary",Range(0,1)) = 0.1
        
        _MoonOffset ("Moon Offset",Range(0,1)) = 0.1
        _MoonSize ("Moon Size",Float) = 1
        [Space(5)]
        [Header(Day and Night)]
        _DayBottomColor ("Day Bottom Color",Color) = (1,1,1,1)
        _DayMidColor ("Day Mid Color",Color) = (1,1,1,1)
        _DayTopColor ("Day Top Color",Color) = (1,1,1,1)
        _NightBottomColor ("Night Bottom Color",Color) = (1,1,1,1)
        _NightMidColor ("Night Mid Color",Color) = (1,1,1,1)
        _NightTopColor ("Night Top Color",Color) = (1,1,1,1)
        
        _MoonTex ("Moon Tex",2D) = "white"{} 
        [Space(5)]
        _HorizonColorDay("Horizon Day Color",Color) = (1,1,1,1) 
        _HorizonColorNight("Horizon Night Color",Color) = (1,1,1,1) 
        
        [Space(5)]
        [Header(Star and Cloud)]
        _SunColor ("Sun Color",Color) = (1,1,1,1)
        _MoonColor ("Moon Color",Color) = (1,1,1,1)
        _StarTex ("Star Tex",2D) = "white"{}
        _StarNoiseTex ("Star Noise Tex",2D) = "white"{}
        _StarSpeed ("Star Speed",Range(-1,1)) = 0.2
        _StarsCutoff ("Stars Cutoff",Range(0,1)) = 0.2
    	_StarScale ("Star Scale",Range(0,1000)) = 10
    	_StarColor ("Star Color", Color) = (1,1,1,1)
        
        [Space(5)]
        _CloudTex ("Cloud Tex",2D) = "white"{}
        _CloudSpeed ("Cloud Speed",Range(-10,10)) = 0.2
        _CloudCutoff ("Cloud Cutoff",Range(0,3)) = 0.2
        _CloudScale ("Cloud Scale",Range(0,1)) = 0.2
        _CloudColorDay ("Cloud Color Day",Color) = (1,1,1,1)
        _CloudColorNight ("Cloud Color Night",Color) = (1,1,1,1)
        _CloudBrightnessDay ("Cloud Brightness Day",Range(0,3)) = 0.2
        _CloudBrightnessNight ("Cloud Brightness Night",Range(0,3)) = 0.2
        _CloudColorDaySec  ("Cloud Color Day Sec",Color) = (1,1,1,1)
        _CloudColorNightSec  ("Cloud Color Day Sec",Color) = (1,1,1,1)
        [Space(5)]
        _DistortTex ("Distort Tex",2D) = "white"{}
        _DistortSpeed ("Distort Speed",Range(-1,1)) = 0.2
        _DistortScale ("Distort Scale",Range(0,20)) = 0.2
        [Space(5)]
        _CloudNoiseTex ("Noise Tex",2D) = "white"{}
        _CloudNoiseScale ("Noise Scale",Range(0,20)) = 0.2
        
        _Fuzziness("Cloud Fuzziness",  Range(-5, 5)) = 0.04
    	_FuzzinessSec("Cloud Fuzziness Sec",  Range(-5, 5)) = 0.04
        
        [Space(5)]
        [Header(Horizon)]
        _HorizonHeight("Horizon Height", Range(-10,10)) = 10
		_HorizonIntensity("Horizon Intensity",  Range(0, 100)) = 3.3
        
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
            // make fog work
            //#pragma multi_compile_fog
            #pragma shader_feature ADDCLOUD
            #pragma shader_feature MIRROR

            #include "UnityCG.cginc"

            //debug
		    float _Test, addSunandMoon, _addHorizon, _addGradient, _addCloud, _addStar, _MirrorMode;

            float4 _BaseColor;

            float _SunSize,_SunInnerBoundary,_SunOuterBoundary;
            float4 _SunColor;
            
            float4 _MoonColor;

            float _MoonOffset,_MoonSize;

            float4 _DayBottomColor,_DayMidColor,_DayTopColor,_NightBottomColor,_NightMidColor,_NightTopColor;

            float4 _HorizonColorDay,_HorizonColorNight;
            float _HorizonIntensity,_HorizonHeight;

            float _StarSpeed,_StarsCutoff,_StarScale;
            float4 _StarColor;

            float _CloudSpeed,_CloudCutoff,_CloudScale,_CloudBrightnessDay,_CloudBrightnessNight;
            float4 _CloudColorDay,_CloudColorNight,_CloudColorDaySec,_CloudColorNightSec;

            float _DistortSpeed,_DistortScale,_CloudNoiseScale,_Fuzziness,_FuzzinessSec;

           
            struct appdata
            {
                float4 vertex : POSITION;
                float3 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MoonTex;
            float4 _MoonTex_ST;
            sampler2D _StarTex;
            float4 _StarTex_ST;
            sampler2D _StarNoiseTex;
            float4 _StarNoiseTex_ST;
            sampler2D _CloudTex;
            float4 _CloudTex_ST;
            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            sampler2D _CloudNoiseTex;
            float4 _CloudNoiseTex_ST;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                //o.uv.xy = TRANSFORM_TEX(v.texcoord,_MoonTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the base texture for skybox
                fixed4 col = tex2D(_MainTex, i.uv.xy);
                float3 worldPos = normalize(i.worldPos);

                //=========================PART1: Sun and Moon===============================
                //sun
                float sunDist = distance(i.uv.xyz,_WorldSpaceLightPos0);
                float sunArea = saturate((1 - sunDist / _SunSize) * 50);
                sunArea = smoothstep(_SunInnerBoundary,_SunOuterBoundary,sunArea);

                //moon
                float moon = distance(i.uv.xyz,-_WorldSpaceLightPos0);
                float moonDist = saturate((1 - moon / _MoonSize) * 50);
                
                float crescent = distance(float3(i.uv.x + _MoonOffset,i.uv.yz),-_WorldSpaceLightPos0);//crescent新月
                float crescentDist = saturate((1 - crescent / _MoonSize) * 50);

                moonDist = saturate(moonDist - crescentDist);

                 //TODO: add a moon texture
                float4 moonTex = tex2D(_MoonTex, i.uv.xy);
                // ?moonMap
                //float moonTexArea = moonMap.a * 0.5;
                float3 moonMap = moonTex.a * moonTex.rgb;

                float3 sunAndMoon = (moonDist * _MoonColor * moonMap + sunArea * _SunColor).rgb;

                //==================PART2: day Alternates night========================
            	#if MIRROR
					float ypos = saturate(abs(i.uv.y));
				#else
					float ypos = saturate(i.uv.y);
				#endif
                float sunNightStep = smoothstep(-0.3,0.25,_WorldSpaceLightPos0.y);
                //DAY NIGHT
                float3 gradientDay = lerp(_DayBottomColor, _DayMidColor, ypos);
                float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, ypos);
                float3 skyGradient = lerp(gradientNight, gradientDay,sunNightStep);

                //========================PART3: Star and Cloud================================
                float2 skyuv = (i.worldPos.xz) / (clamp(i.worldPos.y, 0, 10000));
                //STAR
                float3 stars = tex2D(_StarTex, (skyuv + float2(_StarSpeed, _StarSpeed) * _Time.x) * _StarScale);
                stars = step(_StarsCutoff, stars) * saturate(-_WorldSpaceLightPos0.y) * _StarColor * _addStar;

                //CLOUD
				float cloud = tex2D(_CloudTex, (skyuv + (_Time.x * _CloudSpeed)) * _CloudScale);
				float distort = tex2D(_DistortTex, (skyuv + (_Time.x * _DistortSpeed)) * _DistortScale);
				float noise = tex2D(_CloudNoiseTex, ((skyuv + distort) - (_Time.x * _CloudSpeed)) * _CloudNoiseScale);
				float finalNoise = saturate(noise) * 3 * saturate(i.worldPos.y);
				cloud = saturate(smoothstep(_CloudCutoff * cloud, _CloudCutoff * cloud + _Fuzziness, finalNoise));
				float cloudSec = saturate(smoothstep(_CloudCutoff * cloud, _CloudCutoff * cloud + _Fuzziness + _FuzzinessSec, finalNoise));
				
				float3 cloudColoredDay = cloud *  _CloudColorDay * _CloudBrightnessDay;
				float3 cloudSecColoredDay = cloudSec * _CloudColorDaySec * _CloudBrightnessDay;
				cloudColoredDay += cloudSecColoredDay;

				float3 cloudColoredNight = cloud * _CloudColorNight * _CloudBrightnessNight;
				float3 cloudSecColoredNight = cloudSec * _CloudColorNightSec * _CloudBrightnessNight;
				cloudColoredNight += cloudSecColoredNight;

				float3 finalcloud = lerp(cloudColoredNight, cloudColoredDay, saturate(_WorldSpaceLightPos0.y)) * _addCloud;

                #if ADDCLOUD
					stars *= (1 - cloud);
				#endif

                //horizon
                float3 horizon = abs((i.uv.y * _HorizonIntensity) - _HorizonHeight);
                horizon = saturate((1 - horizon)) * (_HorizonColorDay * saturate(-_WorldSpaceLightPos0.y)
                    + _HorizonColorNight * saturate(_WorldSpaceLightPos0.y)) * _addHorizon;

                float3 final = sunAndMoon +
                    + skyGradient
                    + horizon
                    + stars;
                    + finalcloud;
                return float4(final,1);
            }
            ENDCG
        }
    }
}
