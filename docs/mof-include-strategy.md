## File Includes

### 1 Basic Include

```mof
# Include entire file
@include: @path(file.mof)

# Include specific section
@include: @path(file.mof) => section-name
```

### 2 Include Strategies

| Strategy            | Syntax                  | Behavior                               |
|---------------------|-------------------------|----------------------------------------|
| **merge** (default) | `[merge]`               | Deep merge objects, concatenate arrays |
| **replace**         | `[replace]`             | Replace entire section                 |
| **overlay**         | `[overlay]`             | Shallow merge (top-level only)         |
| **append**          | `[append]`              | Append to arrays (error on objects)    |
| **prepend**         | `[prepend]`             | Prepend to arrays (error on objects)   |
| **exclude**         | `[exclude: key1; key2]` | Load but exclude specific keys         |

### 3 Include Options

| Option         | Syntax                 | Behavior                          |
|----------------|------------------------|-----------------------------------|
| **optional**   | `[optional]`           | No error if file missing          |
| **fallback**   | `[fallback: file.mof]` | Use fallback if primary missing   |
| **only**       | `[only: key1; key2]`   | Include only specified keys       |
| **except**     | `[except: key1; key2]` | Include all except specified keys |
| **prefix**     | `[prefix: namespace]`  | Add prefix to all keys            |

Strategy	Objects	Arrays	Use Case
merge	Deep merge	Concatenate	Default, most flexible
replace	Replace	Replace	Environment overrides
overlay	Shallow merge	Replace	Quick top-level changes
append	Error	Append	Add extra items
prepend	Error	Prepend	Priority items first
exclude	Filter keys	Filter items	Remove sensitive data

### 4 Examples

```mof
# Merge with exclude
@include: @path(config.mof) [merge] [exclude: debug; temp]

# Replace database section
@include: @path(prod.mof) => database [replace]

# Optional include with fallback
@include: @path(overrides.mof) [optional] [fallback: defaults.mof]

# Append transformers
@include: @path(extra-transformers.mof) => transformers [append]

# Include with prefix
@include: @path(shared.mof) [prefix: shared]
```

1. Merge Strategy Example

```text
# base.mof
!mof/1.0.0 {
  database: {
    host: localhost;
    port: 5432;
    pool: {
      min: 2;
      max: 10
    }
  };
  features: [feature1; feature2]
}

# override.mof
!mof/1.0.0 {
  database: {
    host: prod-db.internal;
    pool: {
      max: 50;
      timeout: 30
    }
  };
  features: [feature3]
}

# main.mof
!mof/1.0.0 {
  @include: @path(base.mof) [merge];
  @include: @path(override.mof) [merge];
}

# RESULT:
{
  database: {
    host: prod-db.internal;        # Overridden
    port: 5432;                    # From base
    pool: {
      min: 2;                      # From base
      max: 50;                     # Overridden
      timeout: 30                  # Added
    }
  };
  features: [feature1; feature2; feature3]  # Concatenated
}
```

2. Replace Strategy Example

```text
# base.mof
!mof/1.0.0 {
  database: {
    host: localhost;
    port: 5432;
    pool: {
      min: 2;
      max: 10
    }
  }
}

# override.mof
!mof/1.0.0 {
  database: {
    host: prod-db.internal;
    port: 3306
  }
}

# main.mof
!mof/1.0.0 {
  @include: @path(base.mof);
  @include: @path(override.mof) [replace];
}

# RESULT:
{
  database: {
    host: prod-db.internal;
    port: 3306
    # pool is GONE (replaced, not merged)
  }
}
```

3. Overlay Strategy Example

```text
# base.mof
!mof/1.0.0 {
  database: {
    host: localhost;
    port: 5432;
    pool: {
      min: 2;
      max: 10
    }
  }
}

# override.mof
!mof/1.0.0 {
  database: {
    pool: {
      max: 50
    }
  }
}

# main.mof
!mof/1.0.0 {
  @include: @path(base.mof);
  @include: @path(override.mof) [overlay];
}

# RESULT:
{
  database: {
    pool: {
      max: 50
      # min is GONE (overlay replaces entire 'pool' object)
    }
    # host and port are GONE (overlay only merges top-level 'database')
  }
}
```

4. Append Strategy Example

```text
# base.mof
!mof/1.0.0 {
  transformers: [
    transformer1;
    transformer2
  ]
}

# extra.mof
!mof/1.0.0 {
  transformers: [
    transformer3;
    transformer4
  ]
}

# main.mof
!mof/1.0.0 {
  @include: @path(base.mof);
  @include: @path(extra.mof) [append];
}

# RESULT:
{
  transformers: [
    transformer1;
    transformer2;
    transformer3;  # Appended
    transformer4   # Appended
  ]
}
```

5. Prepend Strategy Example

```text
# base.mof
!mof/1.0.0 {
  transformers: [
    transformer3;
    transformer4
  ]
}

# priority.mof
!mof/1.0.0 {
  transformers: [
    transformer1;
    transformer2
  ]
}

# main.mof
!mof/1.0.0 {
  @include: @path(base.mof);
  @include: @path(priority.mof) [prepend];
}

# RESULT:
{
  transformers: [
    transformer1;  # Prepended
    transformer2;  # Prepended
    transformer3;
    transformer4
  ]
}
```

6. Exclude Strategy Example

```text
# base.mof
!mof/1.0.0 {
  database: {
    host: localhost;
    port: 5432;
    password: secret123;
    debug: true
  };
  logging: {
    level: DEBUG
  }
}

# main.mof
!mof/1.0.0 {
  @include: @path(base.mof) [exclude: database.password; database.debug];
}

# RESULT:
{
  database: {
    host: localhost;
    port: 5432
    # password and debug excluded
  };
  logging: {
    level: DEBUG
  }
}
```

#### Advanced Example

1. Section-Specific Strategies

mof
!mof/1.0.0 {
  # Include entire file with merge
  @include: @path(base.mof) [merge];
  
  # Include specific section with replace
  @include: @path(overrides.mof) => database [replace];
  
  # Include with append strategy
  @include: @path(extra-features.mof) => features [append];
}

2. Conditional Includes
mof
!mof/1.0.0 {
  # Include based on environment variable
  @include: @path(configs/${ENV}.mof) [merge];
  
  # Include secrets only if file exists
  @include: @path(secrets/${ENV}-secrets.mof) [merge] [optional];
  
  # Include with fallback
  @include: @path(overrides.mof) [merge] [optional] [fallback: defaults.mof];
}

3. Multi-Strategy Chain
mof
!mof/1.0.0 {
  # Load base (merge by default)
  @include: @path(base.mof);
  
  # Override database (replace entire section)
  @include: @path(db-${ENV}.mof) => database [replace];
  
  # Add extra transformers (append to array)
  @include: @path(extra-transformers.mof) => transformers [append];
  
  # Load secrets (merge, exclude debug keys)
  @include: @path(secrets.mof) [merge] [exclude: *.debug; *.temp];
}

4. Include with Filters
mof
!mof/1.0.0 {
  # Include only specific keys
  @include: @path(full-config.mof) [only: database; logging];
  
  # Include everything except specific keys
  @include: @path(full-config.mof) [except: secrets; credentials];
  
  # Include with key prefix
  @include: @path(shared.mof) [prefix: shared];
  # Result: shared.database, shared.logging, etc.
}

```text
# ============================================
# BASIC INCLUDE
# ============================================

# Include entire file (merge by default)
@include: @path(file.mof)

# Include specific section
@include: @path(file.mof) => section-name

# Include with variable in path
@include: @path(configs/${ENV}/settings.mof)

# ============================================
# INCLUDE WITH STRATEGY
# ============================================

# Merge (default) - deep merge
@include: @path(file.mof) [merge]

# Replace - replace entire section
@include: @path(file.mof) [replace]

# Overlay - shallow merge (top-level only)
@include: @path(file.mof) [overlay]

# Append - append to arrays
@include: @path(file.mof) [append]

# Prepend - prepend to arrays
@include: @path(file.mof) [prepend]

# Exclude specific keys
@include: @path(file.mof) [exclude: key1; key2; nested.key]

# ============================================
# INCLUDE WITH OPTIONS
# ============================================

# Optional include (no error if file missing)
@include: @path(optional.mof) [optional]

# Include with fallback
@include: @path(primary.mof) [optional] [fallback: backup.mof]

# Include only specific keys
@include: @path(file.mof) [only: database; logging]

# Include except specific keys
@include: @path(file.mof) [except: secrets; temp]

# Include with key prefix
@include: @path(shared.mof) [prefix: shared]

# ============================================
# COMBINED STRATEGIES
# ============================================

# Replace database, exclude passwords
@include: @path(prod.mof) => database [replace] [exclude: password; api-key]

# Merge with prefix and exclude
@include: @path(common.mof) [merge] [prefix: common] [exclude: debug]

# Optional append with fallback
@include: @path(extras.mof) [append] [optional] [fallback: defaults.mof]
```

#### Real-World Use Case

```mof
# ============================================
# common/base.mof - Shared configuration
# ============================================
!mof/1.0.0 {
  app: {
    name: data-pipeline;
    version: 2.0.0;
    timeout: 3600
  };
  
  features: {
    enable-cache: true;
    enable-logging: true
  }
}

# ============================================
# environments/dev.mof - Development overrides
# ============================================
!mof/1.0.0 {
  database: {
    host: localhost;
    port: 5432;
    password: @secret(DEV_DB_PASSWORD)
  };
  
  features: {
    enable-cache: false;  # Disable cache in dev
    enable-debug: true
  }
}

# ============================================
# environments/prod.mof - Production overrides
# ============================================
!mof/1.0.0 {
  database: {
    host: prod-db.internal;
    port: 5432;
    password: @secret(PROD_DB_PASSWORD);
    pool: {
      min: 10;
      max: 100
    }
  };
  
  features: {
    enable-cache: true;
    enable-metrics: true
  }
}

# ============================================
# main.mof - Main configuration
# ============================================
!mof/1.0.0 {
  # Load base (merge)
  @include: @path(common/base.mof) [merge];
  
  # Load environment-specific (merge features, replace database)
  @include: @path(environments/${ENV}.mof) [merge];
  @include: @path(environments/${ENV}.mof) => database [replace];
  
  # Load secrets (exclude debug keys in production)
  @include: @path(secrets/${ENV}.mof) [merge] [exclude: *.debug; *.temp];
}
```

```text
# ============================================
# plugins/base-transformers.mof
# ============================================
!mof/1.0.0 {
  transformers[3]: [
    column_flatten;
    column_select;
    column_rename
  ]
}

# ============================================
# plugins/advanced-transformers.mof
# ============================================
!mof/1.0.0 {
  transformers[2]: [
    custom_sql;
    define_datatype
  ]
}

# ============================================
# main.mof - Load plugins
# ============================================
!mof/1.0.0 {
  # Load base transformers
  @include: @path(plugins/base-transformers.mof);
  
  # Append advanced transformers
  @include: @path(plugins/advanced-transformers.mof) [append];
  
  # Result: transformers[5]: [column_flatten, column_select, column_rename, custom_sql, define_datatype]
}
```

```text
# ============================================
# shared/company-defaults.mof
# ============================================
!mof/1.0.0 {
  company: {
    name: "Acme Corp";
    region: "US"
  };
  
  security: {
    enable-ssl: true;
    min-tls-version: "1.2"
  };
  
  monitoring: {
    enable-metrics: true;
    enable-tracing: true
  }
}

# ============================================
# teams/data-engineering.mof
# ============================================
!mof/1.0.0 {
  team: {
    name: "Data Engineering";
    contact: "de-team@acme.com"
  };
  
  # Team-specific tools
  tools: [spark; airflow; dbt]
}

# ============================================
# my-project.mof
# ============================================
!mof/1.0.0 {
  # Include company defaults with prefix
  @include: @path(shared/company-defaults.mof) [prefix: company];
  
  # Include team config
  @include: @path(teams/data-engineering.mof) [merge];
  
  # Project-specific config
  project: {
    name: "Stock Data Pipeline";
    version: "1.0.0"
  };
  
  # Result:
  # - company.company, company.security, company.monitoring
  # - team, tools
  # - project
}
```