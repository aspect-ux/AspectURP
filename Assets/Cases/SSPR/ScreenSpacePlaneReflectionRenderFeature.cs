using UnityEngine;

using UnityEngine.Rendering;

using UnityEngine.Rendering.Universal;

public class ScreenSpacePlaneReflectionRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class PassSetting
    {
        public string CmdName = "屏幕空间平面反射";

        /// <summary>
        /// 是否启用SSPR
        /// </summary>
        [Header("Settings")]
        public bool ShouldRenderSSPR = true;

        /// <summary>
        /// 用于捕捉屏幕反射内容的ComputerShader
        /// </summary>
        public ComputeShader SsprComputerShader;

        /// <summary>
        /// 反射采样贴图大小
        /// </summary>
        [Range(128, 1024)]
        public int RT_height = 512;

        /// <summary>
        /// 反射结果的色调调整
        /// </summary>
        [ColorUsage(true, true)]
        public Color TintColor = Color.white;

        /// <summary>
        /// SSPR插入的渲染阶段
        /// </summary>
        public RenderPassEvent EventPlugIn = RenderPassEvent.AfterRenderingTransparents;
    }

    private CustomRenderPass m_ScriptablePass;
    public PassSetting Setting = new PassSetting();

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(Setting);
        m_ScriptablePass.renderPassEvent = Setting.EventPlugIn;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //Debug.Log("运行AddRenderPasses");
        renderer.EnqueuePass(m_ScriptablePass);
    }

    /// <summary>
    /// 进行SSPR的自定义RenderPass
    /// </summary>
    private class CustomRenderPass : ScriptableRenderPass
    {
        private PassSetting Setting;

        private static readonly int ReflectColorRT = Shader.PropertyToID("_ReflectColor");//定义一张RT用来存储反射图像的颜色 当颜色缓冲区使
        private static readonly int HashPackedDataRT = Shader.PropertyToID("_HashPackedData"); //定义一张RT来保存对应关系
        private static readonly int TempTextureRT = Shader.PropertyToID("_TempTexture");

        private RenderTargetIdentifier ReflectColorRT_ID = new RenderTargetIdentifier(ReflectColorRT);
        private RenderTargetIdentifier HashPackedDataRT_ID = new RenderTargetIdentifier(HashPackedDataRT);
        private RenderTargetIdentifier TempTextureRT_ID = new RenderTargetIdentifier(TempTextureRT);

        private ShaderTagId lightMode_SSPR_sti = new ShaderTagId("SSPR"); //使得指定LightMode为SSPR的反射平面Shader能够起作用

        private const int SHADER_NUMTHREAD_X = 8; //must match compute shader's [numthread(x)]
        private const int SHADER_NUMTHREAD_Y = 8; //must match compute shader's [numthread(y)]

        public ComputeShader SsprComputerShader;

        public CustomRenderPass(PassSetting setting)
        {
            this.Setting = setting;
        }

        private ScreenSpacePlaneReflectionVolumeComponent SSPRvolume;

        private int RTWidth;//真实的rt水平大小
        private int RTHeight;//真实的rt垂直大小
        private int ThreadCountX => Mathf.RoundToInt((float)RTWidth / SHADER_NUMTHREAD_X); //水平方向上的组数
        private int ThreadCountY => Mathf.RoundToInt((float)RTHeight / SHADER_NUMTHREAD_Y); //竖直方向上的组数
        private int ThreadCountZ => 1; //Z方向组数

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            //Debug.Log("Configure");
            var POSTstack = VolumeManager.instance.stack;
            SSPRvolume = POSTstack.GetComponent<ScreenSpacePlaneReflectionVolumeComponent>();//获取自定义的volume组件的参数来控制反射的效果

            float aspect = (float)Screen.width / Screen.height;

            RTHeight = SSPRvolume.RTHieght.value;
            RTWidth = Mathf.RoundToInt(RTHeight * aspect);

            //Debug.Log($"RTWidth:{RTWidth}, RTHeight:{RTHeight}");
            //Debug.Log($"ThreadCountX:{ThreadCountX}, ThreadCountY:{ThreadCountY}");

            RenderTextureDescriptor rtd = new RenderTextureDescriptor(RTWidth, RTHeight, RenderTextureFormat.ARGBFloat, 0, 0);//ARGB是用来存颜色通道的 这个图要传给shader 注意我们要a当遮罩 精度我认为单通道8字节足够了
            rtd.sRGB = false;
            rtd.enableRandomWrite = true;//绑定uav

            //ColorRT
            rtd.colorFormat = RenderTextureFormat.ARGBFloat;
            cmd.GetTemporaryRT(ReflectColorRT, rtd);

            //PackedDataRT - HashRT
            rtd.colorFormat = RenderTextureFormat.RInt;
            cmd.GetTemporaryRT(HashPackedDataRT, rtd);

            rtd.colorFormat = RenderTextureFormat.ARGBFloat;
            cmd.GetTemporaryRT(TempTextureRT, rtd);

            SsprComputerShader = Setting.SsprComputerShader;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //Debug.Log("Execute");
            CommandBuffer cmd = CommandBufferPool.Get(Setting.CmdName);

            if (SSPRvolume.On.value)
            {
                if (SsprComputerShader == null)
                {
                    Debug.LogError("SSPRcomputeShader丢失！");
                    return;
                }

                SsprComputerShader.name = "SSPR_CatchReflection";

                cmd.SetComputeVectorParam(SsprComputerShader, Shader.PropertyToID("_RTSize"), new Vector2(RTWidth, RTHeight));
                cmd.SetComputeFloatParam(SsprComputerShader, Shader.PropertyToID("_ReflectPlaneHeight"), SSPRvolume.ReflectPlaneHeight.value);
                cmd.SetComputeVectorParam(SsprComputerShader, Shader.PropertyToID("_CameraDirection"), renderingData.cameraData.camera.transform.forward);
                //Debug.Log(renderingData.cameraData.camera.transform.forward);
                cmd.SetComputeVectorParam(SsprComputerShader, Shader.PropertyToID("_FinalTintColor"), SSPRvolume.FinalTintColor.value);

                cmd.SetComputeFloatParam(SsprComputerShader, Shader.PropertyToID("_FadeOutScreenBorderWidthVerticle"), SSPRvolume.FadeOutScreenBorderWidthVerticle.value);
                cmd.SetComputeFloatParam(SsprComputerShader, Shader.PropertyToID("_FadeOutScreenBorderWidthHorizontal"), SSPRvolume.FadeOutScreenBorderWidthHorizontal.value);

                Camera camera = renderingData.cameraData.camera;
                Matrix4x4 VP = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true) * camera.worldToCameraMatrix;
                cmd.SetComputeMatrixParam(SsprComputerShader, "_VPMatrix", VP);
                SsprComputerShader.SetMatrix(Shader.PropertyToID("_IVPMatrix"), VP.inverse);

                //清除历史影响
                int kernel_PathClear = SsprComputerShader.FindKernel("PathClear");
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathClear, "HashRT", HashPackedDataRT_ID);
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathClear, "_TempTexture", TempTextureRT_ID);
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathClear, "ColorRT", ReflectColorRT_ID);
                cmd.DispatchCompute(SsprComputerShader, kernel_PathClear, ThreadCountX, ThreadCountY, ThreadCountZ);

                //绘制HashRT关系映射
                int kernel_PathRenderHashRT = SsprComputerShader.FindKernel("PathRenderHashRT");
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathRenderHashRT, "HashRT", HashPackedDataRT_ID);
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathRenderHashRT, "_TempTexture", TempTextureRT_ID);
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathRenderHashRT, "_CameraDepthTexture", new RenderTargetIdentifier("_CameraDepthTexture"));
                cmd.DispatchCompute(SsprComputerShader, kernel_PathRenderHashRT, ThreadCountX, ThreadCountY, ThreadCountZ);

                //将反射结果绘制到ColorRT
                int kernel_PathResolveColorRT = SsprComputerShader.FindKernel("PathResolveColorRT");
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathResolveColorRT, "_CameraOpaqueTexture", new RenderTargetIdentifier("_CameraOpaqueTexture"));
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathResolveColorRT, "ColorRT", ReflectColorRT_ID);
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_PathResolveColorRT, "HashRT", HashPackedDataRT_ID);
                cmd.DispatchCompute(SsprComputerShader, kernel_PathResolveColorRT, ThreadCountX, ThreadCountY, ThreadCountZ);

                //补洞
                int kernel_FillHoles = SsprComputerShader.FindKernel("FillHoles");
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_FillHoles, "ColorRT", ReflectColorRT_ID);
                cmd.SetComputeTextureParam(SsprComputerShader, kernel_FillHoles, "HashRT", HashPackedDataRT_ID);
                cmd.DispatchCompute(SsprComputerShader, kernel_FillHoles, Mathf.CeilToInt(ThreadCountX / 2f), Mathf.CeilToInt(ThreadCountY / 2f), ThreadCountZ);

                cmd.SetGlobalTexture(ReflectColorRT, ReflectColorRT_ID); //让外部Shader可以获取反射贴图结果，用Texture2D(_ReflectColor)来获取
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

            DrawingSettings drawingSettings = CreateDrawingSettings(lightMode_SSPR_sti, ref renderingData, SortingCriteria.CommonOpaque);
            FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.all);
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            //Debug.Log("FrameCleanup");
            cmd.ReleaseTemporaryRT(ReflectColorRT);
            cmd.ReleaseTemporaryRT(HashPackedDataRT);
        }
    }
}