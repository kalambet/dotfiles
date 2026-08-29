---
name: python-architect
description: Architectural guidance for designing Python projects and packages. Use this skill whenever the user is starting a new Python project, designing a package or module boundary, choosing a layout (src vs flat), picking a dependency manager or build backend, setting the typing baseline, designing an exception hierarchy, choosing sync vs async, deciding on Protocol vs ABC, or writing an ADR for Python work. EVEN IF the user does not explicitly say "architecture" — triggers on "design a Python package", "new Python project", "src layout", "uv or poetry", "pyproject.toml setup", "Protocol or ABC", "async or sync", "exception hierarchy", "dependency injection in Python", "ADR for Python", "typed package", "py.typed". Do NOT use for line-level Python coding (use python-developer) or Python PR review (use python-reviewer).
metadata:
  type: role-workflow
  language: python
  role: architect
  authored-via: web-research (2026-08-09)
---

# Python Architect

Designing Python systems — packages, libraries, services, and the boundaries between them.

Python gives you almost no structural enforcement, so architecture here is mostly about
**choosing constraints and making tooling enforce them.** An untyped, unlayered Python codebase
does not fail at compile time; it fails in production, later, in someone else's module.

## Key Python-specific decisions

### Project layout

- **`src/` layout**, not flat. `src/mypkg/`, `tests/` alongside. This is the single highest-value
  layout decision: a flat layout lets tests import the local source directory instead of the
  installed package, so packaging bugs stay invisible until a user hits them.
- **`pyproject.toml` is the single source of truth** — project metadata (PEP 621), dependencies,
  and every tool's configuration. No `setup.py`, no `setup.cfg`, no scattered `.ini` files.
- **Build backend:** `hatchling` for new work (auto-detects `src/`); `setuptools` where entrenched.
- **One package per repo** unless there is a real reason to share a release cadence.

### Dependency and environment management

- **`uv`** for environments, resolution, locking, and running. Commit `uv.lock`; use `--frozen` in
  CI. Applications pin; libraries declare ranges and do **not** commit a lock as the contract.
- Never depend on an activated virtualenv — `uv run <cmd>` makes the environment explicit and
  reproducible, which matters most in CI and in someone else's checkout.
- **Set `requires-python` deliberately.** It is a public API decision for a library and a
  deployment constraint for an application, and it gates which typing syntax you may use.

### Typing baseline

- **Floor is Python 3.12** for new work, which buys PEP 695 syntax. Current stable is 3.14.
- **A type checker runs in CI or the types are decoration.** `mypy --strict` is the default —
  broadest ecosystem and plugin support. `pyright` is stricter and faster in editors. `ty`
  (Astral) is far faster but still beta as of 2026 — viable, not yet the safe default for a
  codebase others depend on.
- **Decide the strictness floor once, in `pyproject.toml`, and ratchet.** Per-module opt-outs with
  a reason beat a permanently lax global setting.
- **Libraries ship `py.typed`** (PEP 561), or downstream users get no types at all from you.

### Interfaces: Protocol over ABC

- **`typing.Protocol` (PEP 544) for structural interfaces** — the implementer needs no import of
  yours and no inheritance, which keeps coupling out of the dependency graph. This is the default.
- **ABC when you need shared implementation** or a runtime `isinstance` gate, and are willing to
  pay for the inheritance edge.
- Define the Protocol **next to the consumer**, not the implementer. That is what makes the
  dependency point inward.

### Layering

- **Business logic stays pure**: it takes and returns plain data (dataclasses, Pydantic models),
  and imports no framework. Web framework, ORM, and network clients live at the edges.
- **Validate at the boundary, trust inward.** Parse untrusted input into typed models once, at the
  edge; internal code then handles known-good types instead of re-checking defensively.
- **Dependency injection by constructor parameter.** A DI container is rarely warranted; passing
  collaborators in is enough and keeps tests from needing monkeypatching.

### Exception hierarchy

- **One base exception per package** (`class MyPkgError(Exception)`), everything else inherits it.
  Callers can then catch your whole surface without catching the world.
- Distinguish **recoverable** from **programming error** by class, never by message text.
- **The exception hierarchy is public API.** Renaming or re-parenting one is a breaking change.

### Sync vs async

- **Choose once, per boundary.** Mixed-color codebases leak: a blocking call inside an event loop
  stalls everything, and it is invisible until load.
- Async earns its place with **I/O concurrency**, not CPU work. For CPU-bound work use processes —
  or free-threaded 3.14 builds, with the caveat that the ecosystem is still catching up.
- **Library authors:** consider `anyio` so you are not binding consumers to `asyncio`.
- Offload unavoidable blocking calls with `asyncio.to_thread`.

### Public API

- **`__all__` in every public module** — it is the difference between a deliberate surface and
  whatever happened to be importable.
- Prefix internals with `_`. A leading underscore is the only privacy signal Python has; use it.
- Keyword-only arguments (`*`) for anything that could grow — positional parameters are a
  compatibility promise you probably did not intend to make.

## ADR template for Python work

- **Public surface** — what is exported, what `py.typed` promises, what the exception hierarchy is.
- **Typing baseline** — checker, strictness, `requires-python`, and which modules are exempt and why.
- **Sync/async decision** and where the boundary sits.
- **Data boundaries** — what is validated where, and what internal code may assume.
- **Dependency policy** — what is allowed in, and the runtime/dev split.
- **Invariants impacted** — link the project's own records; ours win over general guidance.

## Anti-patterns at design time

- Flat layout for a package that will be published.
- Types present but no checker in CI.
- Business logic importing the web framework or the ORM.
- A `utils` or `helpers` module — it is a naming failure that becomes a dependency magnet.
- Inheritance where composition or a Protocol would do.
- Module-level mutable state and import-time side effects (they make import order load-bearing).
- Reaching for async because it sounds faster, with no I/O concurrency to exploit.

## Related

- Sister roles: `python-developer`, `python-reviewer`
- Upstream: [Python Packaging User Guide](https://packaging.python.org/) · [typing spec](https://typing.python.org/) · [uv](https://docs.astral.sh/uv/)
