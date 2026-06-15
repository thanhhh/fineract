# Reference: Sampling Strategy for Large Codebases

For repos over ~500 files or ~100k LOC, you can't read everything. Be deliberate about what you read.

## Read-everything tier

Always read these in full, regardless of repo size:

- Top-level README, CONTRIBUTING, docs/
- All manifest files (`package.json`, `pyproject.toml`, etc.)
- All route/URL/controller registration files
- All config files (`*.config.*`, `config/`, `.env.example`)
- All migration files (or at least the most recent ~20)
- All Dockerfiles, k8s manifests, CI configs, IaC files
- Entry point files (each `main`, server bootstrap, lambda handler)
- Cross-cutting infrastructure (auth middleware, error handler, logger setup)

These are small in total volume and high in interpretive payoff.

## Sample-by-feature tier

For each feature in the catalog:

1. Read the entry point file (already covered above).
2. Follow imports/dependencies one layer deep — the use case / service file the entry calls into.
3. Follow one more layer if needed (domain logic, repository).
4. Read the relevant test file if it exists — tests reveal expected behavior cheaply.

For 15 features × 4 files each, that's 60 files of focused reading. Tractable.

## Skip tier

Skip these unless evidence suggests otherwise:

- `node_modules/`, `vendor/`, `.venv/`, `target/`, `dist/`, `build/` — never read
- Generated code (gRPC stubs, GraphQL codegen output) — read the schema instead
- Lock files (`package-lock.json`, `yarn.lock`, `Cargo.lock`) — for dependency lists, manifest files are enough
- Static assets, fonts, images
- Test fixtures, snapshot files
- Files with `.min.`, `.bundle.`, `.gen.` in the name

## Strategic greps

Greps and structural searches are how you avoid reading everything while still being confident:

```bash
# Count files per top-level dir to see where mass lives
find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | \
  awk -F/ '{print $2}' | sort | uniq -c | sort -rn

# Quick LOC-by-language using cloc
cloc --vcs=git .

# All TODO/FIXME with file:line
rg -n "TODO|FIXME|HACK|XXX" -g '!*.lock' -g '!node_modules'

# All env vars consumed (Node)
rg -n "process\.env\." -g '*.{ts,tsx,js,jsx}' | awk '{print $NF}' | sort -u

# All env vars consumed (Python)
rg -n "os\.environ\[|os\.getenv\(" -g '*.py'

# Outbound HTTP destinations
rg -n "https?://[a-zA-Z0-9.-]+" | grep -v "test\|spec\|example\|localhost" | sort -u

# All SQL queries (raw)
rg -n "SELECT |INSERT |UPDATE |DELETE " --type sql --type py --type js --type ts -i
```

These give you the *shape* of the codebase without reading it linearly.

## When to escalate honesty

If after sampling you have low confidence about a particular feature or NFR, say so in the doc:

> *Note: This section is based on a partial reading of the codebase. The detailed behavior of <X> was not traced end-to-end. Treat as a starting point, not ground truth.*

The reader benefits more from a calibrated doc than a confident-sounding hallucinated one.
