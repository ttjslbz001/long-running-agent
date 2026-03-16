# Post-Deploy Verification Protocol

Run this protocol after ANY deployment or infrastructure change. The goal is to confirm the agent's changes actually work in the target environment — not just in code.

## When to Run

- After `deploy` command from adapter.md
- After infrastructure changes (new stack, new route, new permission)
- After environment changes (new env var, new secret, new config)
- NOT needed for pure code changes that only touch tests or docs

## Step 1: Read the Adapter

Read the "Verify" section of `domain/adapter.md`. It tells you:
- What verification methods are available
- What health check commands to run
- What success markers to look for
- What failure markers to look for

If the adapter has no "Verify" section, run a basic smoke test:
1. Is the service reachable? (curl health endpoint or invoke function)
2. Does it return a non-error response?

## Step 2: Run Verification

Execute each verification method from the adapter in order. Common patterns:

**API service:**
```bash
curl -s -o /dev/null -w "%{http_code}" <health-endpoint>
```

**Lambda function:**
```bash
aws lambda invoke --function-name <name> --payload '<test-payload>' /tmp/out.json
cat /tmp/out.json
```

**Web application:**
- Navigate to the URL
- Verify the page loads
- Check browser console for errors

**CLI tool:**
```bash
<tool> --version
<tool> <smoke-test-command>
```

Record each result: PASS or FAIL with details.

## Step 3: Check Logs (if applicable)

If the adapter specifies log locations:
1. Fetch recent logs
2. Grep for success markers → confirm they appear
3. Grep for failure markers → confirm they do NOT appear
4. Check for unexpected errors (ERROR, WARN, Exception, Traceback)

Record: log group, stream/file, key findings.

## Step 4: Performance Baseline (optional but recommended)

If previous baselines exist in state.json:
- Compare response time, cold start, memory usage
- Flag regressions: >20% worse than previous baseline

If no baseline exists, record current values as the first baseline.

## Step 5: Record Results

Update `state.json`:

```json
{
  "last_session": {
    "verification": {
      "method": "<what was run>",
      "local_tests": "pass|fail",
      "deployed": "pass|fail|n/a",
      "logs_checked": true,
      "success_markers_found": ["<list>"],
      "errors_found": ["<list or empty>"],
      "performance": {
        "response_time_ms": <n>,
        "notes": "<any regression>"
      }
    }
  }
}
```

## Step 6: Gate Decision

| Result | Action |
|---|---|
| All checks pass | Proceed to reflection, then next task |
| Verification fails | STOP. Fix the issue. Re-deploy. Re-verify. |
| Logs show unexpected errors | Investigate. Fix if related to your change. Log if pre-existing. |
| Performance regression | Log it. Fix if >50% regression. Note if 20-50%. |

## Rules

- NEVER skip verification after a deploy
- NEVER mark a deploy task as complete without verification evidence
- If the adapter says "deploy both stacks", verify AFTER both are deployed
- Capture evidence (response bodies, log snippets) in notes.md
- If verification requires authentication, follow the adapter's "Authenticate" section
