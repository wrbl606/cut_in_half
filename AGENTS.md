<!-- BACKLOG.MD GUIDELINES START -->
<CRITICAL_INSTRUCTION>

## Backlog.md Workflow

This project uses Backlog.md for task and project management.

**For every user request in this project, run `backlog instructions overview` before answering or taking action.**

Use the overview to decide whether to search, read, create, or update Backlog tasks.

Use the detailed guides when needed:
- `backlog instructions task-creation` for creating or splitting tasks
- `backlog instructions task-execution` for planning and implementation workflow
- `backlog instructions task-finalization` for completion and handoff

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

### Backlog CLI Setup

If the CLI reports "No Backlog.md project found," run `backlog init` with the project name as a command argument (not piped via stdin):

```bash
backlog init "project-name" --defaults --integration-mode cli --agent-instructions none
```

This creates the `backlog/` directory and `Backlog.md` at the repo root. After initialization the CLI will recognize the project and all commands will work.

### Creating Tasks

Always include `--plain` for machine-readable output:

```bash
backlog task create "Task title" \
  -d "Description of the outcome." \
  --ac "Acceptance criterion 1" \
  --ac "Acceptance criterion 2" \
  --ref path/to/relevant/file.dart \
  --labels refactor \
  --priority medium \
  --plain
```

Available fields: `--ac` (repeatable), `--labels`, `--priority` (high/medium/low), `--ref` (repeatable), `-d/--description`, `--dep` (dependencies), `-p` (parent task), `--dod` (definition of done).

</CRITICAL_INSTRUCTION>
<!-- BACKLOG.MD GUIDELINES END -->