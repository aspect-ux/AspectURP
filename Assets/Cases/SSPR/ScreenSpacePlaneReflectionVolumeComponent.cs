namespace UnityEngine.Rendering.Universal
{
    /// <summary>
    /// Volume¿Ø¼þ
    /// </summary>
    [SerializeField, VolumeComponentMenu("Mypost/ScreenSpacePlaneReflect")]
    public class ScreenSpacePlaneReflectionVolumeComponent : VolumeComponent

    {
        public BoolParameter On = new BoolParameter(false);
        public ClampedIntParameter RTHieght = new ClampedIntParameter(512, 128, 1080, false);
        public FloatParameter ReflectPlaneHeight = new FloatParameter(0f, false);
        public ColorParameter FinalTintColor = new ColorParameter(Color.white, false);
        public ClampedFloatParameter fadeOutRange = new ClampedFloatParameter(0.3f, 0.0f, 1.0f, false);

        public ClampedFloatParameter FadeOutScreenBorderWidthVerticle = new ClampedFloatParameter(0.25f, 0.01f, 1f, false);
        public ClampedFloatParameter FadeOutScreenBorderWidthHorizontal = new ClampedFloatParameter(0.35f, 0.01f, 1f, false);
    }
}