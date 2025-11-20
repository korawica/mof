# Modern Object Format (MOF)

**Modern Object Format (MOF)** is a human-friendly data serialization format designed
for easy to pass to CLI.

**Core Principles**:

- 👀 **Human-Friendly**: Easy to read and write for humans.
- ⚙️ **Machine-Parsable**: Structured for easy parsing by machines.

## Why MOF?

JSON is widely used but can be verbose and hard to read for complex configurations.

```json5
// Token: 82
{
  "id": "A001015",
  "items": ["a", "b", "c"],
  "data": [
    {"id": 1, "name": "Item 1"},
    {"id": 2, "name": "Item 2"},
    {"id": 3, "name": "Item 3"}
  ],
  "active": true
}
```

YAML is more readable but can be ambiguous and lacks strict typing.

```yaml
# Token: 74
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
active: true
```

TOON

```toon
# Token: 49
id: A001015
items[3]: a,b,c
data[3]{id,name}:
  1,Item 1
  2,Item 2
  3,Item 3
active: true
```

MOF Representation:

```text
# Token: 56
{
  id = A001015;
  item = [a; b; c];
  data = (id,name) [
    1, Item 1;
    2, Item 2;
    3, Item 3
  ];
  active = true;
}
```

```text
{id=A001015;item=[a;b;c];data=(id,name)[1,Item 1;2,Item 2;3,Item 3];active=true}
```

So, with this format, you can use with CLI tools more effectively.

```shell
command --config "{id=A001015;item=[a;b;c];data=(id,name)[1,Item 1;2,Item 2;3,Item 3];active=true}"
```

## License

This project is licensed under the [MIT License](./LICENSE).
