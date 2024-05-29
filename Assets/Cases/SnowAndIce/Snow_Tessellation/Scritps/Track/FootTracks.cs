using UnityEngine;

public class FootTracks : MonoBehaviour
{
	public Shader drawShader;
	private RenderTexture splatMap;
	private Material snowMaterial, drawMaterial, waterMaterial;

	public Transform[] foot;

	[Range(0.996f, 1f)]
	public float Atten = 0.996f;
	private float atten;


	[Range(1, 16)]
	public float BrushSize = 1;

	[Range(0, 1)]
	public float BrushStrength = 0;

	private LayerMask layer;
	public GameObject Ground;
	public GameObject Water;

	// Start is called before the first frame update
	private void Start()
	{
		layer = LayerMask.GetMask("Ground");

		drawMaterial = new Material(drawShader);
		drawMaterial.SetVector("_Color", Color.red);

		snowMaterial = Ground.GetComponent<MeshRenderer>().material;
		splatMap = new RenderTexture(2048, 2048, 0, RenderTextureFormat.ARGBFloat);
		snowMaterial.SetTexture("_MaskTex", splatMap);

		waterMaterial = Water.GetComponent<MeshRenderer>().material;
		waterMaterial.SetTexture("_SplatMap", splatMap);

	}

	// Update is called once per frame
	private void Update()
	{
		if (atten != Atten)
		{
			atten = Atten;
			drawMaterial.SetFloat("_Atten", Atten);
		}

		RaycastHit hit;
		for (int i = 0; i < foot.Length; ++i)
		{
			if (Physics.Raycast(foot[i].position, Vector3.down, out hit, 0.2f, layer))
			{
				drawMaterial.SetVector("_Coordinate", new Vector4(hit.textureCoord.x, hit.textureCoord.y, 0, 0));
				drawMaterial.SetFloat("_Strength", BrushStrength);
				drawMaterial.SetFloat("_Size", BrushSize);

				RenderTexture temp = RenderTexture.GetTemporary(splatMap.width, splatMap.height, 0, RenderTextureFormat.ARGBFloat);
				Graphics.Blit(splatMap, temp);
				Graphics.Blit(temp, splatMap, drawMaterial);
				RenderTexture.ReleaseTemporary(temp);
			}
		}
		
	}

	// 在GUI上绘制Splatmap
	/*private void OnGUI()
	{
		GUI.DrawTexture(new Rect(0, 0, 512, 512), splatMap, ScaleMode.ScaleToFit, false, 1);
	}*/
} 