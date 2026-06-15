#!/usr/bin/env bash
# inventory.sh - bootstrap Phase 1 (Inventory) for a repo.
# Usage: ./inventory.sh <repo-path> > 01-inventory.md
# Output is a draft markdown — you must edit it, not paste it raw.

set -uo pipefail

REPO="${1:-.}"
cd "$REPO" || exit 1

echo "# Inventory"
echo
echo "_Generated $(date -u +"%Y-%m-%d") from \`$(pwd)\`_"
echo

# Languages
echo "## Languages"
echo
if command -v cloc >/dev/null 2>&1; then
  cloc --quiet --md --vcs=git . 2>/dev/null | sed -n '/|/p' | head -30
else
  echo "_cloc not installed. Using file extension counts as fallback._"
  echo
  echo "| Extension | File count |"
  echo "|---|---|"
  find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' \
        -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.venv/*' \
        -not -path '*/target/*' -not -path '*/vendor/*' 2>/dev/null \
    | sed -n 's/.*\.\([a-zA-Z0-9]\+\)$/\1/p' \
    | sort | uniq -c | sort -rn | head -15 \
    | awk '{printf "| .%s | %s |\n", $2, $1}'
fi
echo

# Manifest files found
echo "## Manifest / config files detected"
echo
for f in package.json pnpm-workspace.yaml turbo.json nx.json tsconfig.json \
         pyproject.toml setup.py requirements.txt Pipfile poetry.lock \
         pom.xml build.gradle build.gradle.kts settings.gradle \
         go.mod go.sum \
         Cargo.toml Cargo.lock \
         Gemfile composer.json \
         Dockerfile docker-compose.yml docker-compose.yaml compose.yaml \
         Makefile Justfile Taskfile.yml \
         .github/workflows .gitlab-ci.yml Jenkinsfile \
         serverless.yml sam.yaml wrangler.toml \
         terraform main.tf pulumi.yaml; do
  if [ -e "$f" ]; then
    echo "- \`$f\` exists"
  fi
done
# Also look one level deep for nested workspace manifests
find . -maxdepth 3 -name package.json -not -path '*/node_modules/*' 2>/dev/null | \
  grep -v "^./package.json$" | head -10 | sed 's/^/- /'
echo

# Top-level directories
echo "## Top-level directory map"
echo
echo "_Edit to add a one-line purpose for each entry._"
echo
echo "| Directory | Files | Purpose |"
echo "|---|---|---|"
for d in */; do
  count=$(find "$d" -type f -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
  case "$d" in
    node_modules/|.git/|dist/|build/|.venv/|venv/|target/|vendor/|__pycache__/) ;;
    *) echo "| \`$d\` | $count | _TODO_ |";;
  esac
done
echo

# Entry point candidates
echo "## Entry point candidates"
echo
echo "_Verify each is actually reachable. Remove false positives._"
echo
echo "### Server bootstraps"
grep -rEn --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" --include="*.mjs" --include="*.cjs" \
  "app\.listen|server\.listen|createServer|NestFactory\.create" \
  --exclude-dir=node_modules --exclude-dir=dist . 2>/dev/null | head -10 || true
grep -rEn --include="*.py" "app\s*=\s*(Flask|FastAPI)\(|if\s+__name__\s*==\s*[\"']__main__[\"']" \
  --exclude-dir=.venv --exclude-dir=venv . 2>/dev/null | head -10 || true
grep -rEn --include="*.go" "func main\(\)" . 2>/dev/null | head -10 || true
grep -rEn --include="*.java" --include="*.kt" "@SpringBootApplication|public static void main" . 2>/dev/null | head -10 || true
echo
echo "### CLI declarations"
grep -rEn --include="*.js" --include="*.ts" "commander|yargs|Command\(" --exclude-dir=node_modules . 2>/dev/null | head -5 || true
grep -rEn --include="*.py" "click\.|argparse\.|typer\." --exclude-dir=.venv . 2>/dev/null | head -5 || true
echo
echo "### Lambda / function handlers"
grep -rEn --include="*.js" --include="*.ts" --include="*.py" "exports\.handler|def lambda_handler|def handler" . 2>/dev/null | head -10 || true
echo

# Build/test scripts (Node)
if [ -f package.json ]; then
  echo "## NPM scripts"
  echo
  if command -v jq >/dev/null 2>&1; then
    jq -r '.scripts | to_entries[] | "- `npm run \(.key)` → `\(.value)`"' package.json 2>/dev/null
  else
    # Fallback: extract just the "scripts" object using awk (stop at the closing brace).
    awk '
      /"scripts"[[:space:]]*:[[:space:]]*{/ { in_scripts=1; sub(/.*{/, ""); }
      in_scripts {
        if (match($0, /}/)) { print substr($0, 1, RSTART-1); in_scripts=0; exit }
        print
      }
    ' package.json \
      | sed -n 's/.*"\([a-zA-Z0-9:_-]\+\)"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*,\?.*/- `npm run \1` → `\2`/p' \
      | head -30
  fi
  echo
fi

# Python entry points
if [ -f pyproject.toml ]; then
  echo "## Python project entry points (pyproject.toml)"
  echo
  grep -A 20 -i 'scripts\|entry-points\|console_scripts' pyproject.toml 2>/dev/null | head -30 || true
  echo
fi

# Environment variables consumed
echo "## Environment variables consumed (top references)"
echo
echo "_Sample list. Verify against config schema if one exists._"
echo
{
  grep -rohE --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" --include="*.mjs" --include="*.cjs" \
    "process\.env\.[A-Z_][A-Z0-9_]*" --exclude-dir=node_modules . 2>/dev/null
  grep -rohE --include="*.py" "os\.environ\[['\"][A-Z_][A-Z0-9_]*|os\.getenv\(['\"][A-Z_][A-Z0-9_]*" . 2>/dev/null
  grep -rohE --include="*.go" "os\.Getenv\(\"[A-Z_][A-Z0-9_]*" . 2>/dev/null
} | sed -E 's/.*[\."]([A-Z_][A-Z0-9_]+).*/\1/' | sort -u | head -30 | sed 's/^/- `/' | sed 's/$/`/'
echo

# TODO/FIXME count
echo "## Code health signals"
echo
TODOS=$(grep -rEn --include="*.js" --include="*.ts" --include="*.py" --include="*.java" --include="*.kt" --include="*.go" --include="*.rs" --include="*.rb" \
        "TODO|FIXME|HACK|XXX" \
        --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=target . 2>/dev/null | wc -l | tr -d ' ')
echo "- TODO/FIXME/HACK/XXX comments: $TODOS"
echo "- Tests directory present: $([ -d test ] || [ -d tests ] || [ -d __tests__ ] || [ -d spec ] && echo yes || echo no)"
echo "- CI config present: $([ -d .github/workflows ] || [ -f .gitlab-ci.yml ] || [ -f Jenkinsfile ] || [ -f .circleci/config.yml ] && echo yes || echo no)"
echo
echo "---"
echo "_End of generated draft. Now: edit, prune false positives, fill in TODOs, and verify entry points are real._"
