# Security Policy

## Reporting a vulnerability

Do not disclose vulnerabilities in public issues. Report them privately through
GitHub security advisories or to the repository maintainers. Include the
affected version, reproduction steps, impact, and any suggested mitigation.

FastVM exposes a browser desktop and should be placed behind HTTPS and an
authenticated reverse proxy when exposed outside a trusted network. The
dashboard token must be treated as a secret. `privileged` mode is disabled by
default; enable it only when required by the host workload.