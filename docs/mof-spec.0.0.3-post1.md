# Spec 0.0.3

MOF v0.0.3 - Syntax Reference Tables

## Core Syntax Elements

| Element     | Syntax          | Description                             | Example                   |
|-------------|-----------------|-----------------------------------------|---------------------------|
| Assignment  | `key = value;`  | Universal pattern for all declarations  | `project = "marketing";`  |
| Terminator  | `;`             | Required at the end of every statement  | `timeout = 30;`           |
| Comment     | `#`             | Single-line comment                     | `# This is a comment`     |
| File Header | `!mof/x.x.x`    | Version declaration at file start       | `!mof/1.0.0`              |

## Data Type Syntax

| Type            | Syntax              | Description                            | Example                              |
|-----------------|---------------------|----------------------------------------|--------------------------------------|
| String (Quoted) | `"..."`             | Standard string with escape sequences  | `name = "Alice";`                    |
| String (Raw)    | `\| ... \|`         | Raw string literal, no escaping needed | `query = \|SELECT * FROM "users"\|;` |
| Number          | `123, 45.67`        | Integer or decimal (no type inference) | `timeout = 30;`<br>`rate = 0.95;`    |
| Boolean         | `true, false`       | Lowercase boolean literals             | `active = true;`                     |
| Object          | `{ key = value; }`  | Nested key-value pairs                 | `config = { host = "localhost"; };`  |
| Table           | `(headers) [data]`  | Schema-based array with column headers | `users = (id, name) [1, "Alice";];`  |
| Array           | `[value1, value2]`  | Simple list of values (if supported)   | `roles = ["admin", "user"];`         |

## Table Syntax Components

| Component         | Syntax              | Description                        | Example                  |
|-------------------|---------------------|------------------------------------|--------------------------|
| Header Definition | `(col1, col2, ...)` | Column names in parentheses        | `(id, name, role)`       |
| Data Block        | `[...]`             | Data rows in square brackets       | `[1, "Alice", "admin";]` |
| Row Separator     | `;`                 | Separates rows within data block   | `1, "Alice"; 2, "Bob";`  |
| Column Separator  | `,`                 | Separates values within a row      | `1, "Alice", "admin"`    |
| Nested Field      | `parent.child`      | Dot notation for nested structures | `config.timeout`         | 

## Complete Table Examples

| Pattern             | Syntax                                                   | Output Structure                                          |
|---------------------|----------------------------------------------------------|-----------------------------------------------------------|
| Simple Table        | `users = (id, name) [1, "Alice"; 2, "Bob";];`            | `[{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]`  |
| Nested Fields       | `jobs = (id, config.timeout, config.retry) [1, 30, 1;];` | `[{"id": 1, "config": {"timeout": 30, "retry": 1}}]`      |
| Multi-level Nesting | `data = (id, a.b.c) [1, "value";];`                      | `[{"id": 1, "a": {"b": {"c": "value"}}}]`                 |

## String Literal Comparison

| Type          | Syntax    | Escaping              | Use Case                 | Example                            |
|---------------|-----------|-----------------------|--------------------------|------------------------------------|
| Quoted String | `"..."`   | Required (\", \\, \n) | General text             | `msg = "Hello \"World\"";`         | 
| Raw String    | `\|...\|` | Not needed            | SQL, Regex, Multi-line   | `sql = \|SELECT * FROM "users"\|;` |

## Type Handling

| Approach         | Syntax                                     | Pros                       | Cons                       | Status         |
|------------------|--------------------------------------------|----------------------------|----------------------------|----------------|
| No Type System   | `value = 123;`                             | Simple parser              | App handles conversion     | ✅ Current      |
| Type as Property | `config = { value = 123; type = "int"; };` | Explicit, no syntax change | Verbose                    | ✅ Recommended  |
| Type Annotation  | `value:int = 123;`                         | Concise                    | Breaks key = value pattern | ❌ Out of Scope |

## Parsing State Machine (Lookahead Rules)

| After = Character | Next Action                      | Data Type            |
|-------------------|----------------------------------|----------------------|
| `{`               | Parse Object                     | Object               |
| `(`               | Parse Table (read headers first) | Table                |
| `[`               | Parse Array                      | Array (if supported) |
| `"`               | Parse Quoted String              | String               |
| `\|`              | Parse Raw String                 | String               |
| Digit/`-`         | Parse Number                     | Number               |
| `true/false`      | Parse Boolean                    | Boolean              |
