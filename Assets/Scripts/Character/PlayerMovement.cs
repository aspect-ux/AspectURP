using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    // 角色移动速度
    public float moveSpeed = 5f;
    // 角色跳跃力
    public float jumpForce = 10f;
    // 角色重力加速度
    public float gravity = -9.8f;
    // 角色动画控制器
    public Animator animator;
    // 角色刚体组件
    private Rigidbody rb;
    // 角色速度向量
    private Vector3 velocity;
    // 角色是否在地面上
    private bool isGrounded;

    void Start()
    {
        // 获取角色刚体组件
        rb = GetComponent<Rigidbody>();
    }

    void Update()
    {
        // 获取水平和垂直方向的输入
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");

        // 计算角色移动方向
        Vector3 direction = new Vector3(horizontal, 0, vertical).normalized;

        // 如果有移动方向
        if (direction.magnitude > 0.1f)
        {
            // 计算角色面向的角度
            float targetAngle = Mathf.Atan2(direction.x, direction.z) * Mathf.Rad2Deg;
            // 插值旋转角色
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.Euler(0, targetAngle, 0), 0.1f);
            // 计算角色移动速度
            velocity = direction * moveSpeed;
            // 设置动画参数为移动状态
            animator.SetFloat("Speed", 1f);
        }
        else
        {
            // 设置动画参数为静止状态
            animator.SetFloat("Speed", 0f);
        }

        // 如果按下空格键并且角色在地面上
        if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
        {
            // 给角色一个向上的力
            rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
            // 设置动画参数为跳跃状态
            animator.SetBool("IsJumping", true);
            // 设置角色不在地面上
            isGrounded = false;
        }

        // 计算角色受重力影响的速度
        velocity.y += gravity * Time.deltaTime;
    }

    void FixedUpdate()
    {
        // 移动角色
        rb.MovePosition(rb.position + velocity * Time.fixedDeltaTime);
    }

    void OnCollisionEnter(Collision collision)
    {
        // 如果角色碰到地面
        if (collision.gameObject.CompareTag("Ground"))
        {
            // 设置角色在地面上
            isGrounded = true;
            // 设置动画参数为非跳跃状态
            animator.SetBool("IsJumping", false);
        }
    }
}
