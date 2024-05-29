using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogRendererFeature : ScriptableRendererFeature
{
    /// <summary>
    /// Pass的配置
    /// </summary>
    public PassSetting setting;
    private FogRenderPass fogPass;

    public class PassSetting {
        /// <summary>
        /// Pass名
        /// </summary>
        public string CmdName = "深度雾";

        /// <summary>
        /// 雾的材质
        /// </summary>
        public Material FogMaterial;
    }

    [SerializeField]
    private Material FogMaterial;

    [SerializeField]
    private RenderPassEvent EventPlugin = RenderPassEvent.AfterRenderingTransparents;

    //private readonly string[] keyword = new string[]{ "_linear_", "_exponential_" };
    //private bool UseExponential
    //{
    //    get { return useExponential; }
    //    set
    //    {
    //        if (useExponential != value)
    //        {
    //            useExponential = value;
    //            int activeIndex = useExponential ? 1 : 0;
    //            FogMaterial?.EnableKeyword(keyword[activeIndex]);
    //            FogMaterial?.EnableKeyword(keyword[(activeIndex+1) % 2]);
    //        }
    //    }
    //}
    //private bool useExponential;


    public override void Create()
    {
        //似乎有内容更新就会执行
        name = "DepthFogRenderFeature";

        setting = new PassSetting();
        setting.FogMaterial = FogMaterial;

        fogPass = new FogRenderPass(setting);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (setting.FogMaterial == null)
        {
            Debug.LogWarning($"Missing DepthFog Materials - {GetType().Name}! ");
            return;
        }

        fogPass.renderPassEvent = EventPlugin;
        var src = renderer.cameraColorTarget;
        fogPass.Setup(src);
        renderer.EnqueuePass(fogPass);
    }

    public class FogRenderPass : ScriptableRenderPass
    {
        private PassSetting setting;
        private FogVolunmeComponent fogVolume;

        private RenderTargetHandle resultTexture;
        public FogRenderPass(PassSetting setting)
        {
            this.setting = setting;
            fogVolume = VolumeManager.instance.stack.GetComponent<FogVolunmeComponent>();
            resultTexture.Init("_DepthFogResultTexture");
        }

        /// <summary>
        /// 相机的渲染结果
        /// </summary>
        private RenderTargetIdentifier source;
        public void Setup(RenderTargetIdentifier source)
        {
            this.source = source;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            if(fogVolume == null) fogVolume = VolumeManager.instance.stack.GetComponent<FogVolunmeComponent>();

        }


        private int CameraTextureId = Shader.PropertyToID("CameraTexture");

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (fogVolume.On.value)
            {
                CommandBuffer cmd = CommandBufferPool.Get(setting.CmdName);
                RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor; //相机渲染到的目标说明
                cmd.GetTemporaryRT(resultTexture.id, opaqueDesc);

                var fogMat = setting.FogMaterial;
                fogMat.SetFloat("_FogIntensity", fogVolume.FogIntensity.value);
                fogMat.SetFloat("_MaxOpacity", fogVolume.MaxOpacity.value);
                fogMat.SetInt("_UseExponential", fogVolume.UseExponential.value?1:0);
                fogMat.SetInt("_LightFocus", fogVolume.LightFocus.value);
                fogMat.SetColor("_FogColor", fogVolume.FogColor.value);
                fogMat.SetFloat("_FarPlane", fogVolume.FarPlane.value);
                fogMat.SetFloat("_NearPlane", fogVolume.NearPlane.value);
                fogMat.SetInt("_VerticalGradient", fogVolume.VerticalGradient.value ? 1 : 0);
                fogMat.SetFloat("_BottomPlane", fogVolume.BottomPlane.value);
                fogMat.SetFloat("_TopPlane", fogVolume.TopPlane.value);
                fogMat.SetVector("_CameraPos", Camera.main.transform.position);
                cmd.Blit(source, resultTexture.Identifier(), fogMat);
                cmd.Blit(resultTexture.Identifier(), source);

                context.ExecuteCommandBuffer(cmd);

                CommandBufferPool.Release(cmd);
            }
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(resultTexture.id);
        }
    }
}
