# .bashrc
# ============================================================================
#  Sections:
#    1. System defaults       4. Shell behavior      7. Functions
#    2. PATH                  5. Appearance          8. External tools
#    3. History               6. Aliases
#
#  NOTE: ALIASES must stay above FUNCTIONS. Bash expands aliases inside
#  function bodies when this file is sourced, so the aliases must already
#  exist when the functions are defined.
# ============================================================================


# ===== 1. SYSTEM DEFAULTS ==================================================

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi


# ===== 2. PATH =============================================================

if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

# opencode
[[ ":$PATH:" != *":/home/pilo/.opencode/bin:"* ]] && PATH="/home/pilo/.opencode/bin:$PATH"

# added by fedup init
[[ ":$PATH:" != *":/home/pilo/fedup-v0.1.0-linux-x86_64:"* ]] && PATH="/home/pilo/fedup-v0.1.0-linux-x86_64:$PATH"

# added by fedup (npm global)
[[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]] && PATH="$HOME/.npm-global/bin:$PATH"

export PATH


# ===== 3. HISTORY ==========================================================

export HISTFILESIZE=10000       # max entries in the history file
export HISTSIZE=500             # max entries kept in memory
export HISTTIMEFORMAT="%F %T"   # add a timestamp to each entry

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Append to the history file instead of overwriting it, so a new terminal
# doesn't wipe the history of older sessions
shopt -s histappend

# Share history between open terminals: write + re-read on every prompt
_bashrc_history_sync() {
	history -a
	history -n
}
# PROMPT_COMMAND is an array on bash >= 5.1; register only once
if [[ " ${PROMPT_COMMAND[*]:-} " != *"_bashrc_history_sync"* ]]; then
	PROMPT_COMMAND+=(_bashrc_history_sync)
fi


# ===== 4. SHELL BEHAVIOR ===================================================

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize

# Readline settings (only valid in interactive shells)
if [[ $- == *i* ]]; then
    bind "set completion-ignore-case on"   # case-insensitive tab completion
    bind "set show-all-if-ambiguous on"    # show completion list on first Tab
fi


# ===== 5. APPEARANCE =======================================================

# To have colors for ls and all grep commands such as grep, egrep and zgrep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'


# ===== 6. ALIASES ==========================================================
# (must stay above FUNCTIONS - see note at the top of this file)

# Aliases to modified commands
alias mv='mv -i'
alias mkdir='mkdir -p'
if ps auxf >/dev/null 2>&1; then
	alias ps='ps auxf'
else
	alias ps='ps aux'
fi
alias ping='ping -c 10'
alias less='less -R'
alias cls='clear'

# Modern ls replacement (also used by the cd function below)
alias ls='eza --icons -Ah --group-directories-first'


# ===== 7. FUNCTIONS ========================================================

# --- Navigation ------------------------------------------------------------

# Automatically do an ls after each cd, z, or zoxide
cd() {
	if [ -n "$1" ]; then
		builtin cd "$@" && ls
	else
		builtin cd ~ && ls
	fi
}

# --- Files and archives ----------------------------------------------------

# Extracts any archive(s) (if unp isn't installed)
extract() {
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			case $archive in
			*.tar.bz2) tar xvjf "$archive" ;;
			*.tar.gz) tar xvzf "$archive" ;;
			*.bz2) bunzip2 "$archive" ;;
			*.rar) unrar x "$archive" ;;
			*.gz) gunzip "$archive" ;;
			*.tar) tar xvf "$archive" ;;
			*.tbz2) tar xvjf "$archive" ;;
			*.tgz) tar xvzf "$archive" ;;
			*.zip) unzip "$archive" ;;
			*.Z) uncompress "$archive" ;;
			*.7z) 7z x "$archive" ;;
			*) echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

# Interactive remove: files go to the trash, directories ask first
rm() {
    local arg reply

    # Any flags? You know what you're doing - use the real rm
    for arg in "$@"; do
        case "$arg" in
            --) break ;;
            -*) command rm "$@"; return ;;
        esac
    done

    if (( $# == 0 )); then
        echo "rm: missing operand" >&2
        echo "Try 'rm --help' for more information." >&2
        return 1
    fi

    # Choose the backend command
    local backend
    if command -v trash-put >/dev/null 2>&1; then
        backend=(trash-put --)
    elif command -v trash >/dev/null 2>&1; then
        backend=(trash -v --)
    elif command -v gio >/dev/null 2>&1; then
        backend=(gio trash) # gio trash has no '--' separator
    else
        backend=(command rm -i --)
    fi

    for arg in "$@"; do
        [[ "$arg" == -- ]] && continue
        # Shield dash-prefixed filenames for backends without '--'
        [[ "$arg" == -* && "$arg" != /* ]] && arg="./$arg"

        if [[ -d "$arg" && ! -L "$arg" ]]; then
            printf "'%s' is a directory.\n" "$arg"
            read -r -p "Delete this directory recursively? [y/N] " reply

            case "$reply" in
                [Yy]|[Yy][Ee][Ss])
                    # -r without -I: the prompt above already confirmed
                    command rm -r -- "$arg"
                    ;;
                *)
                    echo "Skipped '$arg'."
                    ;;
            esac
        else
            "${backend[@]}" "$arg"
        fi
    done
}

# --- Text ------------------------------------------------------------------

# Trim leading and trailing spaces (for scripts)
trim() {
	local var=$*
	var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
	echo -n "$var"
}

# --- System and desktop ----------------------------------------------------

# Add an "alert" for long running commands.  Use like so:
#   sleep 10; alert
alert() {
	local exit_status=$? icon last_command title
	if [ "$exit_status" -eq 0 ]; then
		icon=terminal
		title=Done
	else
		icon=error
		title=Failed
	fi
	last_command=$(history 1 | sed -e 's/^[[:space:]]*[0-9]\+[[:space:]]*//;s/[;&|][[:space:]]*alert$//')

	if command -v notify-send >/dev/null 2>&1; then
		notify-send --urgency=low -i "$icon" "$last_command"
	else
		printf '%s: %s\n' "$title" "$last_command"
	fi
}

# Types clipboard text after a delay
clicktype() {
    local wait="${1:-3}"       # Seconds to wait before typing
    local delay="${2:-20}"     # Milliseconds between keystrokes

    # Simple countdown
    while (( wait > 0 )); do
        printf "\rTyping in %d... " "$wait"
        sleep 1
        ((wait--))
    done
    printf "\rTyping now!      \n"

    if command -v ydotool >/dev/null 2>&1; then
        # Compositor-independent - works on any session, but needs the
        # ydotoold daemon running. The only option on KDE Plasma/GNOME Wayland.
        # Clipboard is piped via stdin (--file=-), which also types it
        # literally instead of interpreting backslash escapes.
        if [[ -n $WAYLAND_DISPLAY ]]; then
            wl-paste | ydotool type --key-delay="$delay" --file=-
        else
            xclip -o -selection clipboard | ydotool type --key-delay="$delay" --file=-
        fi

    elif [[ -n $WAYLAND_DISPLAY ]] && command -v wl-paste >/dev/null 2>&1 && command -v wtype >/dev/null 2>&1; then
        # Wayland via wtype - only works on wlroots-based compositors
        # (sway, labwc, Hyprland, ...). KWin and Mutter lack the protocol.
        case ${XDG_CURRENT_DESKTOP,,} in
            *kde*|*plasma*|*gnome*)
                echo "Error: your compositor doesn't support wtype (no virtual keyboard protocol)." >&2
                echo "Install ydotool instead: sudo dnf install ydotool" >&2
                return 1
                ;;
        esac
        wl-paste | wtype -d "$delay" -

    elif command -v xclip >/dev/null 2>&1 && command -v xdotool >/dev/null 2>&1; then
        # X11
        xdotool type --delay "$delay" "$(xclip -o -selection clipboard)"

    else
        echo "Error: clicktype requires one of:" >&2
        echo "  ydotool (any session, needs ydotoold) - only option for KDE Plasma/GNOME Wayland" >&2
        echo "  wl-paste + wtype (wlroots compositors: sway, labwc, Hyprland, ...)" >&2
        echo "  xclip + xdotool (X11)" >&2
        return 1
    fi
}


# ===== 8. EXTERNAL TOOLS ===================================================

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# zoxide (smarter cd: z / zi) - keep last so it hooks into the final
# PROMPT_COMMAND and sees all functions defined above
eval "$(zoxide init bash)"
. "$HOME/.cargo/env"
