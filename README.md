# Aspect URP Repository
My URP Learning Repository.

## Notice: No model or texture assets because of copyright, so here are source files only.

# Contents

## Real-time Rendering cases

### 1. Shadow

### 2. AO

### 3. Ray Tracing

![](Readme/raytracing_rabi.gif)

### 4. GI

## Unity shader cases(Toys)

### **1. PBR Shader**(基于物理渲染的Shader)

Physically Based Rendering

左图为Customed,右图为Unity自带。左图额外添加了闪烁的自发光，并使用了Reflection Probe。

![2024-05-21-21-12-18_converted](Readme/pbr_shader.gif)

### **2. NPR(非真实感渲染)**

Non-Photorealistic Rendering

* **Simple Toon Shader** , 简单卡通着色器，**BlinnPhong + Ramp Texture**

  ![image-20240521234804045](Readme/simple_toon.png)

* **Stylized Toon Shader(风格化卡通着色器)**

  TODO: cel&tone based shading,stylized highlight,Pencil Sketch Shading,Hatching

  tangent

  ![image-20240522002834563](../../../Website/Blog/source/_posts/408/数据结构/图/image-20240522002834563.png)

  

* **NPR Shader For Character**,mainly three schemes, some bugs or incorrect vision exist,please ignore them,do not affect. You can fix them according to your own requirements.

  1. **Girls Frontline**

  ![2024-05-22-01-47-49_converted](Readme/character_girlsFront.gif)

  2. **Guilty Gear Strive/Xrd -------Dizzy**

  ![image-20240522015614919](Readme/character_gg.png)

  3. **Genshin / Star Trail**

  ![](Readme/character_startrail.gif)

### 3. Jade(玉石渲染)

## Post Processing With URP

My another Repo: [aspect-ux/Mini-PostProcessing: a mini post processing system based on urp (github.com)](https://github.com/aspect-ux/Mini-PostProcessing)

### Rendering Tools

# Reference Lists

* NPR
  * [candycat1992/NPR_Lab: :pencil2: Test some NPR in Unity. (github.com)](https://github.com/candycat1992/NPR_Lab)
  * [przemyslawzaworski/Unity3D-CG-programming: Various shaders. (github.com)](https://github.com/przemyslawzaworski/Unity3D-CG-programming)
  * [UnityChanToonShaderVer2_Project/Assets/Toon/Shader at release/legacy/2.0 · unity3d-jp/UnityChanToonShaderVer2_Project (github.com)](https://github.com/unity3d-jp/UnityChanToonShaderVer2_Project/tree/release/legacy/2.0/Assets/Toon/Shader)
