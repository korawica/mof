# Spec 0.0.3

```text
!mof/1.0.0 {
    # 1. Standard Config
    project = "marketing";
    timeout = 30;

    # 2. Object (เดิมใช้ > ตอนนี้ใช้แบบปกติ)
    # แบบนี้เข้าใจง่ายกว่า ไม่ต้องเรียนรู้ syntax > ใหม่
    extract_job = {
        type = "postgres";
        host = "10.0.0.5";
        
        # Safe Token |...| ยังคงอยู่เพื่อ SQL
        query = |SELECT * FROM "users"|;
    };

    # 3. Table (Schema Array)
    # Parsing เร็วมาก เพราะอ่าน Header ทีเดียว แล้ว loop data ยาวๆ
    mapping = (source, target, type) [
        "id",    "user_id",    "int";
        "name",  "user_name",  "string";
        "email", "user_email", "string";
    ];
}
```

```text
!mof/1.0.0 { project="mkt"; mapping=(src,dst)[id,uid; name,uname]; }
```