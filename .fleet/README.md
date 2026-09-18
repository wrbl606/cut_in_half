# `.fleet/` automation contract

This repository is a target for the fleet remote agent runner. The dispatcher
reads these files to render a prompt, run an agent, and gate the result:

- `fleet.toml` — manifest (agent tool, prompt, PR settings, COI policy)
- `prompts/task.md` — `{{var}}`-rendered task prompt
- `setup.sh` — `flutter pub get` (runs in the sandbox before the agent)
- `verify.sh` — `flutter analyze` + `flutter test` (the pass/fail gate)
- `pr-template.md` — PR body

See the `fleet-config` repository for the dispatcher, registry, and runner.

## Requirements

- **Flutter SDK** must be present in the runner image; `setup.sh`/`verify.sh`
  assume `flutter` is on `PATH`. If your COI image lacks Flutter, build a
  custom image (or run on a Flutter-equipped Linux agent) before targeting this
  repo. Installing Flutter in `setup.sh` alone is not enough, because the
  dispatcher runs setup/agent/verify as separate ephemeral containers and only
  the workspace persists between them.
- **LLM key**: the runner injects the value for `[agent].llm_env`
  (`OPENCODE_GO_SUBSCRIPTION_KEY`) from its credentials store. The value never
  lives in this repository.
- **GitHub token**: push/PR use a scoped token on the runner
  (`contents:write` + `pull-requests:write`). This repository does not store it.
