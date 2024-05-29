using System;
using Aspect;
using UnityEngine;
using UnityEngine.Rendering;

namespace AspectPostProcessing
{
	[ExecuteInEditMode]
    [RequireComponent (typeof(Camera))]
    public class PostEffectsBase : MonoBehaviour {
    
	    public enum PostProcessing
	    {
		    None,Bloom,GaussianBlur
	    }

	    protected PostProcessing _postProcessingType = PostProcessing.None;
    	// Called when start
    	protected void CheckResources() {
    		bool isSupported = CheckSupport();
    		
    		if (isSupported == false) {
    			NotSupported();
    		}
    	}
    
    	// Called in CheckResources to check support on this platform
    	protected bool CheckSupport() {
    		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false) {
    			Debug.LogWarning("This platform does not support image effects or render textures.");
    			return false;
    		}
    		
    		return true;
    	}
    
    	// Called when the platform doesn't support this effect
    	protected void NotSupported() {
    		enabled = false;
    	}
    	
    	protected void Start() {
    		CheckResources();
    	}
    
    	// Called when need to create the material used by this effect
    	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material) {
    		if (shader == null) {
    			return null;
    		}
    		
    		if (shader.isSupported && material && material.shader == shader)
    			return material;
    		
    		if (!shader.isSupported) {
    			return null;
    		}
    		else {
    			material = new Material(shader);
    			material.hideFlags = HideFlags.DontSave;
    			if (material)
    				return material;
    			else 
    				return null;
    		}
    	}
    
    	protected virtual void OnEnable()
    	{
	        /*
    		EventManager.Instance.AddEventListener<ScriptableRenderContext,Camera>
	            ("OnPostProcessing",OnPostProcessing);*/
            RenderPipelineManager.endCameraRendering += OnPostProcessing;
    	}
        

        protected virtual void OnDisable()
        {
	        /*
	        EventManager.Instance.RemoveEventListener<ScriptableRenderContext,Camera>
		        ("OnPostProcessing",OnPostProcessing);*/
	        RenderPipelineManager.endCameraRendering -= OnPostProcessing;
        }
        
        protected virtual void OnPostProcessing(ScriptableRenderContext context, Camera camera)
        {
	        Debug.Log("start postprocess " + _postProcessingType);
	        return;
        }
    }
}

