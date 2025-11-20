# Spec 0.0.2

```text
!mof/1.0.0 {
    # 1. Variables
    project_id = "data-platform-prod";
    env = "production";

    # 2. Simple Object & Interpolation
    metadata {
        owner = "data_team";
        path  = "gs://bucket/${env}/data";
    }

    # 3. Typed Object with Fence String (SQL)
    extraction > postgres_source {
        host = "10.0.0.5";
        port = 5432;
        # No escaping needed for single quotes or semicolons inside |...|
        query = |
            SELECT id, email, "status" 
            FROM users 
            WHERE created_at > '2024-01-01';
        |;
    }

    # 4. Schema Array (Compact)
    # Multi-line style
    schema > (name, type, is_pii) [
        "id",    "int64",  false;
        "email", "string", true;
    ];

    # 5. One-line Capability
    # "sink" typed "bigquery"
    sink > bigquery { table="${project_id}.users"; mode=overwrite; };
}
```

```json
{
  "project_id": "data-platform-prod",
  "env": "production",
  "metadata": {
    "owner": "data_team",
    "path": "gs://bucket/production/data"
  },
  "extraction": {
    "type": "postgres_source",
    "host": "10.0.0.5",
    "port": 5432,
    "query": "\n            SELECT id, email, \"status\" \n            FROM users \n            WHERE created_at > '2024-01-01';\n        "
  },
  "schema": [
    { "name": "id", "type": "int64", "is_pii": false },
    { "name": "email", "type": "string", "is_pii": true }
  ],
  "sink": {
    "type": "bigquery",
    "table": "data-platform-prod.users",
    "mode": "overwrite"
  }
}
```