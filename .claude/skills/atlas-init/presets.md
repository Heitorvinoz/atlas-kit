# Presets de comandos por stack (referência para /atlas-init)

Ajuste ao que o projeto realmente usa. `{file}` em `format_file` é substituído pelo hook.

| Stack | install | lint | format | format_file | typecheck | test | test_coverage | build | deps_audit |
|---|---|---|---|---|---|---|---|---|---|
| Node (npm) | `npm ci` | `npm run lint` | `npm run format` | `npx prettier --write {file}` | `npx tsc --noEmit` | `npm test -- --run` | `npm test -- --run --coverage` | `npm run build` | `npm audit --audit-level=high` |
| Node (pnpm) | `pnpm i --frozen-lockfile` | `pnpm lint` | `pnpm format` | `pnpm prettier --write {file}` | `pnpm tsc --noEmit` | `pnpm test -- --run` | `pnpm test -- --run --coverage` | `pnpm build` | `pnpm audit --audit-level=high` |
| Node (bun) | `bun install` | `bun run lint` | `bun run format` | `bunx prettier --write {file}` | `bunx tsc --noEmit` | `bun test` | `bun test --coverage` | `bun run build` | `bun audit` (ou `npm audit`) |
| Python (uv) | `uv sync` | `uv run ruff check .` | `uv run ruff format .` | `uv run ruff format {file}` | `uv run mypy .` | `uv run pytest -q` | `uv run pytest -q --cov --cov-report=term-missing` | `uv build` | `uv run pip-audit` |
| Python (pip/poetry) | `pip install -r requirements.txt` / `poetry install` | `ruff check .` | `ruff format .` | `ruff format {file}` | `mypy .` | `pytest -q` | `pytest -q --cov --cov-report=term-missing` | null | `pip-audit` |
| Go | `go mod download` | `golangci-lint run` | `gofmt -w .` | `gofmt -w {file}` | `go vet ./...` | `go test ./...` | `go test ./... -cover` | `go build ./...` | `govulncheck ./...` |
| Rust | `cargo fetch` | `cargo clippy -- -D warnings` | `cargo fmt` | `rustfmt {file}` | `cargo check` | `cargo test` | `cargo llvm-cov` (ou `cargo tarpaulin`) | `cargo build --release` | `cargo audit` |
| Java (Maven) | `mvn -q dependency:resolve` | `mvn -q checkstyle:check` | `mvn -q spotless:apply` | null | `mvn -q compile` | `mvn -q test` | `mvn -q verify` (jacoco) | `mvn -q package` | `mvn org.owasp:dependency-check-maven:check` |
| Ruby (Rails) | `bundle install` | `bundle exec rubocop` | `bundle exec rubocop -A` | `bundle exec rubocop -A {file}` | null | `bundle exec rspec` | `COVERAGE=1 bundle exec rspec` | null | `bundle exec bundler-audit check --update` |
| PHP (Laravel) | `composer install` | `vendor/bin/phpstan analyse` | `vendor/bin/pint` | `vendor/bin/pint {file}` | null | `php artisan test` | `php artisan test --coverage` | null | `composer audit` |
| .NET | `dotnet restore` | `dotnet format --verify-no-changes` | `dotnet format` | null | `dotnet build --no-restore` | `dotnet test` | `dotnet test --collect:"XPlat Code Coverage"` | `dotnet publish -c Release` | `dotnet list package --vulnerable` |

Migrations (campos `migrate` / `migrate_check`):
- Prisma: `npx prisma migrate deploy` / `npx prisma migrate diff --from-migrations ./prisma/migrations --to-schema-datamodel ./prisma/schema.prisma --exit-code`
- Drizzle: `npx drizzle-kit migrate` / `npx drizzle-kit check`
- Alembic: `alembic upgrade head` / `alembic check`
- Django: `python manage.py migrate` / `python manage.py makemigrations --check --dry-run`
- Rails: `bin/rails db:migrate` / `bin/rails db:migrate:status`
- Go (goose): `goose up` / `goose status`
- Laravel: `php artisan migrate` / `php artisan migrate:status`

Segurança agnóstica de stack (campo `security`):
- `secrets`: `gitleaks detect --no-banner --redact`
- `sast`: `semgrep --config auto --error --quiet .`
- e2e (opcional): Playwright `npx playwright test`, Cypress `npx cypress run`

Seeds (campo `seed`): Prisma `npx prisma db seed` · Drizzle `npx tsx src/db/seed.ts` · Django `python manage.py loaddata demo` ou comando próprio ·
Rails `bin/rails db:seed` · Laravel `php artisan db:seed` · Go/Rust: script próprio (`go run ./cmd/seed`).

API spec (campos `api_spec` / `api_spec_check`): FastAPI `python -c "import json,app;print(json.dumps(app.app.openapi()))" > docs/api/openapi.json` ·
NestJS/Express com swagger: comando de export do projeto · Spring `springdoc` em `/v3/api-docs` (curl para arquivo) · validação: `npx @redocly/cli lint docs/api/openapi.yaml`.

Load test (campo `load_test`): `npx autocannon -d 10 -c 20 <url>` ou `k6 run tests/load/smoke.js`.

Deploy (bloco `deploy.commands`): Vercel `vercel --yes` / `vercel --prod --yes` · Netlify `netlify deploy --build` / `--prod` ·
Railway `railway up` (ambientes via `--environment`) · Fly `fly deploy` · Render via `render deploys create` · Docker `docker compose -f compose.prod.yml up -d --build`.
