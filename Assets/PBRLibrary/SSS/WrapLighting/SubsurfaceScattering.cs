using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SubsurfaceScattering : ScriptableRendererFeature
{
	class CustomRenderPass : ScriptableRenderPass
	{
		// This method is called before executing the render pass.
		// It can be used to configure render targets and their clear state. Also to create temporary render target textures.
		// When empty this render pass will render to the active camera render target.
		// You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
		// The render pipeline will ensure target setup and clearing happens in a performant manner.
		public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
		{
			// 添加DepthNormalsPass
			ConfigureInput(ScriptableRenderPassInput.Normal);
			/*
			Matrix4x4 view = renderingData.cameraData.GetViewMatrix();  
			Matrix4x4 proj = renderingData.cameraData.GetProjectionMatrix();  
			Matrix4x4 vp = proj * view;  

			// 将camera view space 的平移置为0，用来计算world space下相对于相机的vector  
			Matrix4x4 cview = view;  
			cview.SetColumn(3, new Vector4(0.0f, 0.0f, 0.0f, 1.0f));  
			Matrix4x4 cviewProj = proj * cview;  

			// 计算viewProj逆矩阵，即从裁剪空间变换到世界空间  
			Matrix4x4 cviewProjInv = cviewProj.inverse;  

			// 计算世界空间下，近平面四个角的坐标  
			var near = renderingData.cameraData.camera.nearClipPlane;  
			// Vector4 topLeftCorner = cviewProjInv * new Vector4(-near, near, -near, near);  
			// Vector4 topRightCorner = cviewProjInv * new Vector4(near, near, -near, near);    // Vector4 bottomLeftCorner = cviewProjInv * new Vector4(-near, -near, -near, near);    Vector4 topLeftCorner = cviewProjInv.MultiplyPoint(new Vector4(-1.0f, 1.0f, -1.0f, 1.0f));  
			Vector4 topRightCorner = cviewProjInv.MultiplyPoint(new Vector4(1.0f, 1.0f, -1.0f, 1.0f));  
			Vector4 bottomLeftCorner = cviewProjInv.MultiplyPoint(new Vector4(-1.0f, -1.0f, -1.0f, 1.0f));  

			// 计算相机近平面上方向向量  
			Vector4 cameraXExtent = topRightCorner - topLeftCorner;  
			Vector4 cameraYExtent = bottomLeftCorner - topLeftCorner;  

			near = renderingData.cameraData.camera.nearClipPlane;  

			mMaterial.SetVector(mCameraViewTopLeftCornerID, topLeftCorner);  
			mMaterial.SetVector(mCameraViewXExtentID, cameraXExtent);  
			mMaterial.SetVector(mCameraViewYExtentID, cameraYExtent);  
			mMaterial.SetVector(mProjectionParams2ID, new Vector4(1.0f / near, renderingData.cameraData.worldSpaceCameraPos.x, renderingData.cameraData.worldSpaceCameraPos.y, renderingData.cameraData.worldSpaceCameraPos.z));*/
		}

		// Here you can implement the rendering logic.
		// Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
		// https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
		// You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
		}

		// Cleanup any allocated resources that were created during the execution of this render pass.
		public override void OnCameraCleanup(CommandBuffer cmd)
		{
		}
	}

	CustomRenderPass m_ScriptablePass;

	/// <inheritdoc/>
	public override void Create()
	{
		m_ScriptablePass = new CustomRenderPass();

		// Configures where the render pass should be injected.
		m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
	}

	// Here you can inject one or multiple render passes in the renderer.
	// This method is called when setting up the renderer once per-camera.
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		renderer.EnqueuePass(m_ScriptablePass);
	}
}


