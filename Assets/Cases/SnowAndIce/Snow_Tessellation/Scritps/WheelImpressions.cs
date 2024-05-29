using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WheelImpressions : MonoBehaviour {

	public Shader _impressShader;
	public GameObject _terrain;
	public Transform[] _wheels;

	[Range(0, 2)]
	public float _bSize;

	[Range(0, 1)]
	public float _bStrength;

	private Material _snowMat;
	private Material _drawMat;
	private RenderTexture _splatmap;
	private RaycastHit _hit;
	private int _mask;

	// Use this for initialization
	void Start () {
		_mask = LayerMask.GetMask("Ground");

		_drawMat = new Material(_impressShader);
		_snowMat = _terrain.GetComponent<MeshRenderer>().material; // tesselation shader
		_splatmap = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGBFloat);
		_snowMat.SetTexture("_Splatmap", _splatmap);
	}

	// Update is called once per frame
	void Update() {
		for (int i = 0; i < _wheels.Length; i++)
		{
			// raycasting towards mesh
			if (!Physics.Raycast(_wheels[i].position, - Vector3.up, out _hit, 3f, _mask))
			{
				continue;
			}

			_drawMat.SetVector("_Coordinates", new Vector4(_hit.textureCoord.x, _hit.textureCoord.y, 0, 0));
			_drawMat.SetFloat("_Strength", _bStrength);
			_drawMat.SetFloat("_Size", _bSize);
			RenderTexture tmp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
			Graphics.Blit(_splatmap, tmp);
			Graphics.Blit(tmp, _splatmap, _drawMat);
			RenderTexture.ReleaseTemporary(tmp);

		}
	}
}
