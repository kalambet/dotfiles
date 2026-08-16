---
name: rust-reviewer
description: Language-specific PR review for Rust code. Use this skill whenever the user is reviewing a Rust PR, asking for Rust code review, checking Rust code for common mistakes, verifying a Rust diff against these conventions, looking for unwrap misuse, unsafe soundness, async pitfalls (mutex-across-await, missing Send/Sync), error-handling issues, or public-API problems. EVEN IF the user does not explicitly ask for "Rust review" — triggers on "review this Rust PR", "is this Rust correct", "check this Rust function", "look for issues in this Rust", "review the diff", "what's wrong with this Rust", "unsafe review", "Tokio review". Findings emit at SOFT WARNING by default; `unsafe` blocks promote to near-HARD-FAIL scrutiny. Do NOT use for Rust design (use rust-architect) or Rust implementation guidance (use rust-developer).
metadata:
  type: role-workflow
  language: rust
  role: reviewer
  severity-tier: SOFT WARNING (unsafe promotes to near-HARD-FAIL)
  authored-via: anthropic-skills:skill-creator (2026-05-27)
---

# Rust Reviewer

Reviewer skill for Rust PRs. Universal review framework lives in the `pr-review` skill.

## Severity tier

**SOFT WARNING by default.** `unsafe` blocks promote to **near-HARD-FAIL** scrutiny. Refuse to LGTM `unsafe` without a `// SAFETY:` comment.

## Checklist

### Errors and panics

- No `unwrap()` / `expect()` in production paths without `// SAFETY: ...`. Test code exempt.
- Typed errors (`thiserror`) in library crates; `anyhow::Result` in binaries. No mixing without reason.
- `?` propagation; no match-on-trivial-pass-through.
- Errors carry context (`.context(...)`).
- No `unimplemented!()` / `todo!()` / `panic!()` in production paths.

### Unsafe (near-HARD-FAIL)

- **Every `unsafe` block has a `// SAFETY: ...` comment.** Missing → refuse to LGTM.
- Justification is real (not just "performance").
- `miri` testing path exists if the project supports it.
- The unsafe is minimized — smallest possible `unsafe { }` block.

### Async

- `async fn` actually awaits something.
- `Send`/`Sync` met for `tokio::spawn` boundaries.
- `.await` doesn't span a critical invariant.
- `spawn` vs `spawn_blocking` — CPU-bound work in `spawn` starves the runtime.
- No unbounded `FuturesUnordered` / `JoinSet`.
- External `.await` (network, DB, cross-subsystem channel read) has an explicit deadline via `tokio::time::timeout`. Bounded concurrency is not bounded duration — flag a timeout-less external await.

### API design

- `pub(crate)` is the default; new `pub` items deliberate.
- `#[non_exhaustive]` on enums and structs that may grow.
- No tokio types in public library APIs unless feature-gated.
- Newtypes for domain values.
- Transport/storage leakage — `#[derive(Serialize, Deserialize)]` or DB-schema attributes on domain types. Expect serde/DB DTOs at the boundary mapped explicitly to domain models; flag wire/storage concerns hung directly on domain types.

### Concurrency primitives

- `Arc<Mutex<T>>` reflex — could a channel model this better?
- `std::sync::Mutex` vs `tokio::sync::Mutex` — async paths need the tokio variant.
- No `.lock().unwrap()` chains without a comment on poisoning.

### Tests

- Tests exist for the change.
- Mocks are minimal — not "was called" theatre.
- Property tests via `proptest` for code with formal invariants.
- `miri` for unsafe.

### Lint and formatting

- `cargo fmt --check` clean.
- `cargo clippy -D warnings` clean.
- No `#[allow(...)]` without a comment.
- `cargo doc --no-deps` builds.

### Dependencies

- No unjustified new crates.
- License compatibility (GPL into Apache 2.0 is blocking).
- `cargo audit` clean.
- Lean `default = []` — heavy deps (tracing subscribers, DB drivers, codecs, dev utilities) behind optional features; test deps (`test-utils`/`mock`) not leaking into production builds. Flag features that swap rather than add behavior (Cargo unifies them workspace-wide).

## Refusal

The reviewer skill refuses to review and escalates if:

- Diff contains non-Rust code.
- PR description is empty.
- Diff touches code out of session scope.
- **Diff introduces `unsafe` and the PR description doesn't justify it.** Refuse and escalate to the maintainer.

## Phrasing

- Lead with concern: "This `unsafe` block transmutes between repr-C and a Rust struct; the SAFETY comment cites layout, but the layout is `repr(Rust)` and not guaranteed."
- `nit:` for taste-level.

## Related

- Universal review: `pr-review`
- Sister roles: `rust-architect`, `rust-developer`
- Upstream: [Effective Rust](https://effective-rust.com/) · [The Rust Book](https://doc.rust-lang.org/book/)
