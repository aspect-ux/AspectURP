using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace Aspect.Rendering.PBR
{
[ExecuteAlways]
public class PreCompute : MonoBehaviour
{
	public ComputeShader genIrradianceMapShader;
	// Start is called before the first frame update
	void Start()
	{
		
	}

	// Update is called once per frame
	void Update()
	{
		
	}
	
	void PrefilterDiffuseCubemap(Cubemap envCubemap,out Cubemap outputCubemap) 
	{
		int size = 128;
		outputCubemap = new Cubemap(size, TextureFormat.RGBAFloat, false);
		ComputeBuffer reslutBuffer = new ComputeBuffer(size * size, sizeof(float) * 4);
		Color[] tempColors = new Color[size * size];
		for (int face = 0; face < 6; ++face)
		{
			genIrradianceMapShader.SetInt("_Face", face);
			genIrradianceMapShader.SetTexture(0, "_Cubemap", envCubemap);
			genIrradianceMapShader.SetInt("_Resolution", size);
			genIrradianceMapShader.SetBuffer(0, "_Reslut", reslutBuffer);
			genIrradianceMapShader.Dispatch(0, size / 8, size / 8, 1);
			reslutBuffer.GetData(tempColors);
			outputCubemap.SetPixels(tempColors, (CubemapFace)face);
		}
		reslutBuffer.Release();
		outputCubemap.Apply();
	}
	
	Vector3[] BakeSH(Cubemap map)
	{
		Vector3[] coefficients = new Vector3[9];
		float[] sh9 = new float[9];
		for (int face = 0; face < 6; ++face)
		{
			 var colos = map.GetPixels((CubemapFace)face);
			for (int texel = 0; texel < map.width * map.width; ++texel)
			{
				float u = (texel % map.width) / (float)map.width;
				float v = ((int)(texel / map.width)) / (float)map.width;
				Vector3 dir = DirectionFromCubemapTexel(face, u, v);
				Color radiance = colos[texel];
				float d_omega = DifferentialSolidAngle(map.width, u, v);
				HarmonicsBasis(dir, sh9);
				for (int c = 0; c < 9; ++c)
				{
					float sh = sh9[c];
					coefficients[c].x += radiance.r * d_omega * sh ;
					coefficients[c].y += radiance.g * d_omega * sh ;
					coefficients[c].z += radiance.b * d_omega * sh ;

				}
			}
		}
		return coefficients;
	}

	public static Vector3 DirectionFromCubemapTexel(int face, float u, float v)
	{
		Vector3 dir = Vector3.zero;

		switch (face)
		{
			case 0: //+X
				dir.x = 1;
				dir.y = v * -2.0f + 1.0f;
				dir.z = u * -2.0f + 1.0f;
				break;

			case 1: //-X
				dir.x = -1;
				dir.y = v * -2.0f + 1.0f;
				dir.z = u * 2.0f - 1.0f;
				break;

			case 2: //+Y
				dir.x = u * 2.0f - 1.0f;
				dir.y = 1.0f;
				dir.z = v * 2.0f - 1.0f;
				break;

			case 3: //-Y
				dir.x = u * 2.0f - 1.0f;
				dir.y = -1.0f;
				dir.z = v * -2.0f + 1.0f;
				break;

			case 4: //+Z
				dir.x = u * 2.0f - 1.0f;
				dir.y = v * -2.0f + 1.0f;
				dir.z = 1;
				break;

			case 5: //-Z
				dir.x = u * -2.0f + 1.0f;
				dir.y = v * -2.0f + 1.0f;
				dir.z = -1;
				break;
		}

		return dir.normalized;
	}

  	public static float DifferentialSolidAngle(int textureSize, float U, float V)
	{
		float inv = 1.0f / textureSize;
		float u = 2.0f * (U + 0.5f * inv) - 1;
		float v = 2.0f * (V + 0.5f * inv) - 1;
		float x0 = u - inv;
		float y0 = v - inv;
		float x1 = u + inv;
		float y1 = v + inv;
		return AreaElement(x0, y0) - AreaElement(x0, y1) - AreaElement(x1, y0) + AreaElement(x1, y1);
	}

   	public static float AreaElement(float x, float y)
	{
		return Mathf.Atan2(x * y, Mathf.Sqrt(x * x + y * y + 1));
	}

	const float sh0_0 = 0.28209479f;
	const float sh1_1 = 0.48860251f;
	const float sh2_n2 = 1.09254843f;
	const float sh2_n1 = 1.09254843f;
	const float sh2_0 = 0.31539157f;
	const float sh2_1 = 1.09254843f;
	const float sh2_2 = 0.54627421f;

	void HarmonicsBasis(Vector3 pos, float[] sh9)
	{
		Vector3 normal = pos;
		float x = normal.x;
		float y = normal.y;
		float z = normal.z;
		sh9[0] = sh0_0;
		sh9[1] = sh1_1 * y;
		sh9[2] = sh1_1 * z;
		sh9[3] = sh1_1 * x;
		sh9[4] = sh2_n2 * x * y;
		sh9[5] = sh2_n1 * z * y;
		sh9[6] = sh2_0 * (2 * z * z - x * x - y * y);// (-x * x - z * z + 2 * y * y);
		sh9[7] = sh2_1 * z * x;
		sh9[8] = sh2_2 * (x * x - y * y);
	}
}
}

