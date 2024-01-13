
using UnityEngine.Rendering;

class GaussianBlurParameter : VolumeComponent
{
    public ClampedIntParameter iterations = new ClampedIntParameter(3, 0, 4);
    public ClampedFloatParameter blurSpread = new ClampedFloatParameter(0.6f, 0.2f, 3.0f);
    public ClampedIntParameter downSample = new ClampedIntParameter(2, 1, 8);
}