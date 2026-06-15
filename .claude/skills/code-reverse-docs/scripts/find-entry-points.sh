#!/usr/bin/env bash
# find-entry-points.sh - locate route definitions, CLI handlers, workers across common stacks.
# Usage: ./find-entry-points.sh <repo-path>
# Output: human-readable list grouped by category.

set -uo pipefail

REPO="${1:-.}"
cd "$REPO" || exit 1

EXCL="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=.venv --exclude-dir=venv --exclude-dir=target --exclude-dir=vendor"

# grep -rEn does not expand brace lists in --include; pass each extension separately.
JS_INC="--include=*.js --include=*.ts --include=*.mjs --include=*.cjs --include=*.jsx --include=*.tsx"
PY_INC="--include=*.py"
GO_INC="--include=*.go"
JAVA_INC="--include=*.java --include=*.kt"
CS_INC="--include=*.cs"
RB_INC="--include=*.rb"
YML_INC="--include=*.yml --include=*.yaml"

header() { printf "\n=== %s ===\n" "$1"; }

header "HTTP routes — Node/TS (Express/Fastify/Koa)"
grep -rEn $JS_INC $EXCL \
  "(app|router|fastify|server|api)\.(get|post|put|patch|delete|head|options|use|all|route)\s*\(" . 2>/dev/null \
  | head -50

header "HTTP routes — NestJS"
grep -rEn --include="*.ts" $EXCL \
  "@(Controller|Get|Post|Put|Patch|Delete|Head|Options|All)\(" . 2>/dev/null \
  | head -50

header "HTTP routes — Next.js App Router / API routes"
find . -type f \( -name 'route.ts' -o -name 'route.tsx' -o -name 'route.js' \) -not -path '*/node_modules/*' 2>/dev/null | head -30
find . -type f -path '*/pages/api/*' -not -path '*/node_modules/*' 2>/dev/null | head -30

header "HTTP routes — Python (Flask/FastAPI/Django)"
grep -rEn $PY_INC $EXCL \
  "@(app|router|api|bp|blueprint)\.(get|post|put|patch|delete|route)\(" . 2>/dev/null \
  | head -50
find . -name urls.py -not -path '*/.venv/*' 2>/dev/null | head -10

header "HTTP routes — Java/Kotlin (Spring)"
grep -rEn $JAVA_INC $EXCL \
  "@(RequestMapping|GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)" . 2>/dev/null \
  | head -50

header "HTTP routes — Go (chi/gin/echo/mux)"
grep -rEn $GO_INC $EXCL \
  "(r|router|app|e|mux)\.(GET|POST|PUT|PATCH|DELETE|HEAD|Handle|HandleFunc)\(" . 2>/dev/null \
  | head -50

header "HTTP routes — Ruby on Rails"
[ -f config/routes.rb ] && head -50 config/routes.rb

header "HTTP routes — ASP.NET / C#"
grep -rEn $CS_INC $EXCL \
  "\[Http(Get|Post|Put|Patch|Delete)\]|app\.Map(Get|Post|Put|Patch|Delete|Controllers)" . 2>/dev/null \
  | head -50

header "GraphQL resolvers"
grep -rEn $JS_INC $PY_INC $GO_INC $EXCL \
  "@(Query|Mutation|Subscription|Resolver|FieldResolver)|graphqlHTTP|gql\`" . 2>/dev/null | head -30

header "Server bootstraps"
grep -rEn $JS_INC $EXCL \
  "(app|server)\.listen|createServer|NestFactory\.create" . 2>/dev/null | head -20
grep -rEn $PY_INC $EXCL \
  "uvicorn\.run|app\.run\(|runserver" . 2>/dev/null | head -20
grep -rEn $GO_INC $EXCL "func main\(\)" . 2>/dev/null | head -20

header "CLI handlers"
grep -rEn $JS_INC $EXCL \
  "new Command\(|program\.command\(|yargs\.command\(" . 2>/dev/null | head -20
grep -rEn $PY_INC $EXCL \
  "@(app|cli|main)\.(command|group)\(|argparse\.|typer\." . 2>/dev/null | head -20
grep -rEn $GO_INC $EXCL "cobra\.Command{" . 2>/dev/null | head -20

header "Queue consumers / workers"
grep -rEn $JS_INC $EXCL \
  "new Worker\(|\.process\(|@Process\(|consumeFrom|subscribe\(" . 2>/dev/null | head -20
grep -rEn $PY_INC $EXCL \
  "@(shared_task|task|celery\.task)|@app\.task" . 2>/dev/null | head -20
grep -rEn $RB_INC $EXCL "include Sidekiq::Worker|perform_async" . 2>/dev/null | head -20

header "Lambda / Cloud Function handlers"
grep -rEn $JS_INC $EXCL "exports\.handler\s*=" . 2>/dev/null | head -20
grep -rEn $PY_INC $EXCL "def (lambda_handler|handler)\(" . 2>/dev/null | head -20

header "Scheduled jobs / cron"
grep -rEn $YML_INC $EXCL "schedule:|cron:" . 2>/dev/null | head -20
find . -name 'cronjob*.yaml' -o -name 'cronjob*.yml' 2>/dev/null | head -10
grep -rEn $PY_INC $EXCL "@(periodic_task|scheduled)" . 2>/dev/null | head -10

header "Webhook endpoints (heuristic)"
grep -rEn $JS_INC $PY_INC $GO_INC $JAVA_INC $RB_INC $CS_INC $EXCL "webhook" . 2>/dev/null | head -30

echo
echo "=== Done. Review and group these into logical features for the feature catalog. ==="
