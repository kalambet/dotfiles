#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"
require "yaml"

MARKER = "<!-- Generated from ~/.agents; edit the canonical source instead. -->"

def expand(path)
  File.expand_path(path.sub(%r{\A~/}, ""), Dir.home)
end

def load_markdown(path)
  text = File.read(path)
  match = text.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
  raise "invalid frontmatter: #{path}" unless match

  [YAML.safe_load(match[1]), match[2].strip]
end

def managed_write(path, content, apply:)
  if File.exist?(path) && !File.read(path).include?(MARKER)
    raise "refusing to overwrite unmanaged file: #{path}"
  end
  current = File.exist?(path) ? File.read(path) : nil
  return false if current == content
  return true unless apply

  FileUtils.mkdir_p(File.dirname(path))
  temp = "#{path}.tmp.#{$$}"
  File.write(temp, content)
  File.rename(temp, path)
  true
ensure
  FileUtils.rm_f(temp) if defined?(temp) && temp
end

def yaml_frontmatter(data)
  YAML.dump(data).sub(/\A---\s*\n/, "")
end

config_path = ARGV.fetch(0)
mode = ARGV.fetch(1, "--check")
apply = mode == "--apply"
raise "expected --check or --apply" unless apply || mode == "--check"

config = YAML.safe_load(File.read(config_path))
prompts_dir = expand(config.dig("canonical", "prompts"))
commands_dir = expand(config.dig("canonical", "commands"))
changed = []

Dir.glob(File.join(prompts_dir, "*.md")).sort.each do |source|
  meta, body = load_markdown(source)
  name = meta.fetch("name")
  description = meta.fetch("description")
  model_class = meta.fetch("model_class")
  read_only = meta.fetch("read_only")
  skills = meta.fetch("skills", [])

  claude_tools = case model_class
                 when "architect" then "Read, Grep, Glob, Write, Edit, WebSearch, WebFetch, Skill"
                 when "developer" then "Read, Write, Edit, Bash, Glob, Grep, Skill"
                 when "researcher" then "Read, Glob, Grep, WebSearch, WebFetch"
                 else "Read, Glob, Grep, Bash, Skill"
                 end
  claude = {
    "name" => name,
    "description" => description,
    "tools" => claude_tools,
    "model" => config.dig("models", "claude", model_class)
  }
  claude["skills"] = skills unless skills.empty?
  content = "---\n#{yaml_frontmatter(claude)}---\n#{MARKER}\n\n#{body}\n"
  path = File.join(expand(config.dig("agent_directories", "claude")), "#{name}.md")
  changed << path if managed_write(path, content, apply: apply)

  junie = {
    "name" => name,
    "description" => description,
    "model" => config.dig("models", "junie", model_class),
    "skills" => skills
  }
  junie["tools"] = read_only ? ["read", "search", "web"] : ["read", "write", "shell", "search", "web"]
  content = "---\n#{yaml_frontmatter(junie)}---\n#{MARKER}\n\n#{body}\n"
  path = File.join(expand(config.dig("agent_directories", "junie")), "#{name}.md")
  changed << path if managed_write(path, content, apply: apply)

  permissions = { "edit" => read_only ? "deny" : "allow" }
  permissions["shell"] = "deny" if %w[oracle librarian].include?(name)
  opencode = {
    "description" => description,
    "mode" => "subagent",
    "model" => config.dig("models", "opencode", model_class),
    "permissions" => permissions
  }
  content = "---\n#{yaml_frontmatter(opencode)}---\n#{MARKER}\n\n#{body}\n"
  path = File.join(expand(config.dig("agent_directories", "opencode")), "#{name}.md")
  changed << path if managed_write(path, content, apply: apply)
end

Dir.glob(File.join(commands_dir, "*.md")).sort.each do |source|
  name = File.basename(source, ".md")
  body = File.read(source).strip
  description = "Run the #{name} phase of the approved Research → Plan → Annotate → Implement workflow"

  {
    "claude" => "---\ndescription: #{description}\n---\n#{MARKER}\n\n#{body}\n",
    "codex" => "#{MARKER}\n\n#{body}\n",
    "junie" => "---\ndescription: #{description}\nallowPromptArgument: true\n---\n#{MARKER}\n\n#{body.gsub("$ARGUMENTS", "$prompt")}\n",
    "opencode" => "---\ndescription: #{description}\n---\n#{MARKER}\n\n#{body}\n"
  }.each do |harness, content|
    path = File.join(expand(config.dig("command_directories", harness)), "#{name}.md")
    changed << path if managed_write(path, content, apply: apply)
  end
end

if changed.empty?
  puts "adapters are current"
  exit 0
end

puts "#{apply ? 'updated' : 'drift'}:"
changed.each { |path| puts "  #{path}" }
exit(apply ? 0 : 1)
