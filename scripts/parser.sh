#!/bin/bash

INPUT_FILE="${1:-pipeline.mof}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File $INPUT_FILE not found."
    exit 1
fi

# ==============================================================================
# STAGE 1: Pre-processing (The Tokenizer)
# 1. Remove comments
# 2. Handle |...| blocks: Convert newlines inside pipes to literal \n to keep oneline for awk
# 3. Pad structural characters with spaces for easy tokenizing
# ==============================================================================

# Helper to read file and process multi-line strings |...| first
awk '
BEGIN { ORS=""; }
{
    # Remove comments
    gsub(/#[^\n]*/, "", $0)

    # Handle Fence String |...| logic
    # We reconstruct the file into a single line stream first to handle newlines inside |...|
    print $0 "\n"
}' "$INPUT_FILE" | \
awk '
BEGIN { RS="|"; ORS=""; check=0 }
{
    if (check % 2 == 1) {
        # Inside Fence: Escape newlines and quotes
        gsub(/\n/, "\\n", $0)
        gsub(/"/, "\\\"", $0)
        print "\"" $0 "\"" # Convert to quoted string
    } else {
        # Outside Fence: Print as is
        gsub(/\n/, " ", $0) # Flatten normal newlines
        print $0
    }
    check++
}' | \
# Tokenize: Add spaces around structural chars: { } [ ] ( ) = ; : ,
sed -E 's/([{}[\].=;:(),])/ \1 /g' | \
# Clean up double spaces
tr -s ' ' | \
# Pass to the Main Parser
awk '
BEGIN {
    # State Machine Variables
    state = "ROOT"   # ROOT, OBJECT, ARRAY, TABLE_HEAD, TABLE_BODY
    depth = 0
    json_out = ""

    print "{"
}

# --- Utility Functions ---
function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }
function is_number(s) { return s ~ /^[0-9]+(\.[0-9]+)?$/ }
function is_bool(s) { return s ~ /^(true|false|null)$/ }

function format_val(v) {
    if (v ~ /^".*"$/) return v  # Already quoted
    if (is_number(v) || is_bool(v)) return v
    return "\"" v "\""          # Quote string identifiers
}

function print_key(k) { printf "\"%s\": ", k }

# --- Main Loop ---
{
    for (i = 1; i <= NF; i++) {
        token = $i

        # SKIP standard tokens that are just noise in specific contexts
        if (token == "MOF_HEADER") continue

        # 1. ROOT / OBJECT STATE
        if (state == "ROOT" || state == "OBJECT") {
            if (token == "}") {
                print "}"
                depth--
                # Heuristic: if depth > 0, we might need a comma if explicitly requested,
                # but for simple JSON output logic, we rely on structure.
                continue
            }
            if (token == "!mof/1.0.0") continue
            if (token == "{") {
                print "{"
                depth++
                state = "OBJECT"
                continue
            }
            if (token == "=") { state = "ASSIGN"; continue }
            if (token == ";") { print "," ; continue } # End of key-value pair

            # It must be a Key
            print_key(token)
        }

        # 2. ASSIGNMENT STATE
        else if (state == "ASSIGN") {
            if (token == "{") {
                printf "{\n"
                depth++
                state = "OBJECT"
            }
            else if (token == "[") {
                state = "ARRAY_START" # Check if it is table or normal array
            }
            else if (token == "(") {
                state = "TABLE_HEAD"
                delete headers
                h_idx = 0
            }
            else {
                # Primitive value
                printf "%s", format_val(token)
                state = "WAIT_TERM" # Wait for semicolon
            }
        }

        # 3. WAIT FOR TERMINATOR (;)
        else if (state == "WAIT_TERM") {
            if (token == ";") {
                print ","
                if (depth == 0) state = "ROOT"
                else state = "OBJECT"
            }
        }

        # 4. ARRAY / LIST (Using ; as separator)
        else if (state == "ARRAY_START") {
            printf "["
            state = "ARRAY_BODY"
            # Handle immediate close []
            if (token == "]") { printf "]"; state = "WAIT_TERM"; }
            else { i--; } # Reprocess token
        }
        else if (state == "ARRAY_BODY") {
            if (token == "]") {
                printf "]"
                state = "WAIT_TERM"
            }
            else if (token == ";") {
                printf ","
            }
            else {
                printf "%s", format_val(token)
            }
        }

        # 5. TABLE: HEADERS (key = (a,b) ...)
        else if (state == "TABLE_HEAD") {
            if (token == ")") continue
            if (token == "[") {
                state = "TABLE_BODY"
                printf "[\n"
                row_start = 1
                col_idx = 0
            }
            else if (token == ",") continue
            else {
                # Capture nested keys (target.table) -> target.table
                # AWK handles dots naturally in string
                headers[h_idx++] = token
            }
        }

        # 6. TABLE: BODY (Using : as separator)
        else if (state == "TABLE_BODY") {
            if (token == "]") {
                print "" # Newline before closing array
                printf "]"
                state = "WAIT_TERM"
            }
            else if (token == ";") {
                # End of Row
                print "},"
                row_start = 1
                col_idx = 0
            }
            else if (token == ":") {
                # Column Separator -> Ignore, just move to next value logic
                continue
            }
            else {
                # Data Value
                if (row_start) { printf "{"; row_start=0 }
                else { printf ", " }

                # Handle Nested Key Logic (a.b -> "a": {"b": ...})
                # For high speed, we generate flat keys or simple nesting mapping
                # Logic: headers[col_idx] is "target.table"
                # Output: "target.table": "value" (Simplest for JSON to be consumed by App)

                # Advanced: Flatten dots to objects?
                # Let keep it compliant with the "Column Flattening" concept -> "config.timeout": 30

                printf "\"%s\": %s", headers[col_idx], format_val(token)
                col_idx++
            }
        }
    }
}
END {
    print "}"
}' | \
# Post-processing to clean up JSON syntax errors (trailing commas)
sed 's/,[\s\n]*}/}/g' | \
sed 's/,[\s\n]*]/]/g' | \
# Pretty print (Optional: requires jq, otherwise plain text)
jq . 2>/dev/null || cat
