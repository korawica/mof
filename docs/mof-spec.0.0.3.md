# Spec 0.0.3

Parser เขียนง่ายขึ้น: เหลือแค่ Pattern เดียวคือ Key = Value จบ

Consistency: ทุกอย่างในไฟล์จะเป็น Key = Value เหมือนกันหมด ไม่ต้องจำข้อยกเว้น

Review: Syntax data{id,name}: [...]
ที่คุณเสนอมา:

ข้อมูลโค้ด

data{id,name}: [
  1, Item 1;
  2, Item 2
]
ความเห็น: รูปแบบนี้ดู "กระชับ" แต่ในมุมของการเขียน Parser และ Syntax Highlighting ถือว่า "ไม่ค่อยดี" ครับ เพราะ:

Dirty Key: Parser ต้องเสียเวลา Regex ตัว Key (data{id,name}) เพื่อแยกชื่อ (data) ออกจาก Schema (id,name)

Inconsistent: บรรทัดอื่นใช้ key = value แต่อันนี้เอา Schema ไปแปะติดกับ Key ทำให้โครงสร้างไม่เหมือนเพื่อน

ข้อเสนอที่ดีกว่า (Better Design): ย้าย Schema Definition ( ... ) มาอยู่ฝั่งขวา (Value Side) หลังเครื่องหมาย = ครับ รูปแบบ: Key = (Header) [ Data ];

ข้อมูลโค้ด

# แบบนี้ Clean กว่ามาก Parser แยก Key กับ Data ชัดเจน
data = (id, name) [
  1, "Item 1";
  2, "Item 2";
];
MOF v7 (Simplified & Safe Token Edition)
นี่คือ Spec ที่ปรับจูนล่าสุด ตัด > ทิ้ง และใช้ Table Syntax แบบใหม่ที่คุณต้องการครับ

1. กฎเหล็ก (Core Rules)
Assignment: ใช้ = เท่านั้น

Terminator: ใช้ ; จบคำสั่งเสมอ (เพื่อ One-line & Fast Parsing)

No Implicit Type: ถ้าอยากระบุ Type ให้ใส่เป็น Property type = "..." ใน Object เอาตรงๆ (Simple is Best)

2. Table Syntax (The Star Feature)
ข้อมูลโค้ด

# Syntax: Key = (Headers) [ Data ];
# - ( ) : ระบุ Column Name
# - [ ] : เริ่มต้น Data Block
# - ;   : จบ Row (ใน [] ) และ จบคำสั่ง (นอก [])
# - ,   : คั่น Column

users = (id, name, role) [
    1, "Alice", "admin";
    2, "Bob",   "user";
];
3. Full Example (Clean & Safe)
ลองดูหน้าตาเต็มๆ ครับ ว่ามันอ่านง่ายและปลอดภัยแค่ไหน

ข้อมูลโค้ด

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

ทำไมแบบนี้ถึง Parsing เป็น One-line ได้เร็วที่สุด?
เมื่อแปลงเป็น One-line จะได้หน้าตาแบบนี้:

ข้อมูลโค้ด

```text
!mof/1.0.0 { project="mkt"; mapping=(src,dst)[id,uid; name,uname]; }
```

Parsing Algorithm (Speed Check): Parser จะทำงานเป็น State Machine ง่ายๆ (Lookahead แค่ 1 ตัวอักษร):

อ่านเจอ Key -> อ่านเจอ =

เช็คตัวถัดไป:

ถ้าเจอ { -> Parse Object

ถ้าเจอ [ -> Parse Array

ถ้าเจอ ( -> Trigger "Table Mode" (Special Case)

อ่าน Header ใน () เก็บใส่ Cache

อ่าน Data ใน []

Map Data เข้ากับ Header Cache ทันที (Row by Row)

ถ้าเจอ | หรือ " -> Parse String

เจอ ; -> จบ เก็บลง Memory

ความปลอดภัย (Token Safety):

การแยก Schema (..) ออกจาก Key data ทำให้ไม่มีอักขระพิเศษไปปนใน Key

การใช้ ; คั่นระหว่าง Row ใน Table [ 1, 2; 3, 4 ] ทำให้ ไม่สับสนกับ Comma ที่อาจจะอยู่ในข้อมูล (เช่น Item 1, Description)

ถ้าข้อมูลมี ; ก็แค่ใส่ Quote "Item 1; Desc" หรือใช้ |Item 1; Desc| ก็จบปัญหา

สรุป

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

---

Nested Fields in Tables

```text
jobs = (id, name, config:timeout, config:retry) [
    1, "Cleanup", 30, 1;
    2, "Ingest",  60, 3;
];
```