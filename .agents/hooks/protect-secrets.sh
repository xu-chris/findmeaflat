#!/bin/bash

# Protect secrets before Read, Edit, Write, or Bash tool use.

SAFETY_LEVEL="high"

ALLOWLIST_REGEXES=(
  '\.env\.example$'
  '\.env\.sample$'
  '\.env\.template$'
  '\.env\.schema$'
  '\.env\.defaults$'
  'env\.example$'
  'example\.env$'
)

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

FILE_LEVELS=()
FILE_IDS=()
FILE_REGEXES=()
FILE_REASONS=()

BASH_LEVELS=()
BASH_IDS=()
BASH_REGEXES=()
BASH_REASONS=()

add_file_pattern() {
  FILE_LEVELS[${#FILE_LEVELS[@]}]="$1"
  FILE_IDS[${#FILE_IDS[@]}]="$2"
  FILE_REGEXES[${#FILE_REGEXES[@]}]="$3"
  FILE_REASONS[${#FILE_REASONS[@]}]="$4"
}

add_bash_pattern() {
  BASH_LEVELS[${#BASH_LEVELS[@]}]="$1"
  BASH_IDS[${#BASH_IDS[@]}]="$2"
  BASH_REGEXES[${#BASH_REGEXES[@]}]="$3"
  BASH_REASONS[${#BASH_REASONS[@]}]="$4"
}

# Critical files
add_file_pattern critical env-file '(^|/)\.env(\.[^/]*)?$' '.env file contains secrets'
add_file_pattern critical envrc '(^|/)\.envrc$' '.envrc (direnv) contains secrets'
add_file_pattern critical ssh-private-key '(^|/)\.ssh/id_[^/]+$' 'SSH private key'
add_file_pattern critical ssh-private-key-2 '(^|/)(id_rsa|id_ed25519|id_ecdsa|id_dsa)$' 'SSH private key'
add_file_pattern critical ssh-authorized '(^|/)\.ssh/authorized_keys$' 'SSH authorized_keys'
add_file_pattern critical aws-credentials '(^|/)\.aws/credentials$' 'AWS credentials file'
add_file_pattern critical aws-config '(^|/)\.aws/config$' 'AWS config may contain secrets'
add_file_pattern critical kube-config '(^|/)\.kube/config$' 'Kubernetes config contains credentials'
add_file_pattern critical pem-key '\.pem$' 'PEM key file'
add_file_pattern critical key-file '\.key$' 'Key file'
add_file_pattern critical p12-key '\.(p12|pfx)$' 'PKCS12 key file'

# High-sensitivity files
add_file_pattern high credentials-json '(^|/)credentials\.json$' 'Credentials file'
add_file_pattern high secrets-file '(^|/)(secrets?|credentials?)\.(json|ya?ml|toml)$' 'Secrets configuration file'
add_file_pattern high service-account 'service[_-]?account.*\.json$' 'GCP service account key'
add_file_pattern high gcloud-creds '(^|/)\.config/gcloud/.*(credentials|tokens)' 'GCloud credentials'
add_file_pattern high azure-creds '(^|/)\.azure/(credentials|accessTokens)' 'Azure credentials'
add_file_pattern high docker-config '(^|/)\.docker/config\.json$' 'Docker config may contain registry auth'
add_file_pattern high netrc '(^|/)\.netrc$' '.netrc contains credentials'
add_file_pattern high npmrc '(^|/)\.npmrc$' '.npmrc may contain auth tokens'
add_file_pattern high pypirc '(^|/)\.pypirc$' '.pypirc contains PyPI credentials'
add_file_pattern high gem-creds '(^|/)\.gem/credentials$' 'RubyGems credentials'
add_file_pattern high vault-token '(^|/)(\.vault-token|vault-token)$' 'Vault token file'
add_file_pattern high keystore '\.(keystore|jks)$' 'Java keystore'
add_file_pattern high htpasswd '(^|/)\.?htpasswd$' 'htpasswd contains hashed passwords'
add_file_pattern high pgpass '(^|/)\.pgpass$' 'PostgreSQL password file'
add_file_pattern high my-cnf '(^|/)\.my\.cnf$' 'MySQL config may contain password'

# Strict files
add_file_pattern strict database-config '(^|/)(config/)?database\.(json|ya?ml)$' 'Database config may contain passwords'
add_file_pattern strict ssh-known-hosts '(^|/)\.ssh/known_hosts$' 'SSH known_hosts reveals infrastructure'
add_file_pattern strict gitconfig '(^|/)\.gitconfig$' '.gitconfig may contain credentials'
add_file_pattern strict curlrc '(^|/)\.curlrc$' '.curlrc may contain auth'

# Critical commands
add_bash_pattern critical cat-env '(^|[^[:alnum:]_])(cat|less|head|tail|more|bat|view)[[:space:]]+[^|;]*\.env([^[:alnum:]_]|$)' 'Reading .env file exposes secrets'
add_bash_pattern critical cat-ssh-key '(^|[^[:alnum:]_])(cat|less|head|tail|more|bat)[[:space:]]+[^|;]*(id_rsa|id_ed25519|id_ecdsa|id_dsa|\.pem|\.key)([^[:alnum:]_]|$)' 'Reading private key'
add_bash_pattern critical cat-aws-creds '(^|[^[:alnum:]_])(cat|less|head|tail|more)[[:space:]]+[^|;]*\.aws/credentials' 'Reading AWS credentials'

# High-sensitivity environment commands
add_bash_pattern high env-dump '(^|[^[:alnum:]_])printenv([^[:alnum:]_]|$)|(^|[;&|][[:space:]]*)env[[:space:]]*($|[;&|])' 'Environment dump may expose secrets'
add_bash_pattern high echo-secret-var '(^|[^[:alnum:]_])echo[^;|&]*\$\{?[[:alnum:]_]*(SECRET|KEY|TOKEN|PASSWORD|PASSW|CREDENTIAL|API_KEY|AUTH|PRIVATE)[[:alnum:]_]*\}?' 'Echoing secret variable'
add_bash_pattern high printf-secret-var '(^|[^[:alnum:]_])printf[^;|&]*\$\{?[[:alnum:]_]*(SECRET|KEY|TOKEN|PASSWORD|CREDENTIAL|API_KEY|AUTH|PRIVATE)[[:alnum:]_]*\}?' 'Printing secret variable'
add_bash_pattern high cat-secrets-file '(^|[^[:alnum:]_])(cat|less|head|tail|more)[[:space:]]+[^|;]*(credentials?|secrets?)\.(json|ya?ml|toml)' 'Reading secrets file'
add_bash_pattern high cat-netrc '(^|[^[:alnum:]_])(cat|less|head|tail|more)[[:space:]]+[^|;]*\.netrc' 'Reading .netrc credentials'
add_bash_pattern high source-env '(^|[^[:alnum:]_])source[[:space:]]+[^|;]*\.env([^[:alnum:]_]|$)|(^|[;&|][[:space:]]*)\.[[:space:]]+[^|;]*\.env([^[:alnum:]_]|$)' 'Sourcing .env loads secrets'
add_bash_pattern high export-cat-env 'export[[:space:]]+.*\$\(cat[[:space:]]+[^)]*\.env' 'Exporting secrets from .env'

# High-sensitivity exfiltration commands
add_bash_pattern high curl-upload-env '(^|[^[:alnum:]_])curl[^;|&]*(-d[[:space:]]*@|-F[[:space:]]*[^=]+=@|--data[^=]*=@)[^;|&]*(\.env|credentials|secrets|id_rsa|\.pem|\.key)' 'Uploading secrets via curl'
add_bash_pattern high curl-post-secrets '(^|[^[:alnum:]_])curl[^;|&]*-X[[:space:]]*POST[^;|&]*(\.env|credentials|secrets)' 'POSTing secrets via curl'
add_bash_pattern high wget-post-secrets '(^|[^[:alnum:]_])wget[^;|&]*--post-file[^;|&]*(\.env|credentials|secrets)' 'POSTing secrets via wget'
add_bash_pattern high scp-secrets '(^|[^[:alnum:]_])scp[^;|&]*(\.env|credentials|secrets|id_rsa|\.pem|\.key)[^;|&]+:' 'Copying secrets via scp'
add_bash_pattern high rsync-secrets '(^|[^[:alnum:]_])rsync[^;|&]*(\.env|credentials|secrets|id_rsa)[^;|&]+:' 'Syncing secrets via rsync'
add_bash_pattern high nc-secrets '(^|[^[:alnum:]_])nc[^;|&]*<[^;|&]*(\.env|credentials|secrets|id_rsa)' 'Exfiltrating secrets via netcat'

# High-sensitivity mutation commands
add_bash_pattern high cp-env '(^|[^[:alnum:]_])cp[^;|&]*\.env([^[:alnum:]_]|$)' 'Copying .env file'
add_bash_pattern high cp-ssh-key '(^|[^[:alnum:]_])cp[^;|&]*(id_rsa|id_ed25519|\.pem|\.key)([^[:alnum:]_]|$)' 'Copying private key'
add_bash_pattern high mv-env '(^|[^[:alnum:]_])mv[^;|&]*\.env([^[:alnum:]_]|$)' 'Moving .env file'
add_bash_pattern high rm-ssh-key '(^|[^[:alnum:]_])rm[^;|&]*(id_rsa|id_ed25519|id_ecdsa|authorized_keys)' 'Deleting SSH key'
add_bash_pattern high rm-env '(^|[^[:alnum:]_])rm.*\.env([^[:alnum:]_]|$)' 'Deleting .env file'
add_bash_pattern high rm-aws-creds '(^|[^[:alnum:]_])rm[^;|&]*\.aws/credentials' 'Deleting AWS credentials'
add_bash_pattern high truncate-secrets '(^|[^[:alnum:]_])truncate.*\.(env|pem|key)([^[:alnum:]_]|$)|(^|[;&|][[:space:]]*)>[[:space:]]*\.env([^[:alnum:]_]|$)' 'Truncating secrets file'

# High-sensitivity process commands
add_bash_pattern high proc-environ '/proc/[^/]*/environ' 'Reading process environment'
add_bash_pattern high xargs-cat-env 'xargs.*cat|\.env.*xargs' 'Reading .env via xargs'
add_bash_pattern high find-exec-cat-env 'find.*\.env.*-exec|find.*-exec.*(cat|less)' 'Finding and reading .env files'

# Strict commands
add_bash_pattern strict grep-password '(^|[^[:alnum:]_])grep[^|;]*(-r|--recursive)[^|;]*(password|secret|api.?key|token|credential)' 'Grep for secrets may expose them'
add_bash_pattern strict base64-secrets '(^|[^[:alnum:]_])base64[^|;]*(\.env|credentials|secrets|id_rsa|\.pem)' 'Base64 encoding secrets'

level_number() {
  case "$1" in
    critical) echo 1 ;;
    high) echo 2 ;;
    strict) echo 3 ;;
    *) echo 2 ;;
  esac
}

is_allowlisted() {
  local value="$1"
  local regex

  [[ -n "$value" ]] || return 1
  for regex in "${ALLOWLIST_REGEXES[@]}"; do
    [[ "$value" =~ $regex ]] && return 0
  done
  return 1
}

check_file_path() {
  local value="$1"
  local pattern
  local index
  local threshold

  [[ -n "$value" ]] || return 1
  # Runs before PROTECTED_PATTERNS, which substring-matches ".env" and would
  # otherwise deny every allowlisted template. check_bash_command allowlists
  # first for the same reason.
  is_allowlisted "$value" && return 1

  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$value" == *"$pattern"* ]]; then
      MATCH_ID="protected-path"
      MATCH_LEVEL="critical"
      MATCH_REASON="matches protected pattern '$pattern'"
      return 0
    fi
  done

  threshold=$(level_number "$SAFETY_LEVEL")

  for ((index = 0; index < ${#FILE_REGEXES[@]}; index++)); do
    (( $(level_number "${FILE_LEVELS[$index]}") > threshold )) && continue
    if [[ "$value" =~ ${FILE_REGEXES[$index]} ]]; then
      MATCH_ID="${FILE_IDS[$index]}"
      MATCH_LEVEL="${FILE_LEVELS[$index]}"
      MATCH_REASON="${FILE_REASONS[$index]}"
      return 0
    fi
  done
  return 1
}

check_bash_command() {
  local value="$1"
  local index
  local threshold

  [[ -n "$value" ]] || return 1
  is_allowlisted "$value" && return 1
  threshold=$(level_number "$SAFETY_LEVEL")

  for ((index = 0; index < ${#BASH_REGEXES[@]}; index++)); do
    (( $(level_number "${BASH_LEVELS[$index]}") > threshold )) && continue
    if [[ "$value" =~ ${BASH_REGEXES[$index]} ]]; then
      MATCH_ID="${BASH_IDS[$index]}"
      MATCH_LEVEL="${BASH_LEVELS[$index]}"
      MATCH_REASON="${BASH_REASONS[$index]}"
      return 0
    fi
  done
  return 1
}

deny() {
  local action="$1"
  local emoji

  case "$MATCH_LEVEL" in
    critical) emoji='🔐' ;;
    high) emoji='🛡️' ;;
    strict) emoji='⚠️' ;;
  esac

  echo "$emoji [$MATCH_ID] Cannot $action: $MATCH_REASON" >&2
  exit 2
}

INPUT=$(cat)
if ! TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null); then
  echo '{}'
  exit 0
fi

shopt -s nocasematch

case "$TOOL_NAME" in
  Read|Edit|Write)
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
    FILE_PATH="${FILE_PATH//\\//}"
    if check_file_path "$FILE_PATH"; then
      case "$TOOL_NAME" in
        Read) deny read ;;
        Edit) deny modify ;;
        Write) deny 'write to' ;;
      esac
    fi
    ;;
  Bash)
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
    check_bash_command "$COMMAND" && deny execute
    ;;
esac

echo '{}'
exit 0
