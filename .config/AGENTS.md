# Personal AGENTS.md

## Communication Style

- Be concise and direct
- Skip explanations unless asked
- Use Oracle frequently for planning, debugging, and architecture reviews
- When asked to update/fix code, just do it - don't ask for confirmation

## Workflow For A New Project

Follow the Research → Plan → Annotate → Implement pipeline.
See `.config/agents/` for phase-specific slash commands.
- Never implement without an approved plan in `plan.md`
- Write research findings to `research.md` before planning
- Wait for inline annotations before proceeding between phases
- Mark tasks complete in the plan during implementation
- Run typecheck continuously during implementation

## Workflow Preferences

- **Always consult Oracle** for: bug fixes, architecture decisions, security audits, complex implementations
- **Always consult Librarian** for: documentation investigation, code reviews, and best practices
- When writing scripts, prefer reading config from YAML files (e.g., `config.yaml`, `config.devnet.yaml`, `config.mainnet.yaml`)
- Use environment variables as overrides, not primary config source
- Generate PR descriptions in markdown files when asked (e.g., `pr_description.md`)
- Write release notes concisely
- Check ARCHITECTURE.md in the root directory or in the `docs` directory
- Check LIBRARIAN.md in the root directory or in the `docs` directory

## Common Tech Stack

### Go Projects
```bash
# Build
go build ./...

# Test
go test ./...
```

### Solidity/Foundry Projects
```bash
# Build
forge build

# Test
forge test

# Deploy
forge script <Script>.s.sol --broadcast --rpc-url $ETH_RPC_URL
```

### Shell Scripts
- Use `jq` for JSON parsing
- Use `cast` for Ethereum interactions
- Parse YAML configs with `awk`/`grep`/`sed`
- Always add confirmation prompts for mainnet operations
- Support `--dry-run` flag for validation

## Code Conventions

- Extract magic numbers/amounts into variables at the top of scripts
- Use meaningful variable names (e.g., `TEST_DEPOSIT_TOKENS`, `TEST_WITHDRAW_AMOUNT_DECIMAL`)
- Add colored output helpers for scripts (`print_success`, `print_error`, `print_step`)
- For Go: follow existing patterns, use `zap` for logging
- For Solidity: use OpenZeppelin, SafeERC20, ReentrancyGuard

## Security Practices

- Never hardcode private keys - use environment variables
- Always check token mappings before creating duplicates
- Handle fee-on-transfer tokens explicitly
- Add multisig recommendations for privileged roles

## Common Patterns

### Script Configuration Pattern
```bash
# Parse from config file, allow env override
VALUE="${ENV_VAR:-$(grep 'key:' config.yaml | sed 's/.*key: *"\([^"]*\)".*/\1/')}"
```

## GitHub

### Pull Requests

When crawling Github do not try to access the page directly, use snipets like this:
```
curl -s "https://api.github.com/repos/kalambet/tbyd/pulls/1/comments" | python3 -c "
  import json, sys
  comments = json.load(sys.stdin)
  # Get only gemini-code-assist comments, sorted by created_at
  gemini = [c for c in comments if c['user']['login'] == 'gemini-code-assist[bot]']
  # Get the latest review id
  if gemini:
      latest_review = max(set(c['pull_request_review_id'] for c in gemini))
      for c in gemini:
          if c['pull_request_review_id'] == latest_review:
              print(f\"File: {c['path']}, Line: {c.get('line', c.get('original_line'))}\")
              print(c['body'][:1000])
              print('---')
  " 2>&1
```
