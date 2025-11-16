# Modern Object Format (MOF)

**Modern Object Format (MOF)** is a human-friendly data serialization format designed
for easy to pass to CLI.

The Core principles of MOF are:

- **Human-Friendly**: Easy to read and write for humans.
- **Machine-Parsable**: Structured for easy parsing by machines.
- **CLI Supported**: Supported by command-line tools for validation and conversion.

## Why MOF?

JSON is widely used but can be verbose and hard to read for complex configurations.

```json
{
  "id": "A001015",
  "items": ["a", "b", "c"],
  "data": [
    {"id": 1, "name": "Item 1"},
    {"id": 2, "name": "Item 2"},
    {"id": 3, "name": "Item 3"}
  ]
}
```

YAML is more readable but can be ambiguous and lacks strict typing.

```yaml
id: "A001015"
items:
  - "a"
  - "b"
  - "c"
data:
  - id: 1
    name: "Item 1"
  - id: 2
    name: "Item 2"
  - id: 3
    name: "Item 3"
```

TOON

```toon
id: A001015
items[3]: a,b,c
data[3]{id,name}:
  1,Item 1
  2,Item 2
  3,Item 3
```

MOF Representation:

```text
{id:A001015;item[a,b,c];data{id,name}:[1,Item 1;2,Item 2;3,Item 3]}
```

## Key Features

| Data Type            | MOF Syntax                                                                         | Description                       |
|----------------------|------------------------------------------------------------------------------------|-----------------------------------|
| String               | `key: "value"`                                                                     | Quoted or unquoted strings        |
| Multi-line String    | `key:\|`<br>`  Line 1`<br>`  Line 2`<br>`\|`                                       | Multi-line text                   |
| Integer              | `key: 123`                                                                         | Integer values                    |
| Float                | `key: 3.14`                                                                        | Floating-point numbers            |
| Boolean              | `key: true`<br>`key: false`                                                        | Boolean values                    |
| Null                 | `key: null`                                                                        | Null value                        |
| Date                 | `key: 2025-11-16`                                                                  | Date values                       |
| DateTime             | `key: 2025-11-16T07:14:51Z`                                                        | DateTime values                   |
| Object               | `key: {key1: value1, key2: value2}`                                                | Key-value pairs                   |
| Array                | `key: [item1, item2, item3]`                                                       | List of items                     |
| Tabular Array        | `key[N]{col1,col2}:`<br>`  row1_col1,row1_col2;`<br>`  row2_col1,row2_col2`<br>`;` | Table with N rows and columns     |
| Environment Variable | `key: ${VAR}`<br>`key: ${VAR=default}`                                             | Environment variable substitution |


```text
# 1. KEY-VALUE SEPARATOR
key: value
multi-line: |
  Line 1
  Line 2
|
int: 1_000_000
float: 3.14
scientific: 1.5e10

flag: true
empty: null
pending: notset

date: 2025-11-16
datetime: 2025-11-16T07:14:51Z

required: ${VAR}
optional: ${VAR=default}
nested: ${env.project-id}

@include: @path(file.mof),
@include: @path(file.mof) => section,

string: "Escaped \: colon and \, comma"

path: @path(gs://bucket/file)
secret: @secret(SECRET_NAME)
regex: /^\d{3}-\d{2}-\d{4}$/

# 2. OBJECT (braces with comma or newline)
object: {key1: value1, key2: value2}
object: {
  key1: value1
  key2: value2
}

# 3. ARRAY (brackets with comma or newline)
array: [item1, item2, item3]
array: [
  item1
  item2
  item3
]

# 4. TABULAR ARRAY (MUST end with semicolon)
table[N]{col1,col2}:
  row1_col1,row1_col2
  row2_col1,row2_col2
;

# 5. ONE-LINE (commas required, semicolon for tabular end)
!mof/1.0.0 {key: value, arr: [a, b], tbl[2]{x,y}: 1,2 3,4; next: val}

# 6. MULTI-LINE (newlines = implicit separators)
!mof/1.0.0 {
  key: value
  arr: [a, b, c]
  tbl[2]{x,y}:
    1,2
    3,4
  ;
  next: val
}
```

```text
obj: {key1: value1; key2: value2}
arr: [item1; item2; item3]
table[2]{col1; col2}: {
  val1,val2;
  val3,val4
}
```

```text
!mof/1.0.0 {obj: {k: v}; arr: [a; b]; table[2]{x; y}:1,2;3,4}
```

### Secure

```text
!mof/1.0.0 {
  database: {
    host: ${DB_HOST=localhost},
    port: ${DB_PORT=5432},
    username: ${DB_USER},
    password: @secret(DB_PASSWORD),              # ✅ Explicit secret
    ssl-cert: @path(@secret(SSL_CERT_PATH)),     # ✅ Composable
    connection-string: "postgresql://${DB_USER}:@secret(DB_PASSWORD)@${DB_HOST}:${DB_PORT}/mydb"
  }
}
```

## License

This project is licensed under the [MIT License](./LICENSE).
