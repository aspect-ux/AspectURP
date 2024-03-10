#ifndef __RAYTRACING_DATA_H__
#define __RAYTRACING_DATA_H__

//-------------------------------------
//- SPHERES

struct Sphere
{
    float3 position;
    float radius;
    float3 albedo;
    float3 specular;
    float smoothness;
    float3 emission;
};

StructuredBuffer<Sphere> _Spheres;


//-------------------------------------
//- MESHES

struct MeshObject
{
	float4x4 localToWorldMatrix;
	int indices_offset;
	int indices_count;
};

StructuredBuffer<MeshObject> _MeshObjects;
StructuredBuffer<float3> _Vertices;
StructuredBuffer<int> _Indices;


#endif