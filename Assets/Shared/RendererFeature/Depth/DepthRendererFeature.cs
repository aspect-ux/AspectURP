using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthRendererFeature : ScriptableRendererFeature
{
	[System.Serializable]
	public class Settings
	{
		public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
		public Material depthMat = null;
		public Material sssMat = null;
		//public int depthMatPassIndex = -1;
		//目标RenderTexture 
		public RenderTexture renderTexture = null;

	}
	public Settings settings = new Settings();
	private CustomPass blitPass;
	

	public override void Create()
	{
		blitPass = new CustomPass(name, settings);
	}

	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		if (settings.depthMat == null)
		{
			Debug.LogWarningFormat("丢失blit材质");
			return;
		}
		blitPass.renderPassEvent = settings.renderPassEvent;
		blitPass.Setup(renderer.cameraDepthTarget);
		renderer.EnqueuePass(blitPass);
	}
	
	
public class CustomPass : ScriptableRenderPass
{
	private Settings settings;
	string m_ProfilerTag;
	RenderTargetIdentifier source;
	int _renderTargetId0;
	
	private static readonly int m_DepthTexID = Shader.PropertyToID("_BackDepthTex");
	
	private static readonly int m_BuiltinDepthID = Shader.PropertyToID("_CameraDepthTexture");

	public CustomPass(string tag, Settings settings)
	{
		m_ProfilerTag = tag;
		this.settings = settings;
	}

	public void Setup(RenderTargetIdentifier src)
	{
		source = src;
	}
	
	public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData) {
		_renderTargetId0 = Shader.PropertyToID("_ImageFilterResult");
		
		var lightCamera = GameObject.Find("lightCamera").GetComponent<Camera>();
		var mat = settings.sssMat;
		
		if (lightCamera != null)
		{
			// 使用lightCamera充当光照以便参与计算
			Matrix4x4 lightTexMatrix = lightCamera.projectionMatrix * lightCamera.worldToCameraMatrix * Matrix4x4.identity;
			mat.SetFloat ("_CamNearPlane", lightCamera.nearClipPlane);
			mat.SetFloat ("_CamFarPlane", lightCamera.farClipPlane);
			mat.SetMatrix ("_WolrdtoLightMatrix", lightCamera.worldToCameraMatrix);
			mat.SetMatrix ("_LightVPMatrix", lightTexMatrix);
			//Debug.Log("error");
		}
	}

	public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
	{
		CommandBuffer command = CommandBufferPool.Get(m_ProfilerTag);
		
		var target = renderingData.cameraData.targetTexture;
		// 1. simple blit
		command.Blit(null,settings.renderTexture,settings.depthMat,0);
		
		// 2. 
		//command.Blit(null, _renderTargetId0, settings.depthMat,0);
		//command.Blit(_renderTargetId0,settings.renderTexture);
		//settings.depthMat.SetTexture("_BackDepthTex",_renderTargetId0);
		//command.SetGlobalTexture(m_DepthTexID, settings.renderTexture);
		//command.Blit(_renderTargetId0,m_DepthTexID);
		
		// 不透明物体渲染完才有深度贴图，所以先将_CameraDepthTexture暂存起来
		//command.Blit(m_BuiltinDepthID,_renderTargetId0);
		//command.Blit(_renderTargetId0,m_DepthTexID);
		
		context.ExecuteCommandBuffer(command);
		CommandBufferPool.Release(command);
	}
	
	public override void OnCameraCleanup(CommandBuffer cmd) {

		cmd.ReleaseTemporaryRT(_renderTargetId0);
	}
}
}

