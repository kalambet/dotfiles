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
from dataclasses import dataclass
from pathlib import Path

import yaml

MARKER = "<!-- Generated from ~/.agents; edit the canonical source instead. -->"
FRONTMATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n(.*)\Z", re.DOTALL)
SKILL_NAME = re.compile(r"\A[a-z0-9]+(?:-[a-z0-9]+)*\Z")


class ConfigError(RuntimeError):
    """Raised when adapter configuration or source metadata is invalid."""


@dataclass(frozen=True)
class RuntimePaths:
    agents_root: Path
    adapter_home: Path


@dataclass(frozen=True)
class FileTarget:
    path: Path
    content: str


@dataclass(frozen=True)
class LinkTarget:
    path: Path
    source: Path


Target = FileTarget | LinkTarget


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
    for index, key in enumerate(keys[:-1], start=1):
        current = require_mapping(current.get(key), ".".join(keys[:index]))
    value = current.get(keys[-1])
    if value is None:
        raise ConfigError(f"missing configuration: {'.'.join(keys)}")
    return value


def runtime_paths() -> RuntimePaths:
    home = Path(os.environ.get("HOME", "~")).expanduser()
    return RuntimePaths(
        agents_root=Path(os.environ.get("AGENTS_ROOT", home / ".agents")),
        adapter_home=Path(os.environ.get("ADAPTER_HOME", home)),
    )


def expand(path: object, context: str, paths: RuntimePaths) -> Path:
    value = require_string(path, context)
    if value == "~/.agents":
        return paths.agents_root
    if value.startswith("~/.agents/"):
        return paths.agents_root / value.removeprefix("~/.agents/")
    if value == "~":
        return paths.adapter_home
    if value.startswith("~/"):
        return paths.adapter_home / value.removeprefix("~/")
    return Path(value)


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


def model(config: dict[str, object], harness: str, model_class: str) -> str:
    return require_string(
        nested(config, "models", harness, model_class),
        f"models.{harness}.{model_class}",
    )


def claude_tools(model_class: str, *, read_only: bool, shell: bool) -> str:
    tools = {
        "architect": [
            "Read",
            "Grep",
            "Glob",
            "Write",
            "Edit",
            "WebSearch",
            "WebFetch",
            "Skill",
        ],
        "developer": ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Skill"],
        "researcher": ["Read", "Glob", "Grep", "WebSearch", "WebFetch"],
    }.get(model_class, ["Read", "Glob", "Grep", "Bash", "Skill"])
    if read_only:
        tools = [tool for tool in tools if tool not in {"Write", "Edit"}]
    if not shell:
        tools = [tool for tool in tools if tool != "Bash"]
    return ", ".join(tools)


def render_agents(config: dict[str, object], paths: RuntimePaths) -> list[FileTarget]:
    prompts_dir = expand(
        nested(config, "canonical", "prompts"), "canonical.prompts", paths
    )
    targets: list[FileTarget] = []
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
        shell = require_bool(metadata.get("shell", True), f"{source}: shell")
        skills = require_strings(metadata.get("skills", []), f"{source}: skills")

        claude: dict[str, object] = {
            "name": name,
            "description": description,
            "tools": claude_tools(model_class, read_only=read_only, shell=shell),
            "model": model(config, "claude", model_class),
        }
        if skills:
            claude["skills"] = skills
        targets.append(
            FileTarget(
                expand(
                    nested(config, "agent_directories", "claude"),
                    "agent_directories.claude",
                    paths,
                )
                / f"{name}.md",
                f"---\n{frontmatter(claude)}---\n{MARKER}\n\n{body}\n",
            )
        )

        junie_tools = ["read", "search", "web"]
        if not read_only:
            junie_tools.insert(1, "write")
        if shell:
            junie_tools.append("shell")
        junie: dict[str, object] = {
            "name": name,
            "description": description,
            "model": model(config, "junie", model_class),
            "skills": skills,
            "tools": junie_tools,
        }
        targets.append(
            FileTarget(
                expand(
                    nested(config, "agent_directories", "junie"),
                    "agent_directories.junie",
                    paths,
                )
                / f"{name}.md",
                f"---\n{frontmatter(junie)}---\n{MARKER}\n\n{body}\n",
            )
        )

        opencode: dict[str, object] = {
            "description": description,
            "mode": "subagent",
            "model": model(config, "opencode", model_class),
            "permissions": {
                "edit": "deny" if read_only else "allow",
                "shell": "allow" if shell else "deny",
            },
        }
        targets.append(
            FileTarget(
                expand(
                    nested(config, "agent_directories", "opencode"),
                    "agent_directories.opencode",
                    paths,
                )
                / f"{name}.md",
                f"---\n{frontmatter(opencode)}---\n{MARKER}\n\n{body}\n",
            )
        )
    return targets


def render_commands(config: dict[str, object], paths: RuntimePaths) -> list[FileTarget]:
    commands_dir = expand(
        nested(config, "canonical", "commands"), "canonical.commands", paths
    )
    targets: list[FileTarget] = []
    for source in sorted(commands_dir.glob("*.md")):
        metadata, body = load_markdown(source)
        name = source.stem
        description = require_string(
            metadata.get("description"), f"{source}: description"
        )
        metadata_yaml = frontmatter({"description": description})
        contents = {
            "claude": f"---\n{metadata_yaml}---\n{MARKER}\n\n{body}\n",
            "codex": f"{MARKER}\n\n{body}\n",
            "junie": f"---\n{frontmatter({'description': description, 'allowPromptArgument': True})}---\n{MARKER}\n\n{body.replace('$ARGUMENTS', '$prompt')}\n",
            "opencode": f"---\n{metadata_yaml}---\n{MARKER}\n\n{body}\n",
        }
        directories = require_mapping(
            config.get("command_directories"), "command_directories"
        )
        for harness, directory in sorted(directories.items()):
            content = contents.get(harness)
            if content is None:
                raise ConfigError(f"unsupported command adapter: {harness}")
            targets.append(
                FileTarget(
                    expand(
                        directory,
                        f"command_directories.{harness}",
                        paths,
                    )
                    / f"{name}.md",
                    content,
                )
            )
    return targets


def render_instruction_links(
    config: dict[str, object], paths: RuntimePaths
) -> list[LinkTarget]:
    source = expand(
        nested(config, "canonical", "instructions"), "canonical.instructions", paths
    )
    adapters = require_mapping(
        config.get("instruction_adapters"), "instruction_adapters"
    )
    return [
        LinkTarget(expand(target, f"instruction_adapters.{name}", paths), source)
        for name, target in sorted(adapters.items())
    ]


def render_skill_links(
    config: dict[str, object], paths: RuntimePaths
) -> list[LinkTarget]:
    source = expand(nested(config, "canonical", "skills"), "canonical.skills", paths)
    adapters = require_mapping(config.get("skill_adapters"), "skill_adapters")
    return [
        LinkTarget(expand(target, f"skill_adapters.{name}", paths), source)
        for name, target in sorted(adapters.items())
    ]


def desired_link(target: LinkTarget) -> str:
    return os.path.relpath(target.source, start=target.path.parent)


def target_changed(target: Target) -> bool:
    if isinstance(target, FileTarget):
        if target.path.is_symlink():
            raise ConfigError(f"refusing to overwrite unmanaged symlink: {target.path}")
        if target.path.exists():
            current = target.path.read_text(encoding="utf-8")
            if MARKER not in current:
                raise ConfigError(
                    f"refusing to overwrite unmanaged file: {target.path}"
                )
            return current != target.content
        return True
    if target.path.is_symlink():
        return os.readlink(target.path) != desired_link(target)
    if target.path.exists():
        raise ConfigError(
            f"refusing to overwrite unmanaged instruction adapter: {target.path}"
        )
    return True


def preflight(targets: list[Target]) -> list[Target]:
    seen: set[Path] = set()
    changed: list[Target] = []
    for target in targets:
        if target.path in seen:
            raise ConfigError(f"duplicate generated target: {target.path}")
        seen.add(target.path)
        if target_changed(target):
            changed.append(target)
    return changed


def atomic_write(target: FileTarget) -> None:
    target.path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{target.path.name}.", dir=target.path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(target.content)
        temporary.replace(target.path)
    finally:
        temporary.unlink(missing_ok=True)


def atomic_link(target: LinkTarget) -> None:
    target.path.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.path.parent / f".{target.path.name}.{os.getpid()}.tmp"
    try:
        temporary.symlink_to(desired_link(target))
        temporary.replace(target.path)
    finally:
        temporary.unlink(missing_ok=True)


def apply_targets(targets: list[Target]) -> None:
    for target in targets:
        atomic_write(target) if isinstance(target, FileTarget) else atomic_link(target)


def validate_skills(config: dict[str, object], paths: RuntimePaths) -> None:
    skills_dir = expand(
        nested(config, "canonical", "skills"), "canonical.skills", paths
    )
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
    collision_directories = require_mapping(
        config.get("command_collision_directories"),
        "command_collision_directories",
    )
    for harness, directory in sorted(collision_directories.items()):
        commands_dir = expand(
            directory, f"command_collision_directories.{harness}", paths
        )
        collisions = sorted(
            path.stem for path in commands_dir.glob("*.md") if path.stem in names
        )
        if collisions:
            raise ConfigError(
                f"skill/command collision for {harness}: {', '.join(collisions)}"
            )
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
    paths = runtime_paths()
    if args.validate_skills:
        validate_skills(config, paths)
        return 0
    targets: list[Target] = []
    targets.extend(render_instruction_links(config, paths))
    targets.extend(render_skill_links(config, paths))
    targets.extend(render_agents(config, paths))
    targets.extend(render_commands(config, paths))
    changed = preflight(targets)
    if not changed:
        print("adapters are current")
        return 0
    if args.apply:
        apply_targets(changed)
    print("updated:" if args.apply else "drift:")
    for target in changed:
        print(f"  {target.path}")
    return 0 if args.apply else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ConfigError as error:
        raise SystemExit(str(error)) from error
