# VS Code (Insiders) configuration

Exported from `~/.config/Code - Insiders/User`.

- `default/` – default profile
- `profiles/<name>/` – one folder per named profile (csharp, vue, go, finance, unity)
  - `settings.json`, `keybindings.json`, `tasks.json`, `snippets/`, `chatLanguageModels.json` (when present)
  - `extensions.txt` – extension ids, one per line

The `Agents` built-in profile is not exported.

## Apply

```bash
./apply.sh                 # all profiles
./apply.sh unity           # one profile (folder name)
CODE=code ./apply.sh       # use stable VS Code instead of Insiders
```
