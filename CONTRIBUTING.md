# Contributing to FastVM

1. Copy `config.env.example` to `config.env` for local configuration.
2. Run `scripts/validate-config.sh` and `docker compose config` before opening a PR.
3. Run `npm ci` and `npm test` in `dashboard/` for dashboard changes.
4. Run ShellCheck and the repository lint workflow locally where available.

Pull requests should explain configuration changes, security implications, and
how the change was tested. Do not commit `data/`, recordings, backups, tokens,
dependency directories, or generated build output.