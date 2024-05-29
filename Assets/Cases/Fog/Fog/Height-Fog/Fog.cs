using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fog : MonoBehaviour
{
    public bool enable;
    public Color fogColor;
    public float fogHeight;
    [Range(0,1)] public float fogDensity;
    [Min(0f)] public float fogFalloff;

    public float fogStartDis;
    public float fogInscatteringExp;

    public float fogGradientDis;
    private static readonly int FogColor = Shader.PropertyToID("_FogColor");//雾的颜色
    private static readonly int FogGlobalDensity = Shader.PropertyToID("_FogGlobalDensity");//雾的全局参数
    private static readonly int FogFallOff = Shader.PropertyToID("_FogFallOff");//控制(用于乘法控制系数)

    private static readonly int FogHeight = Shader.PropertyToID("_FogHeight");//目标与相机高度差的 控制参数(用于+-控制)

    private static readonly int FogStartDis = Shader.PropertyToID("_FogStartDis");
    private static readonly int FogInscatteringExp = Shader.PropertyToID("_FogInscatteringExp");
    private static readonly int FogGradientDis = Shader.PropertyToID("_FogGradientDis");   

    void OnValidate(){
        Shader.SetGlobalColor(FogColor,fogColor);
        Shader.SetGlobalFloat(FogGlobalDensity, fogDensity);
        Shader.SetGlobalFloat(FogFallOff, fogFalloff);
        Shader.SetGlobalFloat(FogHeight, fogHeight);
        Shader.SetGlobalFloat(FogStartDis, fogStartDis);
        Shader.SetGlobalFloat(FogInscatteringExp, fogInscatteringExp);
        Shader.SetGlobalFloat(FogGradientDis,fogGradientDis);
        if(enable){
            Shader.EnableKeyword("_FOG_ON");
            Shader.DisableKeyword("_FOG_OFF");
        }
        else{
            Shader.DisableKeyword("_FOG_ON");
            Shader.EnableKeyword("_FOG_OFF");
        }

    }
    

}
