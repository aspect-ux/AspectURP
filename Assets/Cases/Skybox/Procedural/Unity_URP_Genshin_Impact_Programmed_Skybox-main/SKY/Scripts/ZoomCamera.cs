using UnityEngine;  
  
public class ZoomCamera : MonoBehaviour  
{  
    public float zoomSpeed = 10f; // 缩放速度  
    public float minDistance = 1f; // 最小距离  
    public float maxDistance = 10f; // 最大距离  
  
    private Camera camera;  
    private Vector3 originalPosition;  
  
    void Start()  
    {  
        camera = GetComponent<Camera>();  
        originalPosition = transform.position;  
    }  
  
    void Update()  
    {  
        if (Input.GetAxis("Mouse ScrollWheel") != 0)  
        {  
            float scroll = Input.GetAxis("Mouse ScrollWheel") * zoomSpeed * Mathf.Sign(Input.GetAxis("Mouse ScrollWheel"));  
            float currentDistance = (transform.position - originalPosition).magnitude;  
  
            float newDistance = Mathf.Clamp(currentDistance - scroll, minDistance, maxDistance);  
  
            transform.position = originalPosition + (transform.position - originalPosition).normalized * newDistance;  
        }  
    }  
}