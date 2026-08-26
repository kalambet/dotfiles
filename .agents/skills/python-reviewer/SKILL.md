---
name: python-reviewer
description: Language-specific PR review for Python code. Use this skill whenever the user is reviewing a Python PR, asking for Python code review, checking Python code for common mistakes, verifying a Python diff against these conventions, looking for mutable default arguments, bare excepts, `Any` misuse, blocking calls in async code, unbounded concurrency, or public-API problems. EVEN IF the user does not explicitly ask for "Python review" — triggers on "review this Python PR", "is this Python correct", "check this Python function", "look for issues in this .py", "review the diff", "what's wrong with this Python", "type review", "async review", "pytest review". Findings emit at SOFT WARNING severity (agent reports; operator decides on merge); agent never blocks. Do NOT use for Python design (use python-architect) or Python implementation guidance (use python-developer).
metadata:
  type: role-workflow
  language: python
  role: reviewer
  severity-tier: SOFT WARNING
  authored-via: web-research (2026-08-09)
---

# Python Reviewer

Reviewer skill for Python PRs. Universal review framework lives in the `pr-review` skill.

## Severity tier

**SOFT WARNING.** Agent flags; operator decides on merge.

Note that a project's own ADRs may make review sign-off a hard gate regardless of this tier. Where
project records and this skill disagree, **the project's records win.**

## Checklist

### Correctness traps

- **Mutable default argument** (`def f(xs: list[str] = [])`) → the default is created once at
  definition and shared across every call. Flag unconditionally.
- **`assert` used for runtime validation** → stripped under `python -O`. The check vanishes in
  production. Flag as correctness, not style.
- **Mutable class attribute** used as per-instance state → shared across instances.
- **`datetime.utcnow()`** → deprecated and returns a naive datetime. `datetime.now(UTC)`.
- **Late-binding closures in loops** (`lambda: i`) → capture with a default arg or `functools.partial`.
- **Identity vs equality** — `is` on strings/ints. Works by accident via interning, then doesn't.
- **Shadowed builtins** (`list`, `id`, `type`, `input`).

### Type discipline

- `Any` in committed code → flag. `object` plus narrowing is usually the answer.
- `# type: ignore` without an error code and a reason → require both.
- `cast()` without a runtime check behind it.
- Legacy syntax (`List`, `Dict`, `Optional`, `Union`) in code targeting 3.12+ → prefer `list`,
  `dict`, `X | None`, `X | Y`.
- Module-level `TypeVar` in new code → PEP 695 `def f[T]` / `class C[T]`.
- Missing return annotations, especially `-> None`, which is what makes mypy check the body.
- Public function signatures that are untyped in a package shipping `py.typed`.

### Error handling

- **Bare `except:`** → catches `KeyboardInterrupt` and `SystemExit`. Always flag.
- `except Exception:` that neither logs nor re-raises → silent failure.
- Wide `try` blocks → only the raising call belongs inside.
- `raise X(...)` inside an `except` without `from err` → traceback chain lost.
- `raise Exception(str(e))` → destroys type and traceback.
- Exceptions caught by message text rather than class.

### Async

- **Blocking calls inside a coroutine** — `time.sleep`, `requests`, sync file I/O, sync DB
  drivers. Stalls the whole loop; invisible until load. Flag hard.
- `asyncio.gather` where `TaskGroup` fits → gather leaks siblings on failure.
- **Unbounded concurrency** over an external service → require `asyncio.Semaphore`.
- Bare `create_task` whose result isn't retained → task can be garbage-collected mid-flight.
- No timeout on network calls → `asyncio.timeout`.
- `asyncio` sync primitives used across threads.
- `async def` that never awaits → should be sync.

### Resource handling

- File/socket/connection opened without a context manager.
- `subprocess` with `shell=True` on any interpolated input → injection.
- Unclosed sessions or pools in long-lived processes.

### Security

- `eval`, `exec`, `pickle.loads`, or `yaml.load` on untrusted input.
- Secrets in source, defaults, or log lines.
- SQL built by string interpolation → parameterize.
- `tempfile.mktemp`, predictable temp paths.
- `verify=False` on TLS.

### Tests

- New behaviour without a test.
- Tests asserting on implementation details rather than behaviour.
- Session-scoped mutable fixtures → order-dependent failures under `pytest-xdist`.
- Missing `parametrize` where the same body is copy-pasted per input.
- Parsers or encoders without property tests (`hypothesis`).
- `--strict-markers` absent, so typo'd markers select nothing silently.

### Packaging and config

- Imports that only work under a flat layout.
- Dependency added without justification; runtime vs dev misplaced.
- Unpinned or floating versions in an application; `uv.lock` not updated with the change.
- Library missing `py.typed` while advertising types.
- Tool config outside `pyproject.toml`.

### Public API

- New public names absent from `__all__`, or internals exported without a `_` prefix.
- Positional parameters added where keyword-only was intended.
- Exception class renamed or re-parented → breaking change; needs a CHANGELOG entry.

## Refusal

The reviewer skill refuses to review and escalates if:

- Non-Python code in diff.
- Empty PR description.
- Out-of-session-scope code.
- **No type checker configured in `pyproject.toml`** — refuse and escalate. Type hints that nothing
  verifies are documentation that silently rots, and reviewing types by eye does not scale.

## Phrasing

- Lead with the concern: "This coroutine calls `requests.get`, which blocks the event loop for the
  duration — every other task stalls behind it. Was `httpx.AsyncClient` intended?"
- Cite the rule, and say what breaks rather than only what is non-idiomatic.
- `nit:` for taste.

## Related

- Universal review: `pr-review`
- Sister roles: `python-architect`, `python-developer`
