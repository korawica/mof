# Secret

MOF Secret Management Features:

Feature	Syntax	Example
Environment variable	@secret(VAR)	@secret(API_KEY)
Cloud provider	@secret(provider:key)	@secret(gcp:db-password)
Default value	@secret(VAR=default)	@secret(API_KEY=dev-key)
File-based	@secret(file:path)	@secret(file:./secrets/key.txt)
In strings	"text @secret(VAR)"	"user:@secret(PASS)@host"
In paths	@path(@secret(VAR))	@path(@secret(CREDS_FILE))
Structured (JSON)	@secret(VAR)[json]	@secret(config)[json].key
Field extraction	@secret(VAR).field	@secret(db-config).host
Transformations	@secret(VAR)[type]	@secret(CERT)[base64]

This makes MOF the most secure config format for Data Engineering! 🔐🎉

```text
# ============================================
# BASIC SECRETS
# ============================================

# Environment variable (default)
key: @secret(VAR_NAME)

# With default value
key: @secret(VAR_NAME=default-value)

# Explicit environment
key: @secret(env:VAR_NAME)

# ============================================
# CLOUD PROVIDERS
# ============================================

# Google Cloud Secret Manager
key: @secret(gcp:secret-name)
key: @secret(gcp:projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION)

# AWS Secrets Manager
key: @secret(aws:secret-name)
key: @secret(aws:arn:aws:secretsmanager:REGION:ACCOUNT:secret:NAME)

# Azure Key Vault
key: @secret(azure:vault-name/secret-name)
key: @secret(azure:vault-name/secret-name/version)

# HashiCorp Vault
key: @secret(vault:secret/path/to/key)
key: @secret(vault:kv-v2/data/app/config)

# Kubernetes Secret
key: @secret(k8s:namespace/secret-name/key)
key: @secret(k8s:my-secret/api-key)  # Current namespace

# ============================================
# FILE-BASED SECRETS
# ============================================

# Absolute path
key: @secret(file:/run/secrets/api-key)

# Relative path
key: @secret(file:./secrets/dev.key)
key: @secret(file:../shared/secrets/prod.key)

# With environment variable in path
key: @secret(file:${SECRETS_DIR}/api-key.txt)

# ============================================
# STRUCTURED SECRETS
# ============================================

# Extract field from JSON secret
host: @secret(db-config).host
port: @secret(db-config).port

# Load entire JSON as object
config: @secret(config-json)[json]

# Nested field extraction
api-key: @secret(config).api.key

# ============================================
# SECRET TRANSFORMATIONS
# ============================================

# Base64 decode
cert: @secret(CERT_ENCODED)[base64]

# JSON parse
config: @secret(CONFIG_JSON)[json]

# YAML parse
config: @secret(CONFIG_YAML)[yaml]

# Trim whitespace
key: @secret(API_KEY)[trim]

# Chain transformations
cert: @secret(CERT_DATA)[base64|trim]

# ============================================
# SECRETS IN CONTEXT
# ============================================

# In strings
url: "https://user:@secret(PASSWORD)@host.com"
connection: "Server=@secret(DB_HOST);Database=@secret(DB_NAME)"

# In paths
file: @path(@secret(CREDS_PATH))
dir: @path(@secret(DATA_ROOT)/${ENV}/data)

# In objects
database: {
  host: @secret(DB_HOST);
  port: @secret(DB_PORT);
  username: @secret(DB_USER);
  password: @secret(DB_PASSWORD)
}

# In arrays
api-keys[3]: [
  @secret(API_KEY_1);
  @secret(API_KEY_2);
  @secret(API_KEY_3)
]
```

```text
# .mof-secrets (or mof-secrets.config)
!mof/1.0.0 {
  # Default provider (if no prefix specified)
  default-provider: env;
  
  # Environment variables
  providers: {
    env: {
      type: environment;
      prefix: ""  # Optional prefix for all env vars
    };
    
    # Google Cloud Secret Manager
    gcp: {
      type: gcp-secret-manager;
      project: ${GCP_PROJECT_ID};
      # Optional: specify credentials
      credentials: @path(${GOOGLE_APPLICATION_CREDENTIALS})
    };
    
    # AWS Secrets Manager
    aws: {
      type: aws-secrets-manager;
      region: ${AWS_REGION=us-east-1};
      # Uses AWS SDK default credential chain
    };
    
    # Azure Key Vault
    azure: {
      type: azure-key-vault;
      vault-url: "https://${AZURE_VAULT_NAME}.vault.azure.net";
      # Uses Azure SDK default credential chain
    };
    
    # HashiCorp Vault
    vault: {
      type: hashicorp-vault;
      address: ${VAULT_ADDR=http://localhost:8200};
      token: ${VAULT_TOKEN};
      # Or use AppRole authentication
      auth: {
        method: approle;
        role-id: ${VAULT_ROLE_ID};
        secret-id: ${VAULT_SECRET_ID}
      }
    };
    
    # Kubernetes Secrets
    k8s: {
      type: kubernetes;
      namespace: ${K8S_NAMESPACE=default};
      # Uses in-cluster config or kubeconfig
    };
    
    # File-based (for local dev)
    file: {
      type: file;
      base-path: ${SECRETS_BASE_PATH=./secrets};
      encoding: utf-8
    }
  };
  
  # Secret caching (optional)
  cache: {
    enabled: true;
    ttl: 300;  # Cache for 5 minutes
    max-size: 100
  };
  
  # Validation (optional)
  validation: {
    # Fail on missing secrets (default: true)
    fail-on-missing: true;
    
    # Warn on deprecated secrets
    warn-on-deprecated: true;
    
    # Required secrets (must be present)
    required: [
      DB_PASSWORD;
      API_KEY;
      GCS_CREDENTIALS
    ]
  };
  
  # Audit logging (optional)
  audit: {
    enabled: true;
    log-access: true;
    log-file: @path(./logs/secrets-audit.log)
  }
}
```

## Real-World Usage

```text
# ============================================
# production.mof - Production Configuration
# ============================================
!mof/1.0.0 {
  # Environment
  env: {
    name: production;
    project-id: ${GCS_PROJECT_ID};
    region: ${REGION=us-central1}
  };
  
  # ============================================
  # Database Configuration (Secrets from GCP)
  # ============================================
  database: {
    # Host from GCP Secret Manager
    host: @secret(gcp:prod-db-host);
    port: 5432;
    
    # Username from environment variable
    username: @secret(env:DB_USER);
    
    # Password from GCP Secret Manager
    password: @secret(gcp:prod-db-password);
    
    # SSL certificate from file secret
    ssl-cert: @path(@secret(file:db-ssl-cert.pem));
    
    # Connection string with secrets
    connection-string: "postgresql://@secret(env:DB_USER):@secret(gcp:prod-db-password)@@secret(gcp:prod-db-host):5432/production";
    
    # Connection pool settings from structured secret
    pool: @secret(gcp:db-pool-config)[json]
    # JSON secret contains: {"min": 10, "max": 100, "timeout": 30}
  };
  
  # ============================================
  # GCS Configuration
  # ============================================
  gcs: {
    # Service account key from GCP Secret Manager
    credentials: @path(@secret(gcp:gcs-service-account-key));
    
    # Or credentials as JSON directly
    credentials-json: @secret(gcp:gcs-service-account-json)[json];
    
    # Bucket name
    bucket: @secret(env:GCS_BUCKET=stock-prod);
    
    # Paths with secrets
    landing-path: @path(gs://@secret(env:GCS_BUCKET)/landing);
    warehouse-path: @path(gs://@secret(env:GCS_BUCKET)/warehouse)
  };
  
  # ============================================
  # API Configuration
  # ============================================
  api: {
    # Multiple API keys from different providers
    primary-key: @secret(gcp:api-key-primary);
    backup-key: @secret(gcp:api-key-backup);
    
    # API endpoint with port from secrets
    endpoint: "https://@secret(API_HOST):@secret(API_PORT)/v1";
    
    # Bearer token from Vault
    auth-token: @secret(vault:secret/data/api/bearer-token)[json].token;
    
    # OAuth credentials as structured secret
    oauth: @secret(gcp:oauth-config)[json]
    # JSON: {"client_id": "...", "client_secret": "...", "redirect_uri": "..."}
  };
  
  # ============================================
  # Spark Configuration
  # ============================================
  spark-conf: {
    # Hadoop configuration with secrets
    "fs.gs.project.id": @secret(env:GCS_PROJECT_ID);
    "fs.gs.auth.service.account.json.keyfile": @path(@secret(gcp:spark-gcs-key));
    
    # Database JDBC with secrets
    "spark.jdbc.url": "jdbc:postgresql://@secret(gcp:prod-db-host):5432/warehouse";
    "spark.jdbc.user": @secret(env:DB_USER);
    "spark.jdbc.password": @secret(gcp:prod-db-password);
    
    # Encryption key from Vault
    "spark.encryption.key": @secret(vault:kv-v2/data/spark/encryption-key)[base64]
  };
  
  # ============================================
  # Monitoring & Alerting
  # ============================================
  monitoring: {
    # Datadog API key
    datadog-api-key: @secret(gcp:datadog-api-key);
    
    # Slack webhook for alerts (URL contains secret token)
    slack-webhook: @secret(gcp:slack-webhook-url);
    
    # PagerDuty integration key
    pagerduty-key: @secret(gcp:pagerduty-integration-key)
  };
  
  # ============================================
  # Secrets Array (Multiple API Keys)
  # ============================================
  backup-api-keys[3]: [
    @secret(gcp:backup-key-1);
    @secret(gcp:backup-key-2);
    @secret(gcp:backup-key-3)
  ];
  
  # ============================================
  # SSH Keys (Base64 Encoded)
  # ============================================
  ssh: {
    private-key: @secret(gcp:ssh-private-key)[base64];
    public-key: @secret(gcp:ssh-public-key)[base64];
    known-hosts: @secret(file:ssh/known_hosts)[trim]
  }
}
```