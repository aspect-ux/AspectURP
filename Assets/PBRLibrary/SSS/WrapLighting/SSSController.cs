using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
 
 
public class SSSController : MonoBehaviour
{
	public Transform directionalLight;
	public Material mat;
	public Camera lightCamera;
	
	CommandBuffer cb;
	
	private RenderTexture m_depthTexture;
	
	public Shader depthShader;
	
	public RenderTextureFormat format = RenderTextureFormat.Shadowmap;
	public LightEvent LightEvent= LightEvent.AfterShadowMap;	
	
	bool isAdd = false;
	
	void OnEnable()
	{
		RenderPipelineManager.endCameraRendering += OnRenderSSS;
	}
	
	void OnDisable()
	{
		RenderPipelineManager.endCameraRendering -= OnRenderSSS;
	}
 
	void Start ()
	{
		m_depthTexture = new RenderTexture ((int)Camera.main.pixelWidth, (int)Camera.main.pixelHeight, 24);
		m_depthTexture.hideFlags = HideFlags.DontSave;
		directionalLight = GameObject.Find("Directional Light").transform;
		
		// 用于为DirectionalLight生成深度图
		GameObject go = lightCamera.gameObject;
		go.transform.position = directionalLight.position;
		go.transform.rotation = directionalLight.rotation;
		
		lightCamera = go.GetComponent<Camera>();
		//lightCamera.farClipPlane = farClipPlaneDist;//此种方案的缺陷，精度不够，必须把远裁剪面调小,自调
		lightCamera.enabled = false;
		
		// not supported in srp
		//lightCamera.depthTextureMode |= DepthTextureMode.Depth;  
	}
	
	void Update()
	{
		//Camera.Render cannot be put in srp because of recursive render
		if (null != depthShader) {
			lightCamera.targetTexture = m_depthTexture;
			lightCamera.RenderWithShader(depthShader, "");
			mat.SetTexture("_BackDepthTex", m_depthTexture);
		}
	}
	
	void OnRenderSSS(ScriptableRenderContext context, Camera camera)
	{
		
		if (lightCamera != null)
		{
			// 使用lightCamera充当光照以便参与计算
			Matrix4x4 lightTexMatrix = lightCamera.projectionMatrix * lightCamera.worldToCameraMatrix * Matrix4x4.identity;
			mat.SetFloat ("_CamNearPlane", lightCamera.nearClipPlane);
			mat.SetFloat ("_CamFarPlane", lightCamera.farClipPlane);
			mat.SetMatrix ("_WolrdtoLightMatrix", lightCamera.worldToCameraMatrix);
			mat.SetMatrix ("_LightVPMatrix", lightTexMatrix);
		}
		
		
		//AddLightShadowMap();
	}
	
	void AddLightShadowMap()
	{
		// 直接用光源的shadowmap当深度图，而不是重新计算
		//if (!isAdd)
		{
				RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
				RenderTexture m_ShadowmapCopy = new RenderTexture(Screen.width, Screen.height, 0);
				m_ShadowmapCopy.format = RenderTextureFormat.RInt;
				cb = new CommandBuffer();
				cb.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
				cb.Blit(shadowmap, new RenderTargetIdentifier(m_ShadowmapCopy));
				Shader.SetGlobalTexture("_CustomShadowMap", m_ShadowmapCopy);
				var light = directionalLight.gameObject.GetComponent<Light>();
				light.AddCommandBuffer(LightEvent, cb);
				isAdd = true;
		}   
	}
}