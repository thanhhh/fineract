# Reference: Inventory (Phase 1)

## What an inventory must answer

Before any interpretation, you need to be able to answer these without re-grepping:

1. What languages? What's the primary one (by LOC)?
2. What frameworks/major libs? (Read the manifest, not the source.)
3. Where does execution start? Every entry point.
4. How is it built? How is it tested? How is it deployed?
5. What's the directory layout, with one-line purposes?

## Manifest files by stack

| Stack | Files to read first |
|---|---|
| Node.js / TS | `package.json`, `tsconfig.json`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json` |
| Python | `pyproject.toml`, `setup.py`, `requirements*.txt`, `Pipfile`, `poetry.lock` |
| Java/Kotlin | `pom.xml`, `build.gradle(.kts)`, `settings.gradle` |
| Go | `go.mod`, `go.sum` |
| Rust | `Cargo.toml`, `Cargo.lock` |
| C# | `*.csproj`, `*.sln`, `Directory.Packages.props` |
| Ruby | `Gemfile`, `gemspec` |
| PHP | `composer.json` |
| Mixed | `Dockerfile`, `docker-compose.yml`, `Makefile`, `Justfile`, `Taskfile.yml` |

## Entry points by stack

**Web services:**
- Express/Koa/Fastify: search for `app.listen`, `server.listen`, `createServer`
- NestJS: `main.ts` → `NestFactory.create`
- Spring Boot: `@SpringBootApplication`
- Django: `manage.py`, `wsgi.py`, `asgi.py`, `urls.py`
- Flask/FastAPI: `app = Flask(...)` / `app = FastAPI(...)`
- Rails: `config/routes.rb`, `config/application.rb`
- Go: `func main()` in `cmd/*/main.go`
- ASP.NET Core: `Program.cs` (top-level statements or `Main`)

**CLI tools:**
- `argparse`/`click`/`typer` (Python), `commander`/`yargs` (Node), `cobra` (Go), `clap` (Rust)
- Look for the file referenced by `bin` in package.json, `scripts` in pyproject, or `[[bin]]` in Cargo.toml

**Background workers:**
- Celery (`@task`), Sidekiq (`include Sidekiq::Worker`), BullMQ workers, Cloud Functions handlers, AWS Lambda handlers (`exports.handler`, `def lambda_handler`)

**Frontend apps:**
- `index.html` and the script it loads, or Next.js `app/` / `pages/`, Remix `app/`, Vite `main.ts`

**Scheduled jobs:**
- Cron expressions in config, GitHub Actions schedules, `schedule:` in serverless.yml, Kubernetes CronJob manifests

## Frameworks tell you a lot

Recognizing the framework gives you a free conventional layout. Don't redocument what the framework dictates:

- Django → `models.py`, `views.py`, `urls.py`, `admin.py`, `migrations/`
- Rails → MVC under `app/`
- Next.js (App Router) → routes are folders under `app/`
- Spring → `@Controller`, `@Service`, `@Repository`, `@Component`

Note the framework in the inventory and the reader will fill in the rest.

## Inventory.md template structure

```markdown
# Inventory

## Languages
| Language | Files | LOC | % |

## Primary stack
- Runtime: ...
- Framework: ...
- Build tool: ...
- Test framework: ...
- Package manager: ...

## Entry points
| Type | Location | Notes |
| HTTP server | `src/server.ts:14` | Express, port from env `PORT` |
| CLI | `bin/cli.js` | Uses commander |
| Worker | `workers/email.ts` | BullMQ consumer of `email-queue` |
| Scheduled | `.github/workflows/nightly.yml` | Runs `npm run cleanup` daily 03:00 UTC |

## Directory map
- `src/api/` — HTTP route handlers
- `src/domain/` — business logic, framework-free
- `src/infra/` — database, queue, external API clients
- ...

## Build, test, deploy
- Build: ...
- Test: ...
- Deploy: ... (cite the file)

## Dependencies of note
List only the ones that shape architecture (ORM, queue lib, auth lib, HTTP client, framework). Skip lodash.
```

## Common mistakes

- Listing every file. The reader wants the *map*, not the *territory*.
- Listing every dependency. Filter to what shapes architecture.
- Skipping the dev/test/CI tooling. Test framework choice tells you a lot about the team's standards.
- Calling something an entry point when it's not reachable. Verify by tracing.
