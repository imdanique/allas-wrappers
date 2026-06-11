#!/bin/bash

###configure these first###
ALLAS_CLI_UTILS="/csc/epitkane/software/allas-cli-utils"
OS_USERNAME="cscusername"
OS_PROJECT_NAME="project_0000000"
C4GH_KEY="$HOME/path/username.sec"
####################################

if [[ -z "$1" ]]; then
    echo "Usage: $0 <directory_path>"
    echo "Example: $0 PARENT_DIR/CHILD_DIR"
    exit 1
fi

CONTAINER="$1"

read -sp "Enter csc password: " OS_PASSWORD
echo
read -sp "Enter c4gh key passphrase: " C4GH_PASSPHRASE
echo
export OS_PASSWORD C4GH_PASSPHRASE

export allas_conf_path="$ALLAS_CLI_UTILS/allas_conf"

source "$ALLAS_CLI_UTILS"/allas_conf -f -k -u "$OS_USERNAME" -p "$OS_PROJECT_NAME"

echo "Listing files in $CONTAINER..."
mapfile -t files < <(
    "$ALLAS_CLI_UTILS"/a-list "$CONTAINER" \
    | sed "s|^$CONTAINER/||"
)

echo "Found ${#files[@]} files to download."

failed=()
for ob in "${files[@]}"; do
    [[ -z "$ob" ]] && continue

    full_path="$CONTAINER/$ob"
    target="${ob%%.c4gh}"
    echo "Downloading and decrypting: $full_path -> $target"

    if ! "$ALLAS_CLI_UTILS"/a-get \
            --sk "$C4GH_KEY" \
            -t "./$target" \
            "$full_path"; then
        echo "FAILED: $full_path" >&2
        failed+=("$full_path")
    fi

done

if [[ ${#failed[@]} -gt 0 ]]; then
    echo ""
    echo "The following files failed:"
    printf '  %s\n' "${failed[@]}"
    exit 1
fi

echo "All files downloaded successfully."
