using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostProcessingRendererFeature : ScriptableRendererFeature
{
	#region GaussianBlur
	class GaussianBlurPass : ScriptableRenderPass
	{
		private static readonly string shader_name = "AspectURP/PostProcessing/GaussianBlur";     
		static readonly string k_RenderTag = "Render GaussianBlur";                             // 显示在frame debug里的名称
		static readonly int TempTargetId0 = Shader.PropertyToID("_TempTargetColorTint0");       // 用来暂存纹理
		static readonly int TempTargetId1 = Shader.PropertyToID("_TempTargetColorTint1");       // 用来暂存纹理
		GaussianBlurParameter parameter;            // 参数类
		Material postMaterial;                      // 后处理材质
		RenderTargetIdentifier currentTarget;       // 用来获取相机rt的id
		
		
		public GaussianBlurPass(RenderPassEvent evt)
		{
			this.renderPassEvent = evt;
			Init();
		}
		void Init()
		{
			var shader = Shader.Find(shader_name);
			postMaterial = CoreUtils.CreateEngineMaterial(shader);
		}
		
		public void SetTarget(ScriptableRenderer renderer)
		{
			currentTarget = renderer.cameraColorTarget;
		}
		// This method is called before executing the render pass.
		// It can be used to configure render targets and their clear state. Also to create temporary render target textures.
		// When empty this render pass will render to the active camera render target.
		// You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
		// The render pipeline will ensure target setup and clearing happens in a performant manner.
		public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
		{
		}

		// Here you can implement the rendering logic.
		// Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
		// https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
		// You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			//ScriptableRenderContext 用于调度和提交 渲染状态和绘制指令 到GPU
			if (postMaterial == null) return;
			if (!renderingData.cameraData.postProcessEnabled)   // 相机有没有打开后处理
			{
				return;
			}
			var stack = VolumeManager.instance.stack;
			parameter = stack.GetComponent<GaussianBlurParameter>();
			
			if (parameter == null) { return; }

			var cmd = CommandBufferPool.Get(k_RenderTag);
			Render(cmd, ref renderingData);
			context.ExecuteCommandBuffer(cmd);
			CommandBufferPool.Release(cmd);
		}
		
		void Render(CommandBuffer cmd, ref RenderingData renderingData)
		{
			var source = currentTarget;
			int destination0 = TempTargetId0;
			int destination1 = TempTargetId1;

			ref var cameraData = ref renderingData.cameraData;

			var data = renderingData.cameraData.cameraTargetDescriptor;

			var width = data.width/ parameter.downSample.value;
			var height = data.height / parameter.downSample.value;

			// 先存到临时的地方
			cmd.GetTemporaryRT(destination0, width, height, 0, FilterMode.Trilinear, RenderTextureFormat.ARGB32);
			cmd.Blit(source, destination0);

			for (int i = 0; i < parameter.iterations.value; ++i)
			{
				cmd.SetGlobalFloat("_BlurSize", 1.0f + i * parameter.blurSpread.value);

				// 第一轮
				cmd.GetTemporaryRT(destination1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
				cmd.Blit(destination0, destination1, postMaterial, 0);
				cmd.ReleaseTemporaryRT(destination0);

				// 第二轮
				cmd.GetTemporaryRT(destination0, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
				cmd.Blit(destination1, destination0, postMaterial, 1);
				cmd.ReleaseTemporaryRT(destination1);
			}

			cmd.Blit(destination0, source);

			cmd.ReleaseTemporaryRT(TempTargetId0);
		}

		// Cleanup any allocated resources that were created during the execution of this render pass.
		public override void OnCameraCleanup(CommandBuffer cmd)
		{
		}
	}
	#endregion
	
	#region Bloom
	class BloomPass : ScriptableRenderPass
	{
		private static readonly string shader_name = "AspectURP/PostProcessing/Bloom";     
		static readonly string k_RenderTag = "Render Bloom";                             // 显示在frame debug里的名称
		static readonly int TempTargetId0 = Shader.PropertyToID("_TempTargetColorTint0");       // 用来暂存纹理
		static readonly int TempTargetId1 = Shader.PropertyToID("_TempTargetColorTint1");       // 用来暂存纹理
		BloomParameter parameter;            // 参数类
		Material bloomMaterial,gaussianMaterial;                      // 后处理材质
		RenderTargetIdentifier currentTarget;       // 用来获取相机rt的id
		
		public BloomPass(RenderPassEvent evt)
		{
			this.renderPassEvent = evt;
			Init();
		}
		void Init()
		{
			var shader = Shader.Find(shader_name);
			bloomMaterial = CoreUtils.CreateEngineMaterial(shader);
			
			gaussianMaterial = CoreUtils.CreateEngineMaterial(Shader.Find("AspectURP/PostProcessing/GaussianBlur"));
		}
		
		public void SetTarget(ScriptableRenderer renderer)
		{
			currentTarget = renderer.cameraColorTarget;
		}
		// This method is called before executing the render pass.
		// It can be used to configure render targets and their clear state. Also to create temporary render target textures.
		// When empty this render pass will render to the active camera render target.
		// You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
		// The render pipeline will ensure target setup and clearing happens in a performant manner.
		public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
		{
		}

		// Here you can implement the rendering logic.
		// Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
		// https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
		// You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			//ScriptableRenderContext 用于调度和提交 渲染状态和绘制指令 到GPU
			if (bloomMaterial == null) return;
			if (!renderingData.cameraData.postProcessEnabled)   // 相机有没有打开后处理
			{
				return;
			}
			var stack = VolumeManager.instance.stack;
			parameter = stack.GetComponent<BloomParameter>();
			
			if (parameter == null) { return; }

			var cmd = CommandBufferPool.Get(k_RenderTag);
			Render(cmd, ref renderingData);
			context.ExecuteCommandBuffer(cmd);
			CommandBufferPool.Release(cmd);
		}
		
		void Render(CommandBuffer cmd, ref RenderingData renderingData)
		{			
			var source = currentTarget;
			int destination0 = TempTargetId0;
			int destination1 = TempTargetId1;

			ref var cameraData = ref renderingData.cameraData;

			var data = renderingData.cameraData.cameraTargetDescriptor;

			cmd.SetGlobalFloat("_LuminanceThreshold",parameter.luminanceThreshold.value);
			
			var width = data.width/ parameter.downSample.value;
			var height = data.height / parameter.downSample.value;

			// 先存到临时的地方
			cmd.GetTemporaryRT(destination0, width, height, 0, FilterMode.Trilinear, RenderTextureFormat.ARGB32);
			cmd.Blit(source, destination0,bloomMaterial,0);

			for (int i = 0; i < parameter.iterations.value; ++i)
			{
				cmd.SetGlobalFloat("_BlurSize", 1.0f + i * parameter.blurSpread.value);

				// 第一轮
				cmd.GetTemporaryRT(destination1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
				cmd.Blit(destination0, destination1, gaussianMaterial, 0);
				cmd.ReleaseTemporaryRT(destination0);

				destination0 = destination1;
				// 第二轮
				cmd.GetTemporaryRT(destination1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
				cmd.Blit(destination0, destination1, gaussianMaterial, 1);
				
				cmd.ReleaseTemporaryRT(destination0);

				destination0 = destination1;
			}
			//cmd.Blit(destination0, source);
			//postMaterial.SetTexture( " _Bloom" , destination0);
			cmd.SetGlobalTexture("_BloomTex",destination0);
			cmd.Blit(destination0, source, bloomMaterial , 1);
			
			cmd.ReleaseTemporaryRT(TempTargetId0);
		}

		// Cleanup any allocated resources that were created during the execution of this render pass.
		public override void OnCameraCleanup(CommandBuffer cmd)
		{
		}
	}
	#endregion


	// Pass Objects
	GaussianBlurPass m_GaussianBlurScriptablePass;
	
	BloomPass m_BloomScriptablePass;

	/// <inheritdoc/>
	public override void Create()
	{
		m_GaussianBlurScriptablePass = new GaussianBlurPass(RenderPassEvent.BeforeRenderingPostProcessing);
		//m_BloomScriptablePass = new BloomPass(RenderPassEvent.BeforeRenderingPostProcessing);
	}
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		m_GaussianBlurScriptablePass.SetTarget(renderer);
		renderer.EnqueuePass(m_GaussianBlurScriptablePass);
	}
}


