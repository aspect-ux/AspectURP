using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Star : MonoBehaviour {

    Rigidbody2D rigidbody;

    public float x = -5;
    public float y = -1;

    Camera cam;
    float size = -1;

    private Shader trailShader;
    private Material trailMat;

    void Awake(){
        rigidbody = this.GetComponent<Rigidbody2D> ();
        rigidbody.velocity = new Vector2 (x,y);

        cam = Camera.main;
        float height = 2f * cam.orthographicSize;
        size = height;
    }

    void OnEnable()
    {
        StopAllCoroutines();
        StartCoroutine(CoUpdate());
    }

    private void Start()
    {
        if (!trailShader)
            trailShader = Shader.Find("AspectURP/Sky/MeteorTrail");
        if (!trailShader) 
            Debug.LogError("trail shader not found!");
        trailMat = new Material(trailShader);
    }

    private void Update()
    {
        // To be fixed
        //trailMat.SetColor(GetComponent<TrailRenderer>().color);
    }

    IEnumerator CoUpdate()
    {
        while(true)
        {
            if(IsBehind())
            {
                break;
            }
            yield return new WaitForSeconds(1);;
        }
        StopCoUpdate();
    }

    void StopCoUpdate()
    {
        GameObject.Destroy (gameObject);
        StopAllCoroutines();
    }

    bool IsBehind()
    {
        //判断是否超出屏幕一定距离
        float distance = Vector2.Distance(transform.position, cam.transform.position);
        if (distance > size / 2f) {
            return true;
        }
        return false;
    }
}