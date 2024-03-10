using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshFilter))]
public class RayTracingObject : MonoBehaviour
{
	void Awake()
	{
		RayTracingDriver.RegisterObject(this);
	}
	private void OnEnable()
	{
		
	}
	
	void Start()
	{
		//temp
		
	}

	private void OnDisable()
	{
		RayTracingDriver.UnregisterObject(this);
	}
}