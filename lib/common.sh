export_env_dir() {
    env_dir=$1
    blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH|LD_LIBRARY_PATH)$'}
    if [ -d "$env_dir" ]; then
        for e in $(ls $env_dir); do
            echo "$e" | grep -qvE "$blacklist_regex" &&
            export "$e=$(cat $env_dir/$e)"
            :
        done
    fi
}
