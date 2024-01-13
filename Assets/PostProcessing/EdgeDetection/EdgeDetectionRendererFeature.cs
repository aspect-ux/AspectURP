using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectionRendererFeature : ScriptableRendererFeature
{                      
	class EdgeDetectionRenderPass : ScriptableRenderPass
	{
		private static readonly string shaderName = "AspectURP/PostProcessing/Edge Detection"; 
		static readonly string k_RenderTag = "Render Edge Detection";  
	
		[Range(0,1)]private float edgeOnly = 0.0f;
		Color edgeColor = new Color(1,1,1,1);
		Color backgroundColor = new Color(1,1,1,1);
		
		// 后处理材质
		Material edgeDetectionMaterial;

		int _renderTargetId;
		
		// 用来获取相机rt的id
		RenderTargetIdentifier currentTarget;       

		// 相机RT id
		RenderTargetIdentifier _renderTargetIdentifier;
		
		int _renderTextureWidth;
		int _renderTextureHeight;

		int _blockSize;

		public EdgeDetectionRenderPass(Settings set,int renderTargetId)
		{
			this._renderTargetId = renderTargetId;
			edgeOnly = set._edgeOnly;
			edgeColor = set._edgeColor;
			backgroundColor = set._backgroundColor;

			Initialize();
		}
		void Initialize()
		{
			var shader = Shader.Find(shaderName);
			edgeDetectionMaterial = CoreUtils.CreateEngineMaterial(shader);
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
			var cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
			cameraTargetDescriptor.enableRandomWrite = true;
			cmd.GetTemporaryRT(_renderTargetId, cameraTargetDescriptor);
			_renderTargetIdentifier = new RenderTargetIdentifier(_renderTargetId);

			_renderTextureWidth = cameraTargetDescriptor.width;
			_renderTextureHeight = cameraTargetDescriptor.height;
		}

		// Here you can implement the rendering logic.
		// Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
		// https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
		// You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			// Just use this for game view(you decide it)
			if (renderingData.cameraData.isSceneViewCamera)
				return;
			
			//ScriptableRenderContext 用于调度和提交 渲染状态和绘制指令 到GPU
			if (edgeDetectionMaterial == null) return;
			if (!renderingData.cameraData.postProcessEnabled)   // 相机有没有打开后处理
			{
				return;
			}

			CommandBuffer cmd = CommandBufferPool.Get();
			
			Render(cmd, ref renderingData);
			
			context.ExecuteCommandBuffer(cmd);
			cmd.Clear();
			CommandBufferPool.Release(cmd);
		}
		
		void Render(CommandBuffer cmd, ref RenderingData renderingData)
		{			
			// currentTarget = renderingData.cameraData.renderer.cameraColorTarget;

			cmd.Blit(renderingData.cameraData.targetTexture, _renderTargetIdentifier,edgeDetectionMaterial,0);

			//Set Shader Params
			edgeDetectionMaterial.SetFloat("_EdgeOnly",edgeOnly); 
			edgeDetectionMaterial.SetColor("_EdgeColor", edgeColor); 
			edgeDetectionMaterial.SetColor(" BackgroundColor",backgroundColor);

			cmd.Blit(_renderTargetIdentifier, renderingData.cameraData.renderer.cameraColorTarget
				,edgeDetectionMaterial,0);
		}

		// Cleanup any allocated resources that were created during the execution of this render pass.
		public override void OnCameraCleanup(CommandBuffer cmd)
		{
			// Release RT
			cmd.ReleaseTemporaryRT(_renderTargetId);
		}
	}

	EdgeDetectionRenderPass m_ScriptablePass;
	bool _initialized;

	[Serializable]
	public class Settings
	{
		[Range(0,1)]public float _edgeOnly = 0.0f;
		public Color _edgeColor = new Color(1,1,1,1);
		public Color _backgroundColor = new Color(1,1,1,1);
	}
	
	// Call constructor here for only once
	public Settings _settings = new Settings();
	/// <inheritdoc/>
	public override void Create()
	{
		int renderTargetId = Shader.PropertyToID("_TempTargetColorTint0");
		
		m_ScriptablePass = new EdgeDetectionRenderPass(_settings,renderTargetId);
		m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
		_initialized = true;
	}

	// Here you can inject one or multiple render passes in the renderer.
	// This method is called when setting up the renderer once per-camera.
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		if (_initialized)
		{
			m_ScriptablePass.SetTarget(renderer);
			renderer.EnqueuePass(m_ScriptablePass);
		}
	}
}


