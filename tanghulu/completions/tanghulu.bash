_tanghulu() {
    local cur prev words cword
    if declare -F _init_completion >/dev/null; then
        _init_completion || return
    else
        COMPREPLY=()
        cur=${COMP_WORDS[COMP_CWORD]}
        prev=${COMP_WORDS[COMP_CWORD-1]}
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi

    local blocks_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tanghulu/blocks"
    local names=() f
    if [[ -d $blocks_dir ]]; then
        for f in "$blocks_dir"/*.block; do
            [[ -e $f ]] || continue
            names+=("$(basename "$f" .block)")
        done
    fi

    local subs="add list delete rename redefine preview config help -h --help -v --version"

    case $cword in
        1)
            COMPREPLY=( $(compgen -W "$subs ${names[*]}" -- "$cur") )
            ;;
        2)
            case ${words[1]} in
                delete|redefine|preview|rename)
                    COMPREPLY=( $(compgen -W "${names[*]}" -- "$cur") )
                    ;;
                config)
                    COMPREPLY=( $(compgen -W "sound" -- "$cur") )
                    ;;
            esac
            ;;
        3)
            if [[ ${words[1]} == config && ${words[2]} == sound ]]; then
                COMPREPLY=( $(compgen -W "on off" -- "$cur") )
            fi
            ;;
    esac
}

complete -F _tanghulu tanghulu
