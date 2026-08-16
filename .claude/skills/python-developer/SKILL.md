---
name: python-developer
description: Idiomatic Python development — implementation-level guidance for writing Python. Use this skill whenever the user is writing Python, asking how to do something in Python, debugging Python, picking between Python patterns, writing type hints, handling exceptions, writing async code with asyncio, setting up uv/ruff/mypy, writing pytest tests, or packaging a Python project. EVEN IF the user does not explicitly say "Python" but the file is .py. Triggers on "write a Python function", "implement in Python", "fix this Python", "how do I X in Python", "type hints", "PEP 695 generics", "dataclass or pydantic", "asyncio TaskGroup", "async with", "pytest fixture", "parametrize", "hypothesis", "mutable default argument", "bare except", "uv add", "ruff", "mypy strict", "pyproject.toml". Do NOT use for Python architectural design (use python-architect) or Python PR review (use python-reviewer).
metadata:
  type: role-workflow
  language: python
  role: developer
  authored-via: web-research (2026-08-09)
---

# Python Developer

Idiomatic Python, implementation level. Floor is 3.12; current stable is 3.14.

## Tooling baselines

- **Environment and deps:** `uv`. `uv add`, `uv run <cmd>`, `uv sync --frozen` in CI. Commit
  `uv.lock` for applications. Never rely on an activated venv.
- **Lint and format:** `ruff check --fix` and `ruff format`. Ruff subsumes flake8, isort, pyupgrade,
  autoflake and bandit — one tool, one config block.
- **Types:** `mypy --strict` (default) or `pyright`. `ty` is much faster but still beta.
- **Tests:** `pytest`, plus `pytest-cov`, `pytest-xdist`, and `hypothesis` for anything
  parser-shaped or algorithmic.
- **Security:** `pip-audit` for dependency CVEs; ruff's `S` (bandit) rules for code patterns.

## pyproject.toml baseline

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "mypkg"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[tool.ruff]
line-length = 100
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "C4", "SIM", "ASYNC", "S", "RUF"]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]          # assert is the point in tests

[tool.mypy]
strict = true
warn_unreachable = true
enable_error_code = ["redundant-expr", "truthy-bool", "ignore-without-code"]

[tool.pytest.ini_options]
addopts = "--strict-markers --strict-config"
testpaths = ["tests"]
```

Tighten per project; `strict = true` is the floor.

## Type discipline

- **Modern syntax only.** `list[str]`, `dict[str, int]`, `X | Y`, `X | None` — not `List`,
  `Union`, `Optional`.
- **PEP 695 generics** (3.12+): `def first[T](xs: list[T]) -> T | None:` and `class Box[T]:`.
  Type parameters scope to their declaration; variance is inferred. No module-level `TypeVar`.
- **`type` statement for aliases:** `type UserId = str`.
- **No bare `Any`.** Use `object` when you truly accept anything, and narrow. `Any` silently
  disables checking through every expression it touches.
- **`# type: ignore[code]`** — always with the specific code and a reason.
- **`typing.Protocol`** for structural interfaces; **`Self`** for fluent returns;
  **`@override`** (3.12+) so a renamed base method fails loudly.
- **`Final`** for constants, **`Literal`** for closed string/int sets, **`TypedDict`** for
  structured dicts crossing a boundary.

## Data modelling

- **`@dataclass(frozen=True, slots=True)`** for internal value objects — immutable by default,
  cheaper, and typo-proof on attribute assignment.
- **Pydantic at boundaries** — untrusted input (HTTP bodies, config, files) gets parsed into a
  model once, at the edge. Inside the boundary, work with validated types.
- **`enum.Enum` / `StrEnum`** for closed sets, not bare strings.

## Error handling

```python
class MyPkgError(Exception):
    """Base for everything this package raises."""

class FetchError(MyPkgError):
    def __init__(self, url: str, status: int) -> None:
        super().__init__(f"fetch {url} failed: {status}")
        self.url = url
        self.status = status
```

- **Never `except:` and never bare `except Exception:` without re-raising or logging.**
  Catch the narrowest type that you can actually handle.
- **Keep `try` blocks minimal** — only the call that can raise. A wide `try` catches exceptions
  from places you did not intend and masks real bugs.
- **`raise NewError(...) from err`** to preserve the cause. `from None` only when the original is
  genuinely noise.
- **Never `assert` for runtime validation** — `python -O` strips assertions, and your check
  disappears in exactly the deployment you cared about. Assert for internal invariants only.
- **`finally` / context managers** for cleanup, never manual close on the happy path.

## Async

- **`asyncio.TaskGroup` over `gather`** (3.11+). It is structured concurrency: a failure cancels
  siblings and the group cannot exit with tasks still running.

```python
async with asyncio.TaskGroup() as tg:
    for url in urls:
        tg.create_task(fetch(url))
```

- **Bound the fan-out.** `asyncio.Semaphore` around any external call — unbounded concurrency is
  how you DoS a dependency and exhaust memory at the same time.
- **`async with asyncio.timeout(n)`** for deadlines (3.11+).
- **Never block the loop.** No `time.sleep`, no `requests`, no sync file I/O in a coroutine —
  `await asyncio.to_thread(...)` for unavoidable blocking calls.
- **Keep a reference to bare `create_task` results** or they can be garbage-collected mid-flight.
  TaskGroup handles this for you, which is another reason to prefer it.
- `asyncio` primitives are not thread-safe: use `threading` ones across threads, and
  `run_coroutine_threadsafe` to hand work to a loop.

## Testing

- **`tests/` beside `src/`.** Test the installed package, not the source tree.
- **`@pytest.mark.parametrize`** is the biggest coverage-per-line lever; each case reports
  separately.
- **Fixtures in `conftest.py`**, function scope unless the resource is genuinely read-only.
  Session-scoped mutable fixtures create order-dependent tests that fail only under `-p xdist`.
- **`hypothesis` for parsers, encoders, and anything with a wide input space** — it finds the
  boundary cases nobody enumerates by hand.
- Test behaviour through the public API; a test that breaks on every refactor is testing the
  implementation.
- **`--strict-markers`** so a typo'd marker fails instead of silently selecting nothing.

## CI baseline

- `uv sync --frozen`
- `uv run ruff check .`
- `uv run ruff format --check .`
- `uv run mypy src`
- `uv run pytest --cov=src --cov-report=term-missing`
- `uv run pip-audit`

## Anti-patterns

- **Mutable default arguments** (`def f(xs=[])`) — the default is created once and shared across
  calls. Use `None` and build inside.
- **Bare `except:`** — swallows `KeyboardInterrupt` and `SystemExit` too.
- `from module import *`.
- `assert` doing runtime validation.
- `datetime.utcnow()` — deprecated and naive. Use `datetime.now(UTC)`.
- Mutable class attributes used as instance state (shared across all instances).
- Shadowing builtins (`list`, `id`, `type`, `input`).
- String-typed domain values where an enum or `NewType` belongs.
- Import-time side effects — make import order load-bearing and testing miserable.
- Catching an exception only to `raise Exception(str(e))`, destroying the traceback.

## Related

- Sister roles: `python-architect`, `python-reviewer`
- Upstream: [Python docs](https://docs.python.org/3/) · [typing spec](https://typing.python.org/) · [ruff rules](https://docs.astral.sh/ruff/rules/)
