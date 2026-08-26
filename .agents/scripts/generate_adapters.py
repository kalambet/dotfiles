#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["PyYAML==6.0.3"]
# ///

from __future__ import annotations

import argparse
import os
import re
import tempfile
from pathlib import Path

import yaml

MARKER = "<!-- Generated from ~/.agents; edit the canonical source instead. -->"
FRONTMATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n(.*)\Z", re.DOTALL)
SKILL_NAME = re.compile(r"\A[a-z0-9]+(?:-[a-z0-9]+)*\Z")


class ConfigError(RuntimeError):
    """Raised when adapter configuration or source metadata is invalid."""


def require_mapping(value: object, context: str) -> dict[str, object]:
    if not isinstance(value, dict) or not all(isinstance(key, str) for key in value):
        raise ConfigError(f"expected a string-keyed mapping for {context}")
    return value


def require_string(value: object, context: str) -> str:
    if not isinstance(value, str) or not value:
        raise ConfigError(f"expected a non-empty string for {context}")
    return value


def require_bool(value: object, context: str) -> bool:
    if not isinstance(value, bool):
        raise ConfigError(f"expected a boolean for {context}")
    return value


def require_strings(value: object, context: str) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ConfigError(f"expected a string list for {context}")
    return value


def nested(config: dict[str, object], *keys: str) -> object:
    current = config
    for key in keys[:-1]:
        current = require_mapping(current.get(key), ".".join(keys[:-1]))
    value = current.get(keys[-1])
    if value is None:
        raise ConfigError(f"missing configuration: {'.'.join(keys)}")
    return value


def expand(path: object, context: str) -> Path:
    return Path(require_string(path, context)).expanduser()


def load_yaml_mapping(path: Path) -> dict[str, object]:
    try:
        value: object = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as error:
        raise ConfigError(f"cannot load YAML from {path}: {error}") from error
    return require_mapping(value, str(path))


def load_markdown(path: Path) -> tuple[dict[str, object], str]:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise ConfigError(f"cannot read {path}: {error}") from error
    match = FRONTMATTER.match(text)
    if match is None:
        raise ConfigError(f"invalid frontmatter: {path}")
    try:
        metadata: object = yaml.safe_load(match.group(1))
    except yaml.YAMLError as error:
        raise ConfigError(f"invalid YAML frontmatter in {path}: {error}") from error
    return require_mapping(metadata, str(path)), match.group(2).strip()


def frontmatter(data: dict[str, object]) -> str:
    return yaml.safe_dump(
        data,
        allow_unicode=True,
        default_flow_style=False,
        sort_keys=False,
        width=10_000,
    )


def managed_write(path: Path, content: str, *, apply: bool) -> bool:
    if path.exists():
        current = path.read_text(encoding="utf-8")
        if MARKER not in current:
            raise ConfigError(f"refusing to overwrite unmanaged file: {path}")
        if current == content:
            return False
    if not apply:
        return True

    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)
    return True


def model(config: dict[str, object], harness: str, model_class: str) -> str:
    return require_string(
        nested(config, "models", harness, model_class),
        f"models.{harness}.{model_class}",
    )


def generate_agents(config: dict[str, object], *, apply: bool) -> list[Path]:
    prompts_dir = expand(nested(config, "canonical", "prompts"), "canonical.prompts")
    changed: list[Path] = []
    for source in sorted(prompts_dir.glob("*.md")):
        metadata, body = load_markdown(source)
        name = require_string(metadata.get("name"), f"{source}: name")
        description = require_string(
            metadata.get("description"), f"{source}: description"
        )
        model_class = require_string(
            metadata.get("model_class"), f"{source}: model_class"
        )
        read_only = require_bool(metadata.get("read_only"), f"{source}: read_only")
        skills = require_strings(metadata.get("skills", []), f"{source}: skills")

        claude_tools = {
            "architect": "Read, Grep, Glob, Write, Edit, WebSearch, WebFetch, Skill",
            "developer": "Read, Write, Edit, Bash, Glob, Grep, Skill",
            "researcher": "Read, Glob, Grep, WebSearch, WebFetch",
        }.get(model_class, "Read, Glob, Grep, Bash, Skill")
        claude: dict[str, object] = {
            "name": name,
            "description": description,
            "tools": claude_tools,
            "model": model(config, "claude", model_class),
        }
        if skills:
            claude["skills"] = skills
        content = f"---\n{frontmatter(claude)}---\n{MARKER}\n\n{body}\n"
        path = (
            expand(
                nested(config, "agent_directories", "claude"),
                "agent_directories.claude",
            )
            / f"{name}.md"
        )
        if managed_write(path, content, apply=apply):
            changed.append(path)

        junie: dict[str, object] = {
            "name": name,
            "description": description,
            "model": model(config, "junie", model_class),
            "skills": skills,
            "tools": ["read", "search", "web"]
            if read_only
            else ["read", "write", "shell", "search", "web"],
        }
        content = f"---\n{frontmatter(junie)}---\n{MARKER}\n\n{body}\n"
        path = (
            expand(
                nested(config, "agent_directories", "junie"), "agent_directories.junie"
            )
            / f"{name}.md"
        )
        if managed_write(path, content, apply=apply):
            changed.append(path)

        permissions: dict[str, object] = {"edit": "deny" if read_only else "allow"}
        if name in {"oracle", "librarian"}:
            permissions["shell"] = "deny"
        opencode: dict[str, object] = {
            "description": description,
            "mode": "subagent",
            "model": model(config, "opencode", model_class),
            "permissions": permissions,
        }
        content = f"---\n{frontmatter(opencode)}---\n{MARKER}\n\n{body}\n"
        path = (
            expand(
                nested(config, "agent_directories", "opencode"),
                "agent_directories.opencode",
            )
            / f"{name}.md"
        )
        if managed_write(path, content, apply=apply):
            changed.append(path)
    return changed


def generate_commands(config: dict[str, object], *, apply: bool) -> list[Path]:
    commands_dir = expand(nested(config, "canonical", "commands"), "canonical.commands")
    changed: list[Path] = []
    for source in sorted(commands_dir.glob("*.md")):
        name = source.stem
        body = source.read_text(encoding="utf-8").strip()
        description = (
            f"Run the {name} phase of the approved "
            "Research → Plan → Annotate → Implement workflow"
        )
        contents = {
            "claude": f"---\ndescription: {description}\n---\n{MARKER}\n\n{body}\n",
            "codex": f"{MARKER}\n\n{body}\n",
            "junie": (
                f"---\ndescription: {description}\nallowPromptArgument: true\n---\n"
                f"{MARKER}\n\n{body.replace('$ARGUMENTS', '$prompt')}\n"
            ),
            "opencode": f"---\ndescription: {description}\n---\n{MARKER}\n\n{body}\n",
        }
        for harness, content in contents.items():
            target = (
                expand(
                    nested(config, "command_directories", harness),
                    f"command_directories.{harness}",
                )
                / f"{name}.md"
            )
            if managed_write(target, content, apply=apply):
                changed.append(target)
    return changed


def validate_skills(config: dict[str, object]) -> None:
    skills_dir = expand(nested(config, "canonical", "skills"), "canonical.skills")
    names: set[str] = set()
    for path in sorted(skills_dir.glob("*/SKILL.md")):
        metadata, _ = load_markdown(path)
        name = require_string(metadata.get("name"), f"{path}: name")
        description = require_string(
            metadata.get("description"), f"{path}: description"
        )
        if name != path.parent.name:
            raise ConfigError(f"name mismatch: {path}")
        if SKILL_NAME.fullmatch(name) is None:
            raise ConfigError(f"invalid skill name: {name}")
        if len(description) > 1024:
            raise ConfigError(f"description too long: {name}")
        if name in names:
            raise ConfigError(f"duplicate skill: {name}")
        names.add(name)
    print(f"validated {len(names)} skills")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate harness adapters from ~/.agents"
    )
    parser.add_argument("config", type=Path)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--validate-skills", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config = load_yaml_mapping(args.config)
    if args.validate_skills:
        validate_skills(config)
        return 0

    changed = generate_agents(config, apply=args.apply)
    changed.extend(generate_commands(config, apply=args.apply))
    if not changed:
        print("adapters are current")
        return 0
    print("updated:" if args.apply else "drift:")
    for path in changed:
        print(f"  {path}")
    return 0 if args.apply else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ConfigError as error:
        raise SystemExit(str(error)) from error
