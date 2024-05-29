using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace Utils
{
	public class Rotate : MonoBehaviour
	{
		public float rotateSpeed = 40f;
		// Start is called before the first frame update
		void Start()
		{
			
		}

		// Update is called once per frame
		void Update()
		{
			// 自转
			transform.Rotate(Vector3.down * rotateSpeed * Time.deltaTime);
		}
	}
}

