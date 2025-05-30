# Fish Shell Configuration with Catppuccin Theme

# Remove welcome message
set fish_greeting

# Set default editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# Set PATH
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.cargo/bin $PATH
set -gx PATH $HOME/go/bin $PATH

# Wayland environment variables
set -gx QT_QPA_PLATFORM wayland
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx XDG_SESSION_TYPE wayland
set -gx XDG_SESSION_DESKTOP Hyprland
set -gx MOZ_ENABLE_WAYLAND 1
set -gx GDK_BACKEND wayland,x11

# Initialize Starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Aliases
alias ll='exa -l --icons'
alias la='exa -la --icons'
alias ls='exa --icons'
alias tree='exa --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias vim='nvim'
alias vi='nvim'
alias top='htop'
alias ps='procs'
alias du='dust'
alias df='duf'

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'

# System aliases
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -R'
alias autoremove='sudo pacman -Rns (pacman -Qtdq)'
alias clean='sudo pacman -Sc'

# Hyprland specific aliases
alias hypr-reload='hyprctl reload'
alias hypr-kill='hyprctl kill'
alias hypr-info='hyprctl info'
alias hypr-monitors='hyprctl monitors'
alias hypr-workspaces='hyprctl workspaces'

# Functions
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

function weather
    if test (count $argv) -eq 0
        curl wttr.in
    else
        curl wttr.in/$argv[1]
    end
end

function backup
    if test (count $argv) -eq 0
        echo "Usage: backup <file>"
        return 1
    end
    cp $argv[1] $argv[1].bak
    echo "Backup created: $argv[1].bak"
end

function ports
    netstat -tulanp
end

function myip
    curl -s ifconfig.me
end

# Fish syntax highlighting colors (Catppuccin Mocha)
set fish_color_normal cdd6f4
set fish_color_command 89b4fa
set fish_color_quote a6e3a1
set fish_color_redirection f5c2e7
set fish_color_end fab387
set fish_color_error f38ba8
set fish_color_param f2cdcd
set fish_color_comment 6c7086
set fish_color_match --background=brblue
set fish_color_selection white --bold --background=brblack
set fish_color_search_match bryellow --background=brblack
set fish_color_history_current --bold
set fish_color_operator 00a6b2
set fish_color_escape 00a6b2
set fish_color_cwd green
set fish_color_cwd_root red
set fish_color_valid_path --underline
set fish_color_autosuggestion 6c7086
set fish_color_user brgreen
set fish_color_host normal
set fish_color_cancel -r
set fish_pager_color_completion normal
set fish_pager_color_description B3A06D yellow
set fish_pager_color_prefix white --bold --underline
set fish_pager_color_progress brwhite --background=cyan

# Auto-start X at login
if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec Hyprland
    end
end
