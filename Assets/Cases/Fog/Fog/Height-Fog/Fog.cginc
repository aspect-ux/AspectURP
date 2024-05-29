#ifndef CUSTOM_FOG_INCLUDE
#define CUSTOM_FOG_INCLUDE

float3 _FogColor;

float _FogGlobalDensity;
float _FogFallOff;
float _FogHeight;
float _FogStartDis;
float _FogInscatteringExp;
float _FogGradientDis;

half3 ExponentialHeightFog(half3 col, half3 posWorld) {
	half heightFallOff = _FogFallOff * 0.01;
	half falloff = heightFallOff * (posWorld.y - _WorldSpaceCameraPos.y - _FogHeight);
}
#endif