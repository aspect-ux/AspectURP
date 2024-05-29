using System.Collections;
using System.Collections.Generic;
using UnityEngine;
 
[ExecuteInEditMode]
public class DayInAndOut : MonoBehaviour
{
	public enum RotateSubject
	{
		DirectionalLight,Model
	}

	public RotateSubject rotateSubject;

	private Transform m_transform;
	public Transform m_Character;
	
	public bool autoRotate;
	
	[Range(0.0f,20f)] public float autoRotateSpeed;

	[Range(0, 720)] public int rotateAngle = 0;
	private int lastAngle = 0;
	
	private Quaternion startRotation, lastRotation;
	bool isAngleChanged = false;
	
	float counter = 0.5f;

	void Start () {
		m_transform = GameObject.Find("Directional Light").GetComponent<Transform>();
		startRotation = gameObject.transform.rotation;
		//lastRotation = startRotation;
	}
	

	void Update () {
		
		//simple simulation automatically
		//m_transform.Rotate(Vector3.down * 20f * Time.deltaTime);
		
		OnTimeFly();

		// 角色自旋转
		if (rotateSubject == RotateSubject.Model)
		{
			m_transform = m_Character;
			//m_Character.Rotate(Vector3.down * 20f);
		}
		else
		{
			// 只有从 character模式 到 directionalLight模式才 调用
			if (m_transform == m_Character)
				m_transform = GameObject.Find("Directional Light").GetComponent<Transform>();
		}
		
		if (counter > 0)
		{
			counter -= Time.deltaTime;
			return;
		}
		counter = 0.5f;
		if(autoRotate)
		{
			m_transform.Rotate(Vector3.down * 40 * 0.5f);
		}
	}

	void OnTimeFly()
	{
		// 如果rotation角度发生改变
		if (isAngleChanged)
		{
			var angleDiff = rotateAngle - lastAngle;
			m_transform.Rotate(Vector3.down * angleDiff * 0.5f);
			isAngleChanged = false;
			//lastRotation = startRotation;
			lastAngle = rotateAngle;
		}
		else
		{
			if (lastAngle != rotateAngle)
				isAngleChanged = true;
		}
	}
	
}