using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawWithMouse : MonoBehaviour
{
    public Camera camera;
    public Shader drawShader;

    private RenderTexture splatMap;
    private Material snowMaterial, drawMaterial;
    private RaycastHit hit;

    [Range(1, 500)]
    public float BrushSize = 1;

    [Range(0, 1)]
    public float BrushStrength = 0;

    // Start is called before the first frame update
    private void Start()
    {
        drawMaterial = new Material(drawShader);
        drawMaterial.SetVector("_Color", Color.red);

        snowMaterial = GetComponent<MeshRenderer>().material;
        splatMap = new RenderTexture(2048, 2048, 0, RenderTextureFormat.ARGBFloat);
        snowMaterial.SetTexture("_MaskTex", splatMap);
    }

    // Update is called once per frame
    private void Update()
    {
        if (Input.GetKey(KeyCode.Mouse0))
        {
            if (Physics.Raycast(camera.ScreenPointToRay(Input.mousePosition), out hit))
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

    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0, 0, 512, 512), splatMap, ScaleMode.ScaleToFit, false, 1);
    }
}