# MOF (Modern Object Format) v1.0.0 – Final Core Feature Summary

## 1. Purpose

MOF is a human-readable, machine-friendly configuration format optimized for Data Engineering workflows:
- Easy to maintain in version control (clear diffs)
- Compact enough for one-line CLI passing
- Safe handling of secrets and environment variability
- Supports structured, tabular, and multi-line data

## 2. Core Design Principles

1. Predictable: Explicit delimiters and unambiguous grammar
2. Readable: Minimal punctuation, optional formatting whitespace
3. Composable: Includes, variables, secrets, tabular data
4. Safe: Secrets never stored as plain text in config logic
5. Portable: One parser design across languages
6. Dual-mode: Multi-line (human) ↔ One-line (CLI) lossless conversion

## 3. Version Declaration
Every file begins with a version header:
```mof
!mof/1.0.0 {
  ...
}
```
The curly brace after version encloses the root object.

## 4. Fundamental Syntax Tokens
| Element                     | Meaning                                                                          |
|-----------------------------|----------------------------------------------------------------------------------|
| `:`                         | Key–value separator                                                              |
| `{ }`                       | Object delimiters                                                                |
| `[ ]`                       | Array delimiters                                                                 |
| `;`                         | Statement separator (required in one-line; optional after newline in multi-line) |
| `#`                         | Comment prefix                                                                   |
| `${VAR}` / `${VAR=default}` | Variable substitution                                                            |
| `@include:`                 | Include directive                                                                |
| `@secret(...)`              | Secret reference                                                                 |
| `@path(...)`                | Path normalization / encapsulation                                               |
| `/.../flags?`               | Regex literal                                                                    |
| `                           | ...                                                                              |` or `> ... >` | Multi-line string constructs (keep vs collapse line breaks) |

## 5. Data Types (Original Scope Preserved)
Supported base types (no expansion beyond original intent unless explicitly accepted):
- string (quoted or bare if safe)
- int (supports underscores for readability: `1_000_000`)
- float (e.g., `3.14`, `1.5e10`)
- boolean: `true`, `false`
- null: `null`
- notset: `notset` (distinct from null)
- date: `YYYY-MM-DD`
- datetime: `YYYY-MM-DDTHH:MM:SSZ` or with offset
- path: `@path(...)`
- regex: `/pattern/` with optional flags (`i g m`)
- array: `[item1; item2; item3]` (multi-line: newline acts as implicit `;`)
- object: `{key: value; key2: value2}`
- table (tabular uniform array of objects) using header + rows syntax

## 6. Objects
Multi-line (semicolons optional when on separate lines):
```mof
config: {
  host: localhost
  port: 8080
  ssl: true
}
```
One-line (semicolons required):
```mof
config: {host: localhost; port: 8080; ssl: true}
```

## 7. Arrays
Multi-line:
```mof
transformers: [
  column_flatten
  column_select
  column_rename
]
```
One-line:
```mof
transformers: [column_flatten; column_select; column_rename]
```
Optional length marker for validation:
```mof
transformers[3]: [column_flatten; column_select; column_rename]
```

## 8. Tabular (Uniform) Arrays (TOON-inspired integration)
Used for uniform arrays of primitive-field objects—reduces repetition, aids validation.
Syntax:
```
schema[4]{name; datatype; nullable}:
  id; String; false
  bt_no; String; true
  rt_no; String; false
  branch_code; String; false
;
```
Rules:
- `[N]` = declared row count (optional but recommended)
- `{field; field; field}` = ordered headers
- `:` starts the data block
- Each row: column values separated by `;`
- Multi-line rows separated by newline; one-line rows separated by `|`
- Block ends at `;` (terminator) or indentation boundary (multi-line preference: explicit `;` recommended)

One-line form:
```
schema[4]{name; datatype; nullable}: id; String; false | bt_no; String; true | rt_no; String; false | branch_code; String; false;
```

## 9. Multi-line Strings
Keep line breaks:
```mof
query: |
  SELECT *
  FROM table
  WHERE active = true
|
```
Collapse line breaks into single space:
```mof
description: >
  This text
  will become
  one line
>
```

## 10. Variable Substitution
Syntax:
- Required: `${VAR}`
- With default: `${VAR=default_value}`
- Nested: `${ROOT=${FALLBACK=base}}`
Inside strings and paths allowed:
```mof
path: @path(gs://${BUCKET=my-bucket}/data/${DATE})
```

## 11. Secret Feature
Unified syntax draws from provider abstraction:
```mof
db-password: @secret(DB_PASSWORD)
gcp-key: @secret(gcp:projects/my-proj/secrets/api-key/versions/latest)
aws-secret: @secret(aws:my-app/api-token)
vault-token: @secret(vault:secret/data/app/token)
file-based: @secret(file:./secrets/dev.key)
json-config: @secret(config-json)[json]
trimmed-key: @secret(API_KEY)[trim]
chain: @secret(CERT_BASE64)[base64|trim]
```
Field extraction from structured secrets:
```mof
db-host: @secret(db-config)[json].host
```
Composition:
```mof
jdbc-url: "jdbc:postgresql://@secret(DB_HOST):5432/app"
credentials-path: @path(@secret(CREDS_FILE))
```

## 12. Include System
Basic:
```mof
@include: @path(common/base.mof)
@include: @path(common/base.mof) => spark-conf
```
Strategies (appendable in square brackets after directive):

| Strategy                     | Meaning                                  |
|------------------------------|------------------------------------------|
| `[merge]` (default)          | Deep merge (objects); concatenate arrays |
| `[replace]`                  | Replace entire target section            |
| `[overlay]`                  | Shallow (top-level) overwrite            |
| `[append]`                   | Append array items (error if not array)  |
| `[prepend]`                  | Prepend array items                      |
| `[exclude: key; nested.key]` | Remove keys after loading                |
| `[only: key1; key2]`         | Retain only specified keys               |
| `[except: key1; key2]`       | Drop specified keys, keep others         |
| `[prefix: namespace]`        | Prefix added to included top-level keys  |
| `[optional]`                 | No error if file missing                 |
| `[fallback: alt.mof]`        | Load fallback if primary missing         |

Example:

```mof
@include: @path(base.mof) [merge];
@include: @path(overrides.mof) => database [replace];
@include: @path(extra-transformers.mof) => transformers [append];
@include: @path(secrets/${ENV}.mof) [merge] [exclude: debug; temp];
@include: @path(shared.mof) [prefix: shared];
```

## 13. Comments
```mof
# Full line comment
key: value  # Inline comment
```
Best practice: Document intent above blocks.

## 14. Escaping
Within quoted strings:
- Escape: `\`, `"`, `'`, `;`, `{`, `}`, `[`, `]`, `$`, `@`, `#`
- Common escapes: `\n`, `\t`, `\r`, `\\`, `\"`
Example:
```mof
text: "Value with \; semicolon and literal \${NOT_VAR}"
```

## 15. One-line Representation Rules
Transformation from multi-line to one-line:
1. Strip newlines & indentation.
2. Insert semicolons between sibling key-value pairs/array items where newline separators were used.
3. Preserve tabular row separators with `|` if compressed.
4. Keep version header and braces intact.

Example multi-line → one-line:
```mof
!mof/1.0.0 {
  app: {
    name: pipeline
    version: 1.0.0
  }
  features: [cache; logging]
}
```
Becomes:
```mof
!mof/1.0.0 {app: {name: pipeline; version: 1.0.0}; features: [cache; logging]}
```

## 16. Validation Expectations
1. Syntax: Balanced delimiters, proper table row counts, valid regex.
2. Semantics: Variable resolution (required vs default), secret resolution (fail or default), table `N` matches actual row count if declared.
3. Strategy: Include operations applied in order; later includes override earlier merges as per strategy.
4. Security: Ensure `@secret(...)` placeholders are not materialized in logs unless explicitly allowed.

## 17. Recommended Separation
- `config.mof` (non-sensitive)
- `secrets.mof` (gitignored)
- `.mof-secrets` (provider definitions & resolution rules)

## 18. Minimal Grammar (Informal)
```
file        := version_header object
version_header := '!mof/' VERSION '{'
object      := '{' (pair (sep pair)*)? '}'
pair        := key ':' value
sep         := ';' | NEWLINE
value       := primitive | object | array | table | multiline_string | secret_ref | path_ref | regex
primitive   := string | int | float | boolean | null | notset | date | datetime
array       := '[' (value ( ';' value )* )? ']'
table       := IDENT '[' INT? ']' '{' header_fields '}' ':' table_rows table_end
header_fields := field ( ';' field )*
table_rows  := (row NEWLINE)* row
row         := value ( ';' value )*
table_end   := ';' (optional; strongly recommended)
secret_ref  := '@secret(' ref (transform_block)? ')'
path_ref    := '@path(' path_text ')'
regex       := '/' pattern '/' flags?
multiline_string := '|' NEWLINE content '|' | '>' NEWLINE content '>'
variable    := '${' IDENT ( '=' default_value )? '}'
include     := '@include:' path_ref ( '=>' section_name )? (strategy_block)*
```

## 19. Example (Condensed Full Feature Showcase)
```mof
!mof/1.0.0 {
  @include: @path(common/base.mof) [merge];
  @include: @path(env/${ENV}.mof) [merge] [optional] [fallback: env/default.mof];

  env: {
    project: ${PROJECT_ID=my-proj}
    bucket: ${BUCKET=data-bucket}
  };

  hadoop-conf: {
    "fs.gs.project.id": ${env.project}
    "fs.gs.auth.keyfile": @path(@secret(GCS_KEY_PATH))
  };

  transformers[5]: [
    flatten;
    select;
    rename;
    custom_sql;
    define_types
  ];

  column-renames[3]{from; to}:
    oldA; new_a
    oldB; new_b
    oldC; new_c
  ;

  schema[4]{name; datatype; nullable}:
    id; String; false
    created_at; DateTime; true
    active; Boolean; true
    amount; Float; true
  ;

  sql-query: |
    SELECT id, amount
    FROM source_table
    WHERE active = true
  |;

  api: {
    endpoint: "https://api.service.io"
    token: @secret(API_TOKEN)
  };

  # Regex for ID validation
  id-pattern: /^[A-Z]{3}\d{4}$/;

  destination: {
    warehouse-path: @path(gs://${env.bucket}/warehouse)
    mode: append
  }
}
```

## 20. Secret Summary (Core)
| Form             | Example                           | Notes                    |
|------------------|-----------------------------------|--------------------------|
| Basic env        | `@secret(API_KEY)`                | Default provider env     |
| Provider         | `@secret(gcp:secret-name)`        | Mapped via secret config |
| Default fallback | `@secret(API_KEY=dev-key)`        | Non-prod convenience     |
| File             | `@secret(file:./secrets/key.txt)` | Local dev only           |
| Transform        | `@secret(CONFIG_JSON)[json]`      | Structured read          |
| Chain            | `@secret(CERT_B64)[base64         | trim]`                   | Multi-step |

## 21. Include Strategy Quick Matrix
| Strategy | Objects     | Arrays      | Depth       | Typical Use           |
|----------|-------------|-------------|-------------|-----------------------|
| merge    | Deep        | Concat      | Recursive   | Layer overrides       |
| replace  | Whole       | Whole       | N/A         | Environment swap      |
| overlay  | Shallow     | Replace     | Top-level   | Fast patch            |
| append   | Error       | Append      | N/A         | Add tasks             |
| prepend  | Error       | Prepend     | N/A         | Priority ordering     |
| exclude  | Filter      | Filter      | Path-based  | Remove sensitive keys |
| only     | Filter      | Filter      | Top-level   | Whitelist subset      |
| except   | Filter      | Filter      | Top-level   | Blacklist subset      |
| prefix   | Rename      | Error       | Top-level   | Namespacing           |
| optional | Conditional | Conditional | N/A         | Flexible includes     |
| fallback | Conditional | Conditional | N/A         | Resilience            |

## 22. Conversion to One-line Example
Multi-line:
```mof
!mof/1.0.0 {
  env: {project: my-proj; region: us-central1}
  api: {endpoint: https://svc; token: @secret(API_TOKEN)}
}
```
One-line:
```
!mof/1.0.0 {env: {project: my-proj; region: us-central1}; api: {endpoint: https://svc; token: @secret(API_TOKEN)}}
```

## 23. Recommended Git Hygiene
```
.gitignore:
*.secret.mof
*-secrets.mof
.mof-secrets
.env
secrets/
```

## 24. Minimum Implementation Checklist (Parser)
- [ ] Version header parsing
- [ ] Object & array recursive descent
- [ ] Tabular block detection `[N]{...}:`
- [ ] Optional row count validation
- [ ] Variable resolution with defaults
- [ ] Secret reference abstraction hooks
- [ ] Include resolution with strategy stack
- [ ] Multi-line string normalization
- [ ] Regex literal validation
- [ ] One-line canonical serializer
- [ ] Error messages with precise location

## 25. Error Examples
| Error                     | Cause                      | Message Suggestion                                            |
|---------------------------|----------------------------|---------------------------------------------------------------|
| Missing required variable | `${VAR}` unset             | `Variable VAR not provided and no default specified`          |
| Tabular row mismatch      | Declared `[4]` but 3 rows  | `Tabular block 'schema' length mismatch: declared 4, found 3` |
| Column count mismatch     | Row has wrong columns      | `Row 2 in 'schema' has 2 columns; expected 3`                 |
| Unknown include file      | File absent & not optional | `Include failed: path 'env/prod.mof' not found`               |
| Invalid secret provider   | `@secret(abc:foo)` unknown | `Secret provider 'abc' not configured`                        |
| Regex invalid             | Bad pattern                | `Invalid regex at 'id-pattern': /[A-Z]++/`                    |

---

## 26. What NOT to Add (Guardrails)
- Arbitrary expressions or evaluation
- Implicit data typing outside declared forms
- Execution hooks
- Automatic remote fetching (must be explicit `@include` + policy)
- Silent secret fallbacks (must error unless default provided)

## 27. Philosophy Recap
MOF = Config clarity + operational safety + tabular efficiency (when beneficial) without drifting into overly dynamic language semantics. It defers computation, focuses on declarative intent, and enforces structural predictability.

---

## 28. Quick Reference Cheat Sheet (Condensed)
```
!mof/1.0.0 { ... }                # Version root
key: value                        # Primitive
obj: {a: 1; b: 2}                 # Object
arr: [x; y; z]                    # Array
arr[3]: [x; y; z]                 # Array with length
table[2]{id; name}: 1; Alice | 2; Bob;  # Tabular one-line
multi: | line1\n line2 |          # Preserve
collapse: > a b c >               # Collapse
var: ${NAME=default}              # Variable
sec: @secret(API_KEY)             # Secret
path: @path(/data/${DATE})        # Path
regex: /^[A-Z]{3}\d{4}$/          # Regex
@include: @path(base.mof) [merge] # Include
```

---

## 29. Final Notes
This summary reflects the stabilized core of MOF after iterative refinement:
- Single, consistent mental model for separators (semicolons; newline implicit)
- Clearly bounded advanced features (secrets, includes, tables) without overreach
- Practical for Data Engineering pipelines (Spark, Airflow, dbt) and deployment environments.

MOF v1.0.0 is READY for parser implementation, tooling, and ecosystem integration.
