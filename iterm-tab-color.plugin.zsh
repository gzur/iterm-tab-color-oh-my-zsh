# Debug function (disabled by default, enable with TC_DEBUG=1)
tc_debug() {
    [[ -n "$TC_DEBUG" ]] && echo "[TC] $*" >&2
    return 0
}

tc_debug "Plugin starting..."

tcConfigFilePath="$(dirname "$0")/.tc-config"
tcDebugFile="$(dirname "$0")/tc-debug.log"

tc_debug "Config path: $tcConfigFilePath"

# Initialize arrays
declare -gA tcConfigColors
declare -ga orderedConfig

tc_debug "Loading config..."

# Read config file line by line without pipe
while read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
        continue
    fi
    
    # Parse key=value pairs
    if [[ "$line" == *"="* ]]; then
        configKey="${line%%=*}"
        hexValue="${line#*=}"
        
        if [[ -n "$configKey" ]] && [[ -n "$hexValue" ]]; then
            tc_debug "Adding: '$configKey' -> '$hexValue'"
            orderedConfig+=( "$configKey" )
            tcConfigColors[$configKey]="$hexValue"
        fi
    fi
done < "$tcConfigFilePath"

tc_debug "Config loaded. Found ${#orderedConfig[@]} entries."

function directory_tab_color() {
  tc_debug "Directory change: $PWD"
  try_set_tab_color "$PWD"
}

function command_tab_color() {
  tc_debug "Command: $1"
  try_set_tab_color "$1" "command"
}

function try_set_tab_color() {
  local is_command=$2
  tc_debug "Array size: ${#orderedConfig[@]}, checking '$1' against patterns"
  
  for k in "${orderedConfig[@]}"; do
    # Skip empty patterns
    if [[ -z "$k" ]]; then
      continue
    fi
    
    if [[ "$1" =~ $k ]]; then
      tc_debug "MATCH: '$k' -> color ${tcConfigColors[$k]}"
      iterm_tab_color "$tcConfigColors[$k]"
      return 0
    fi
  done
  
  # Only reset color for directory changes, not commands
  if [[ -z "$is_command" ]]; then
    tc_debug "No match found, resetting color"
    iterm_tab_color
  fi
}

function iterm_tab_color() {
  if [ $# -eq 0 ]; then
    # Reset tab color if called with no arguments
    echo -ne "\033]6;1;bg;*;default\a"
    return 0
  elif [ $# -eq 1 ]; then
    if ( [[ $1 == \#* ]] ); then
      # If single argument starts with '#', skip first character to find hex value
      RED_HEX=${1:1:2}
      GREEN_HEX=${1:3:2}
      BLUE_HEX=${1:5:2}
    else
      # If single argument doesn't start with '#', assume it's hex value
      RED_HEX=${1:0:2}
      GREEN_HEX=${1:2:2}
      BLUE_HEX=${1:4:2}
    fi

    RED=$(( 16#${RED_HEX} ))
    GREEN=$(( 16#${GREEN_HEX} ))
    BLUE=$(( 16#${BLUE_HEX} ))

    echo -ne "\033]6;1;bg;red;brightness;$RED\a"
    echo -ne "\033]6;1;bg;green;brightness;$GREEN\a"
    echo -ne "\033]6;1;bg;blue;brightness;$BLUE\a"

    return 0
  fi

  # If more than 1 argument, assume 3 arguments were passed
  echo -ne "\033]6;1;bg;red;brightness;$1\a"
  echo -ne "\033]6;1;bg;green;brightness;$2\a"
  echo -ne "\033]6;1;bg;blue;brightness;$3\a"
}

alias tc='iterm_tab_color'
preexec_functions=(${preexec_functions[@]} "command_tab_color")
precmd_functions=(${precmd_functions[@]} "directory_tab_color")
