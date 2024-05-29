using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StarManager : MonoBehaviour {
    public GameObject pre;

    float time = 0.5f;
    float timer = 0;

    void Update () {
        timer += Time.deltaTime;
        if(timer<time){
            return;
        }
        timer = 0;
        time = Random.Range (0, 5) * 0.3f;

        GameObject go = GameObject.Instantiate (pre);
        go.transform.position = new Vector2 (random(),random());
    }

    private float random(){
        return (Random.Range(0, 4) * 0.7f)+4f;
    }
}