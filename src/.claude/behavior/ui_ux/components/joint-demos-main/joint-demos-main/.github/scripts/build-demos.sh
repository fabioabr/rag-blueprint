#!/usr/bin/env bash
set -euo pipefail

# Usage: build-demos.sh [--force] [demo-name]
# When demo-name is provided, only that demo is built.
# When omitted, all demos are built.
# --force: continue building even if a demo fails (default: exit on first failure)
FORCE=false
FILTER=""
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        *) FILTER="$arg" ;;
    esac
done

SITE_DIR="_site"
FAILED=()
BUILT=()
SKIPPED=()

# Read per-demo config from demos.config.json (if it exists)
CONFIG_FILE="demos.config.json"
demo_config() {
    local demo="$1" field="$2"
    if [[ -f "$CONFIG_FILE" ]]; then
        node -e "
            const cfg = require('./$CONFIG_FILE');
            const val = (cfg.demos && cfg.demos['$demo'] && cfg.demos['$demo']['$field']);
            if (val !== undefined && val !== null) process.stdout.write(String(val));
        " 2>/dev/null || true
    fi
}

rm -rf "$SITE_DIR"
mkdir -p "$SITE_DIR"

for demo_dir in */; do
    demo_name="${demo_dir%/}"

    # Skip dotfiles, _site, and node_modules
    case "$demo_name" in
        .* | _site | node_modules) continue ;;
    esac

    # If a filter is provided, skip non-matching demos
    if [[ -n "$FILTER" && "$demo_name" != "$FILTER" ]]; then
        continue
    fi

    # Check demos.config.json for skip flag
    if [[ "$(demo_config "$demo_name" skip)" == "true" ]]; then
        echo ":: Skipping $demo_name (skip=true in demos.config.json)"
        SKIPPED+=("$demo_name")
        continue
    fi

    # Check demos.config.json for variant override, else use default fallback
    config_variant="$(demo_config "$demo_name" variant)"
    if [[ -n "$config_variant" ]]; then
        if [[ -d "$demo_dir/$config_variant" ]]; then
            build_dir="$demo_dir/$config_variant"
        else
            echo ":: WARNING: $demo_name variant '$config_variant' not found, falling back to default"
            config_variant=""
        fi
    fi

    if [[ -z "$config_variant" ]]; then
        # Default fallback: ts/ → js/, else skip
        if [[ -d "$demo_dir/ts" ]]; then
            build_dir="$demo_dir/ts"
        elif [[ -d "$demo_dir/js" ]]; then
            build_dir="$demo_dir/js"
        else
            echo ":: Skipping $demo_name (no ts/ or js/ subdirectory — add a variant to demos.config.json)"
            SKIPPED+=("$demo_name")
            continue
        fi
    fi

    # Check for build flags override in config
    config_build_flags="$(demo_config "$demo_name" buildFlags)"
    if [[ -n "$config_build_flags" ]]; then
        build_flags="$config_build_flags"
    elif grep -q 'vite build' "$build_dir/package.json" 2>/dev/null; then
        build_flags="--base=./ --mode=production"
    else
        build_flags="--mode=production"
    fi

    echo ":: Building $demo_name from $build_dir ($build_flags)"

    if (
        cd "$build_dir"
        npm install --ignore-scripts=false
        npm run build -- $build_flags
    ); then
        if [[ -d "$build_dir/dist" ]]; then
            cp -r "$build_dir/dist/." "$SITE_DIR/$demo_name/"
            BUILT+=("$demo_name")
            echo ":: Done $demo_name"
        else
            echo ":: FAILED: $demo_name built but no dist/ found"
            FAILED+=("$demo_name")
            if [[ "$FORCE" != true ]]; then exit 1; fi
        fi
    else
        echo ":: FAILED: $demo_name build failed"
        FAILED+=("$demo_name")
        if [[ "$FORCE" != true ]]; then exit 1; fi
    fi
done

# Generate index.html
INDEX_FILE="$SITE_DIR/index.html"
cat > "$INDEX_FILE" <<'HEADER'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JointJS Demos</title>
</head>
<body>
    <h1>JointJS Demos</h1>
    <ul>
HEADER

for demo in "${BUILT[@]}"; do
    echo "        <li><a href=\"./$demo/\">$demo</a></li>" >> "$INDEX_FILE"
done

cat >> "$INDEX_FILE" <<'FOOTER'
    </ul>
</body>
</html>
FOOTER

echo ""
echo "=== Build summary ==="
echo "Built: ${#BUILT[@]} demos"
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "Failed: ${#FAILED[@]} demos: ${FAILED[*]}"
else
    echo "Failed: 0"
fi
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo "Skipped: ${#SKIPPED[@]} demos: ${SKIPPED[*]}"
else
    echo "Skipped: 0"
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    exit 1
fi
