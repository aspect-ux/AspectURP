using UnityEngine;
using UnityEngine.Rendering;

[SerializeField, VolumeComponentMenu("Mypost/DepthFog")]
public class FogVolunmeComponent : VolumeComponent
{
    public BoolParameter On = new BoolParameter(false);
    public ColorParameter FogColor = new ColorParameter(Color.white);
    public ClampedFloatParameter MaxOpacity = new ClampedFloatParameter(0.5f, 0f, 1f);
    public BoolParameter UseExponential = new BoolParameter(false);
    public FloatParameter FogIntensity = new FloatParameter(0f);
    public ClampedIntParameter LightFocus = new ClampedIntParameter(8, 0, 16);
    public FloatParameter NearPlane = new FloatParameter(10f);
    public FloatParameter FarPlane = new FloatParameter(300f);
    public BoolParameter VerticalGradient = new BoolParameter(false);
    public FloatParameter BottomPlane = new FloatParameter(10f);
    public FloatParameter TopPlane = new FloatParameter(300f);
}
