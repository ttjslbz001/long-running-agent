# Adapter Examples

The adapter is the ONLY file you customize per project. Everything else in the scaffold is generic.

---

## Example 1: Nx Monorepo with CDK (Seguro-style)

```markdown
# Domain Adapter: Seguro Insurance Platform

## Build
- Tool: Nx 20.4.1 + Yarn
- Compile: `nx run <project>:tsc`
- Lint: `nx run <project>:lint`

## Test
- Unit: `nx run <project>:test`
- Regression: `nx run <project>:regression-test` (check project.json for target)
- Test location: `__test__/`, `__regression__/`

## Deploy
- Prerequisites: `saml2aws login --force && aws sts get-caller-identity`
- Command: `nx run <project>:deploy --stage=<env>`
- Two-stack pattern: Lambda stack + API Gateway stack must both be deployed
  - `nx run <lambda-project>:deploy --stage=<env>`
  - `nx run <gateway-project>:deploy --stage=<env>`
- Environments: dev, stage, uat, preprod (NEVER prod)

## Verify
- Method 1: Direct Lambda invoke (bypass gateway)
  - Get function name from CloudFormation stack outputs
  - `aws lambda invoke --function-name <arn> --payload '<event>' /tmp/out.json`
- Method 2: HTTP API call with Cognito Bearer token
  - OTP debug login: POST /account/v1/auth/send-otp with x-debug header
  - Then POST /account/v1/auth/login with OTP
  - Use access_token as Bearer header
- Method 3: CloudWatch log markers
  - Log group: /aws/lambda/<function-name>
  - Success markers: "Idempotency key claimed", "Idempotency key marked as success"
  - Failure markers: "Error occured", "error_code"
  - Flow markers: "Starting event handling" → "Executing business logic" → "success"

## Authenticate
- Mobile API: Cognito Bearer token via OTP debug login
- Internal APIs: x-api-key header
- Credentials expire in 1 hour → `saml2aws login --force`

## Conventions
- Folders: kebab-case
- Files: camelCase
- Stack names: service-<domain>-<name>
- Commit messages: NDAI-<number>: <description>
- CDK pattern: AppStack in apps/service/<svc>/src/stacks/app-stack.ts

## Known Gotchas
- @swc/jest breaks AWS SDK v3 → use raw axios for Cognito auth in regression tests
- Deploy only Lambda stack → HTTP returns 403 (gateway stack needs redeploying)
- Stage/UAT/preprod share same AWS account (Novo-STG-UAT), different regions
- `USER_PASSWORD_AUTH` not enabled on all Cognito clients → use OTP login instead
```

---

## Example 2: Next.js on Vercel

```markdown
# Domain Adapter: MyApp (Next.js)

## Build
- Tool: pnpm
- Compile: `pnpm build`
- Lint: `pnpm lint`

## Test
- Unit: `pnpm test`
- E2E: `pnpm e2e` (Playwright)
- Test location: `__tests__/`, `e2e/`

## Deploy
- Command: `vercel --prod`
- Preview: automatic on every PR (Vercel integration)
- Environments: preview (per-PR), production

## Verify
- Health check: `curl -s <deployment-url>/api/health`
- E2E: `PLAYWRIGHT_BASE_URL=<deployment-url> pnpm e2e`
- Success: HTTP 200, JSON response with `{ "status": "ok" }`

## Authenticate
- Dev: no auth needed
- Production: NextAuth.js with GitHub OAuth

## Conventions
- Components: PascalCase in `src/components/`
- Utilities: camelCase in `src/lib/`
- API routes: `src/app/api/<resource>/route.ts`
- Commit messages: Conventional Commits (feat:, fix:, chore:)

## Known Gotchas
- `next build` fails silently on TypeScript errors if `ignoreBuildErrors: true` is set
- Vercel preview URLs change per commit — use `VERCEL_URL` env var
```

---

## Example 3: Python FastAPI with Docker

```markdown
# Domain Adapter: DataPipeline API

## Build
- Tool: uv (Python package manager)
- Install: `uv sync`
- Lint: `uv run ruff check .`
- Type check: `uv run mypy src/`

## Test
- Unit: `uv run pytest tests/unit/`
- Integration: `uv run pytest tests/integration/` (requires running DB)
- Test location: `tests/unit/`, `tests/integration/`

## Deploy
- Prerequisites: `docker build -t datapipeline . && docker push <registry>/datapipeline`
- Command: `kubectl apply -f k8s/`
- Environments: dev (local Docker), staging (k8s), production (k8s)

## Verify
- Health: `curl http://localhost:8000/health`
- Smoke: `curl http://localhost:8000/api/v1/status`
- Logs: `kubectl logs -l app=datapipeline --tail=50`
- Success markers: "Application startup complete", "request completed"
- Failure markers: "Traceback", "Internal Server Error"

## Authenticate
- API key in `X-API-Key` header
- Dev key in `.env` file (not committed)

## Conventions
- Modules: snake_case
- Classes: PascalCase
- Commit messages: Conventional Commits
- Branch naming: feature/<ticket>-<description>

## Known Gotchas
- uv.lock must be committed (reproducible builds)
- Integration tests need `docker compose up db` running first
- FastAPI reload mode breaks with certain import patterns
```

---

## What the Initializer Does

The initializer agent SCANS the project and generates an adapter like the above automatically. It reads package.json, project.json, Dockerfile, CI config, test config, git history, and source files to infer every section.

Sections it cannot determine are marked `[NOT DETECTED — fill manually]`.
