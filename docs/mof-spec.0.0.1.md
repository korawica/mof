# MOF (Modern Object Format) v1.0.0 - SPECIFICATION

## Design Principles

1. **ONE delimiter**: Semicolon (`;`) for all separations
2. **Newline = implicit semicolon** in multi-line mode
3. **Human-first**: Easy to read and write
4. **CLI-friendly**: Clean one-line format
5. **Token-safe**: Built-in secrets and variables
6. **Type-rich**: Special types for data engineering

---

## 1. Basic Syntax

### 1.1 Delimiters

| Symbol    | Purpose               | Required?                       |
|-----------|-----------------------|---------------------------------|
| `:`       | Key-value separator   | Always                          |
| `;`       | Statement terminator  | One-line (multi-line: optional) |
| `{}`      | Object boundaries     | Always                          |
| `[]`      | Array boundaries      | Always                          |
| `\|...\|` | Multi-line string     | When needed                     |
| `>...>`   | Multi-line string     | When needed                     |
| `@`       | Special type prefix   | For types                       |
| `${}`     | Variable substitution | For variables                   |
| `#`       | Comment               | Optional                        |

### 1.2 Version Declaration

```mof
!mof/1.0.0 {
  # Configuration goes here
}
```

---

## 2. Data Types

### 2.1 Primitives

```mof
# String (quotes optional for simple values)
name: John
fullname: "John Doe"
path: "C:\Users\John"

# Integer
count: 100
large: 1_000_000

# Float
price: 19.99
scientific: 1.5e10

# Boolean
enabled: true
disabled: false

# Null
empty: null
pending: notset
```

### 2.2 Date & Time (ISO 8601)

```mof
# Date
created: 2025-11-16

# DateTime with timezone
updated: 2025-11-16T07:31:54Z
local: 2025-11-16T07:31:54+07:00
```

### 2.3 Collections

#### Objects

```mof
# Multi-line (semicolon optional)
config: {
  host: localhost
  port: 8080
  ssl: true
}

# One-line (semicolon required)
config: {host: localhost; port: 8080; ssl: true}

# Nested objects
app: {
  server: {
    host: localhost;
    port: 8080
  };
  database: {
    host: db.local;
    port: 5432
  }
}
```

#### Arrays

```mof
# Multi-line (semicolon optional)
items: [
  item1
  item2
  item3
]

# One-line (semicolon required)
items: [item1; item2; item3]

# With length marker (for validation)
items[3]: [item1; item2; item3]
```

#### Tabular Arrays (TOON-inspired for uniform data)

```mof
# Multi-line tabular
users[3]{id; name; role}:
  1; Alice; admin
  2; Bob; user
  3; Carol; dev

# One-line tabular
users[3]{id; name; role}: 1; Alice; admin | 2; Bob; user | 3; Carol; dev

# Row separator: newline (multi-line) or pipe | (one-line)
# Column separator: semicolon
# Block ends: when indent changes or next top-level key
```

**Tabular Syntax Rules:**
- `[N]` = length marker (number of rows)
- `{field; field; field}` = column headers
- `:` = start of data rows
- `;` = column separator within row
- `|` = row separator in one-line mode
- Newline = row separator in multi-line mode

### 2.4 Special Types

#### Path

```mof
# Local path
local: @path(/home/user/file.txt)
relative: @path(./data/input.csv)

# Cloud storage
gcs: @path(gs://bucket/path/file)
s3: @path(s3://bucket/key)

# With variables
dynamic: @path(gs://${BUCKET}/data/${DATE}.csv)
```

#### Secret (Token-Safe)

```mof
# Environment variable secret
password: @secret(DB_PASSWORD)

# Provider-specific secret
gcp-key: @secret(gcp:secret-manager-id)
aws-key: @secret(aws:secret-arn)

# Composed with path
credentials: @path(@secret(CRED_FILE_PATH))
```

#### Regex

```mof
# Pattern only
email-pattern: /^[\w.+-]+@[\w.-]+\.\w+$/

# With flags
case-insensitive: /pattern/i
global: /pattern/g
multiline: /pattern/m
all-flags: /pattern/gim
```

### 2.5 Multi-line Strings

```mof
# Preserve line breaks (pipe delimiters)
query: |
  SELECT *
  FROM users
  WHERE status = 'active'
    AND created_at > NOW() - INTERVAL '30 days'
|

# Remove line breaks (join into one line)
description: >
  This is a very long description
  that spans multiple lines
  but will be joined into one
>
```

---

## 3. Variables

### 3.1 Variable Substitution

```mof
# Required variable (error if not set)
project: ${PROJECT_ID}

# Optional with default value
region: ${REGION=us-central1}
bucket: ${BUCKET=default-bucket}

# Nested variables
path: ${ROOT_PATH}/${ENV}/${DATE}

# Nested defaults
backup: ${BACKUP_BUCKET=${PRIMARY_BUCKET=default-bucket}}

# In strings
message: "Connected to ${DB_HOST}:${DB_PORT}"
```

### 3.2 Variable Reference

```mof
# Define once, use many times
env: {
  project: ${GCS_PROJECT_ID=my-project};
  bucket: ${GCS_BUCKET=my-bucket};
  region: ${REGION=us-central1}
}

# Reference by dot notation
hadoop-conf: {
  "fs.gs.project.id": ${env.project};
  "fs.gs.bucket": ${env.bucket}
}
```

---

## 4. File Includes

```mof
# Include entire file
@include: @path(common/base.mof)

# Include specific section
@include: @path(common/base.mof) => hadoop-conf

# Include with variables
@include: @path(configs/${ENV}/settings.mof)

# Multiple includes
!mof/1.0.0 {
  @include: @path(common/defaults.mof);
  @include: @path(environments/${ENV}.mof);
  @include: @path(secrets/${ENV}-secrets.mof) => credentials;
  
  # Your config continues here
  app: {
    name: myapp
  }
}
```

---

## 5. Comments

```mof
# Line comment

key: value  # Inline comment

# Multi-line documentation block
# Line 1 of comment
# Line 2 of comment
# Line 3 of comment
config: {
  # Comment inside object
  host: localhost
}
```

---

## 6. Escape Sequences

```mof
# Escape special characters with backslash
text: "Escaped \; semicolon"
path: "C:\\Users\\Admin"
quote: "He said \"Hello\""
dollar: "Literal \${VAR} not substituted"

# Common escapes
newline: "Line 1\nLine 2"
tab: "Col1\tCol2"
carriage: "Text\rOverwrite"
backslash: "Path\\to\\file"
```

**Must escape in strings:**
- `\` (backslash)
- `"` (double quote)
- `'` (single quote)
- `;` (semicolon)
- `{` `}` (braces)
- `[` `]` (brackets)
- `$` (dollar sign - for variables)
- `@` (at sign - for special types)
- `#` (hash - for comments)

---

## 7. One-Line Format

### 7.1 Conversion Rules

**Multi-line to one-line:**
1. Remove all newlines
2. Remove all indentation
3. Add semicolons between statements (inside objects/arrays)
4. Keep one space after `:` for readability (optional)

**Example:**

```mof
# Multi-line
!mof/1.0.0 {
  app: {
    name: myapp
    version: 1.0
  };
  database: {
    host: localhost
    port: 5432
  }
}

# One-line
!mof/1.0.0 {app: {name: myapp; version: 1.0}; database: {host: localhost; port: 5432}}
```

### 7.2 CLI Usage

```bash
# Pass config as CLI argument
spark-submit job.py --config='!mof/1.0.0 {key: value; nested: {x: 1}}'

# Use heredoc for readability
spark-submit job.py --config="$(cat <<'EOF'
!mof/1.0.0 {
  config: {value: 123}
}
EOF
)"
```

---

## 8. Complete Examples

### 8.1 Simple Configuration

```mof
!mof/1.0.0 {
  # Application settings
  app: {
    name: my-data-pipeline
    version: 1.0.0
    environment: ${ENV=development}
  };
  
  # Database connection
  database: {
    host: ${DB_HOST=localhost}
    port: ${DB_PORT=5432}
    name: ${DB_NAME=mydb}
    username: ${DB_USER}
    password: @secret(DB_PASSWORD)
  };
  
  # Feature flags
  features: {
    enable-cache: true
    enable-logging: true
    max-retries: 3
  }
}
```

### 8.2 Data Pipeline Configuration

```mof
!mof/1.0.0 {
  # Include external configs
  @include: @path(common/hadoop-defaults.mof) => hadoop-conf;
  @include: @path(common/spark-defaults.mof) => spark-conf;
  
  # Environment variables
  env: {
    project-id: ${GCS_PROJECT_ID=stock-data-dev};
    bucket: ${GCS_BUCKET=stock-dev};
    environment: ${ENVIRONMENT=dev}
  };
  
  # Source configuration
  source: {
    type: json;
    path: @path(gs://${env.bucket}/landing/stock/year={YEAR}/month={MONTH});
    reader-options: {
      multiline: false;
      compression: gzip
    }
  };
  
  # Transformation steps
  transformers[5]: [
    column_flatten_transformer;
    column_select_transformer;
    custom_sql_transformer;
    column_rename_transformer;
    define_datatype_transformer
  ];
  
  # Column mappings (tabular format)
  column-renames[8]{from; to}:
    _id; id
    btNo; bt_no
    rtNo; rt_no
    branchCode; branch_code
    startDate; start_date
    endDate; end_date
    branchFrom; branch_from
    branchTo; branch_to
  ;
  
  # SQL transformation
  custom-sql: |
    INSERT INTO processed_data AS
    SELECT
      *,
      CAST(SUBSTRING(startDate, 1, 10) AS DATE) AS start_date,
      CAST(SUBSTRING(endDate, 1, 10) AS DATE) AS end_date
    FROM raw_data
    WHERE rtNo IS NOT NULL
  |;
  
  # Schema definition (tabular format)
  schema[8]{name; datatype; nullable}:
    id; String; false
    bt_no; String; true
    rt_no; String; false
    branch_code; String; false
    start_date; Date; true
    end_date; Date; true
    branch_from; String; true
    branch_to; String; true
  ;
  
  # Destination configuration
  destination: {
    type: iceberg;
    path: @path(gs://${env.bucket}/warehouse/stock);
    table-name: stock_transformed;
    write-mode: append;
    partition-by: updated_date;
    
    # Iceberg-specific options
    options: {
      "write.format.default": parquet;
      "write.target-file-size-bytes": 536_870_912;  # 512 MB
      "commit.manifest.min-count-to-merge": 10
    }
  }
}
```

### 8.3 Multi-Environment Configuration

```mof
# base.mof (shared configuration)
!mof/1.0.0 {
  app: {
    name: data-pipeline;
    version: 2.1.0;
    timeout: 3600;
    max-retries: 3
  };
  
  logging: {
    level: ${LOG_LEVEL=INFO};
    format: json
  }
}

# dev.mof (development overrides)
!mof/1.0.0 {
  @include: @path(base.mof);
  
  env: {
    name: development;
    project-id: my-project-dev;
    bucket: my-bucket-dev
  };
  
  database: {
    host: localhost;
    port: 5432;
    password: @secret(DEV_DB_PASSWORD)
  }
}

# prod.mof (production overrides)
!mof/1.0.0 {
  @include: @path(base.mof);
  
  env: {
    name: production;
    project-id: my-project-prod;
    bucket: my-bucket-prod
  };
  
  database: {
    host: prod-db.internal;
    port: 5432;
    password: @secret(PROD_DB_PASSWORD)
  };
  
  logging: {
    level: WARNING;
    format: json;
    enable-metrics: true
  }
}
```

---

## 9. Validation Rules

### 9.1 Syntax Validation

- [ ] Balanced braces `{}` and brackets `[]`
- [ ] Valid escape sequences in strings
- [ ] Valid ISO 8601 dates/datetimes
- [ ] Valid regex patterns
- [ ] Version declaration present
- [ ] Proper semicolon placement (one-line mode)

### 9.2 Semantic Validation

- [ ] Required variables are set
- [ ] Secret references are resolvable
- [ ] Include files exist
- [ ] No circular includes
- [ ] Array lengths match (if specified)
- [ ] Tabular field counts match headers

### 9.3 Type Validation

- [ ] Path types resolve correctly
- [ ] Date/datetime in ISO 8601 format
- [ ] Numbers are valid (int/float)
- [ ] Booleans are `true` or `false`

---

## 10. Parser Implementation Guide

### 10.1 Parsing State Machine

```python
class MOFParser:
    def __init__(self):
        self.state = {
            'in_object': 0,        # Depth of nested objects
            'in_array': 0,         # Depth of nested arrays
            'in_tabular': False,   # Inside tabular block
            'in_string': False,    # Inside quoted string
            'in_multiline': False, # Inside |...| or >...>
            'escape_next': False   # Next char is escaped
        }
    
    def parse(self, text):
        """
        Parse MOF text into data structure
        """
        # 1. Tokenize (handle escapes, quotes, delimiters)
        tokens = self.tokenize(text)
        
        # 2. Parse structure (objects, arrays, tabular)
        ast = self.build_ast(tokens)
        
        # 3. Resolve includes (recursive)
        ast = self.resolve_includes(ast)
        
        # 4. Substitute variables
        ast = self.substitute_variables(ast)
        
        # 5. Resolve secrets
        ast = self.resolve_secrets(ast)
        
        # 6. Validate
        self.validate(ast)
        
        return ast
```

### 10.2 Delimiter Handling

```python
def handle_delimiter(char, state):
    """
    Context-aware delimiter handling
    """
    if state['in_string'] or state['in_multiline']:
        return 'LITERAL_CHAR'  # Ignore delimiters in strings
    
    if char == ';':
        if state['in_object'] > 0 or state['in_array'] > 0:
            return 'STATEMENT_SEPARATOR'
        elif state['in_tabular']:
            return 'COLUMN_SEPARATOR'
        else:
            return 'STATEMENT_TERMINATOR'
    
    # ... handle other delimiters
```

### 10.3 Tabular Parsing

```python
def parse_tabular(tokens):
    """
    Parse tabular array format:
    array[N]{field; field; field}:
      value; value; value
      value; value; value
    """
    # Extract: name, length [N], fields {f1; f2; f3}
    name = tokens[0]
    length = parse_length_marker(tokens)  # [N]
    fields = parse_field_list(tokens)     # {f1; f2; f3}
    
    # Parse rows (newline-separated in multi-line, |-separated in one-line)
    rows = []
    for row_text in split_rows(tokens):
        # Split by semicolon for columns
        values = row_text.split(';')
        
        # Validate column count
        if len(values) != len(fields):
            raise ParseError(f"Row has {len(values)} values, expected {len(fields)}")
        
        # Build object from field names and values
        row_obj = dict(zip(fields, values))
        rows.append(row_obj)
    
    # Validate row count
    if length and len(rows) != length:
        raise ParseError(f"Declared {length} rows, found {len(rows)}")
    
    return {name: rows}
```

---

## 11. Best Practices

### 11.1 When to Use Tabular Format

✅ **Use tabular for:**
- Uniform arrays of objects (same fields, all primitive values)
- Column mappings, schema definitions
- Lookup tables, configuration matrices
- CSV-like data

❌ **Don't use tabular for:**
- Non-uniform arrays (different fields per object)
- Nested objects or arrays as values
- Small arrays (< 3 items)
- Arrays with complex types

### 11.2 Security Best Practices

```mof
# ❌ BAD - Secrets in plain text
database: {
  password: MySecretPassword123!
}

# ✅ GOOD - Use @secret()
database: {
  password: @secret(DB_PASSWORD)
}

# ✅ GOOD - Separate secrets file
@include: @path(secrets/${ENV}.mof) => credentials

# ✅ GOOD - Environment variables
api-key: ${API_KEY}
```

### 11.3 Organizing Large Configs

```mof
# main.mof (orchestrator)
!mof/1.0.0 {
  # Include base configs
  @include: @path(common/defaults.mof);
  @include: @path(common/hadoop.mof) => hadoop-conf;
  @include: @path(common/spark.mof) => spark-conf;
  
  # Include environment-specific
  @include: @path(env/${ENV}/overrides.mof);
  @include: @path(env/${ENV}/secrets.mof) => secrets;
  
  # Application-specific config
  pipeline: {
    name: ${PIPELINE_NAME};
    version: 2.0.0
  }
}
```

### 11.4 Git Best Practices

```gitignore
# .gitignore
*.secret.mof
*-secrets.mof
*.local.mof
.env
secrets/
credentials/
```

---

## 12. Comparison with Other Formats

| Feature            | MOF                | JSON     | YAML  | TOML | TOON | HCL  |
|--------------------|--------------------|----------|-------|------|------|------|
| **Comments**       | ✅                  | ❌        | ✅     | ✅    | ✅    | ✅    |
| **Variables**      | ✅ `${VAR=default}` | ❌        | ❌     | ❌    | ❌    | ✅    |
| **Secrets**        | ✅ `@secret()`      | ❌        | ❌     | ❌    | ❌    | ⚠️   |
| **Includes**       | ✅ `@include`       | ❌        | ❌     | ❌    | ❌    | ❌    |
| **Tabular Arrays** | ✅                  | ❌        | ❌     | ❌    | ✅    | ❌    |
| **One-line**       | ✅ Clean            | ✅        | ❌     | ⚠️   | ⚠️   | ⚠️   |
| **ONE delimiter**  | ✅ `;`              | ⚠️ `,`   | ❌     | ⚠️   | ❌    | ⚠️   |
| **Human Readable** | ⭐⭐⭐⭐⭐              | ⭐⭐⭐      | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Type Safe**      | ✅ Rich             | ⚠️ Basic | ⚠️    | ✅    | ⚠️   | ✅    |

---

## 13. Tools & Ecosystem (Planned)

- **mof-cli** - Command-line tool (`validate`, `format`, `to-json`, `to-yaml`)
- **mof-python** - Python parser and serializer
- **mof-vscode** - VSCode extension (syntax highlighting, validation)
- **mof-lint** - Linter for best practices
- **mof-convert** - Convert between MOF, JSON, YAML, TOML, TOON

---

## 14. License

MOF specification is open source (MIT License).
