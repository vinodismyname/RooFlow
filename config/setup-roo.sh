#!/usr/bin/env bash

# ------------- Color definitions -------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_info()   { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()   { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $*"; }

# ------------- Simple usage -------------
usage() {
  echo "Usage:"
  echo "  Local mode: $0 [--override]"
  echo "  Remote mode: $0 <REPO_URL> [--override]"
  echo
  echo "Options:"
  echo "  --override    Override existing .roo folder if it exists"
  exit 0
}

# ------------- Check for --help -------------
[[ "$1" == "--help" || "$1" == "-h" ]] && usage

# ------------- Parse arguments -------------
REMOTE_URL=""
OVERRIDE=false

for arg in "$@"; do
  if [[ "$arg" == "--override" ]]; then
    OVERRIDE=true
  elif [[ "$arg" != --* && -z "$REMOTE_URL" ]]; then
    REMOTE_URL="$arg"
  fi
done

# ------------- Basic directory setup -------------
ROO_DIR="$(pwd)/.roo"

# ------------- Determine OS and set sed options -------------
if [[ "$(uname)" == "Darwin" ]]; then
  SED_IN_PLACE=(-i "")
else
  SED_IN_PLACE=(-i)
fi

# -------------  Function to escape strings for sed ------------- 
escape_for_sed() {
    echo "$1" | sed 's/[\/&]/\\&/g'
}


# ------------- Check if in a Brazil workspace -------------
get_workspace_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/packageInfo" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1  # Return error code if no workspace root found
}

is_brazil_workspace() {
  local ws_root=$(get_workspace_root)
  [[ -n "$ws_root" && -d "$ws_root" ]]
}

# ------------- Setup directories -------------
setup_directories() {
  # Handle .roo directory
  if [[ -d "$ROO_DIR" ]]; then
    if $OVERRIDE; then
      log_info "Overriding existing .roo directory..."
      rm -rf "$ROO_DIR"
      mkdir -p "$ROO_DIR"
    else
      log_info "Using existing .roo directory..."
    fi
  else
    log_info "Creating new .roo directory..."
    mkdir -p "$ROO_DIR"
  fi

  # Create a sample system prompt if none found
  if ! find "$ROO_DIR" -name "system-prompt-*" | grep -q '.'; then
    cat > "$ROO_DIR/system-prompt-default.txt" <<EOF
# Default System Prompt Template

system_information:
SYSTEMS_SETTING_PLACEHOLDER

global_settings_path: GLOBAL_SETTINGS_PLACEHOLDER
mcp_location: MCP_LOCATION_PLACEHOLDER
mcp_settings: MCP_SETTINGS_PLACEHOLDER

EOF
  fi
}

# ------------- Clone the repo if in remote mode -------------
clone_repo_if_needed() {
  [[ -z "$REMOTE_URL" ]] && { log_info "Local mode: Using existing local files."; return; }

  if ! command -v git &>/dev/null; then
    log_error "git is not installed. Please install git before running remote mode."
    exit 1
  fi

  log_info "Remote mode: Fetching files from $REMOTE_URL ..."
  TEMP_DIR=$(mktemp -d)
  # Set trap to clean up temp directory on exit
  trap 'rm -rf "$TEMP_DIR"' EXIT
  
  # Use sparse checkout to get only what we need
  git init "$TEMP_DIR"
  cd "$TEMP_DIR" || exit 1
  git remote add origin "$REMOTE_URL"
  git config core.sparseCheckout true
  
  # Define which paths we want to checkout
  mkdir -p .git/info
  cat > .git/info/sparse-checkout <<EOF
config/.roo
config/.rooignore
config/.roomodes
EOF
  
  # Only include brazil-workspace-guidelines.yml if in a Brazil workspace
  is_brazil_workspace && echo "config/.roo/brazil-workspace-guidelines.yml" >> .git/info/sparse-checkout
  
  # Pull the files (depth 1 to avoid history)
  git pull --depth=1 origin main || git pull --depth=1 origin master
  
  # Move back to original directory
  cd - || exit 1
  
  # Check if we got the files we need
  if [[ ! -d "$TEMP_DIR/config/.roo" ]]; then
    log_error "Required files not found in the cloned repository. Check paths."
    exit 1
  fi
  
  # Copy the files - using simple copy commands with force flag
  [[ -d "$TEMP_DIR/config/.roo" ]] && cp -f "$TEMP_DIR/config/.roo/system-prompt-"* "$ROO_DIR"/ 2>/dev/null || true
  [[ -f "$TEMP_DIR/config/.rooignore" ]] && cp -f "$TEMP_DIR/config/.rooignore" .
  [[ -f "$TEMP_DIR/config/.roomodes" ]] && cp -f "$TEMP_DIR/config/.roomodes" .
  
  # Only copy brazil-workspace-guidelines.yml if in a Brazil workspace
  if is_brazil_workspace && [[ -f "$TEMP_DIR/config/.roo/brazil-workspace-guidelines.yml" ]]; then
    cp -f "$TEMP_DIR/config/.roo/brazil-workspace-guidelines.yml" "$ROO_DIR"/
    log_info "Copied Brazil workspace guidelines."
  fi
  
  log_info "Files extracted successfully."
}

# ------------- Generate system_info snippets -------------
generate_system_info() {
  local os
  local shell="bash"
  local home="$HOME"

  # Determine OS
  os=$(uname -s)
  [[ "$os" == "Darwin" ]] && os="macOS $(sw_vers -productVersion)" || os="$os $(uname -r)"

  # Build the output
  local output="system_information:\n  os: \"$os\"\n  shell: \"$shell\"\n  home_directory: \"$home\""

  # Add workspace information
  if is_brazil_workspace; then
    local ws_root=$(get_workspace_root)
    local guidelines_path="$ROO_DIR/brazil-workspace-guidelines.yml"
    
    output+="\n  working_directory:"
    
    # Add workspace_guidelines if the file exists
    [[ -f "$guidelines_path" ]] && output+="\n    workspace_guidelines: \"$guidelines_path\""
    
    # Add Brazil workspace information
    output+="\n    brazil_workspace_root: \"$ws_root\"\n    brazil_workspace_packages:"
    
    # List packages
    if [[ -d "$ws_root/src" ]]; then
      for pkg in "$ws_root/src/"*; do
        [[ -d "$pkg" ]] && output+="\n      $(basename "$pkg"): \"$pkg\""
      done
    fi
  else
    # Standard working directory for non-Brazil workspace
    output+="\n  working_directory: \"$(pwd)\""
  fi
  
  # Common ending
  output+="\n  initial_context: \"Recursive file list in working directory provided in environment_details\""
  
  echo -e "$output"
}

# ------------- Replace placeholders in system prompts -------------
process_system_prompts() {
  local tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  local sys_info_file="$tmp_dir/system_info.yaml"
  generate_system_info > "$sys_info_file"

  # Global placeholders
  local GLOBAL_SETTINGS="$HOME/.vscode-server/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_custom_modes.json"
  local MCP_LOCATION="$HOME/.local/share/Roo-Code/MCP"
  local MCP_SETTINGS="$HOME/.vscode-server/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_mcp_settings.json"
  local WORKSPACE="$(get_workspace_root 2>/dev/null || pwd)"

  find "$ROO_DIR" -type f -name "system-prompt-*" | while IFS= read -r file; do
    log_info "Processing system prompt: $file"
    local tmp_file="$tmp_dir/$(basename "$file").tmp"
    cp "$file" "$tmp_file"

    # Replace system_information placeholder with the YAML
    awk -v r="$(cat "$sys_info_file")" '{gsub(/SYSTEMS_SETTING_PLACEHOLDER/, r); print}' "$tmp_file" > "$tmp_file.new"
    mv "$tmp_file.new" "$tmp_file"

    # Replace other placeholders with sed
    sed "${SED_IN_PLACE[@]}" "s|WORKSPACE_PLACEHOLDER|$(escape_for_sed "$WORKSPACE")|g" "$tmp_file"
    sed "${SED_IN_PLACE[@]}" "s|GLOBAL_SETTINGS_PLACEHOLDER|$(escape_for_sed "$GLOBAL_SETTINGS")|g" "$tmp_file"
    sed "${SED_IN_PLACE[@]}" "s|MCP_LOCATION_PLACEHOLDER|$(escape_for_sed "$MCP_LOCATION")|g" "$tmp_file"
    sed "${SED_IN_PLACE[@]}" "s|MCP_SETTINGS_PLACEHOLDER|$(escape_for_sed "$MCP_SETTINGS")|g" "$tmp_file"

    # Move temp file back
    mv "$tmp_file" "$file"
    log_info "Completed: $file"
  done
}

# ----------------- Main Flow -----------------
setup_directories            # Ensure .roo exists, create/override as needed
clone_repo_if_needed         # If URL is passed, clone; else do nothing
process_system_prompts       # Replace placeholders
log_info "All tasks completed successfully."