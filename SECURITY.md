# Security policy

## Supported versions

This is a personal learning project. Only the latest release and the `main` branch receive
security fixes.

| Version | Supported |
|---|---|
| Latest release / `main` | Yes |
| Older releases | No |

## Reporting a vulnerability

**Please do not open a public issue, pull request or discussion for security problems.**

Report it privately through GitHub's private vulnerability reporting:
[Report a vulnerability](https://github.com/jmpoliveira/docker-env/security/advisories/new)
(also reachable from the **Security** tab of this repository).

Please include:

- what the problem is and where (service, compose file, collector or gateway config);
- the steps or a minimal configuration to reproduce it;
- what an attacker could do with it;
- the version or commit you tested.

Do not include real API keys, connection strings, personal data or other secrets in the report.

## What to expect

This project is maintained in spare time, so responses are best effort:

- an acknowledgement within about one week;
- a fix, or an explanation of why it will not be fixed, as soon as is reasonable;
- credit in the advisory and release notes, if you want it.

Please give a reasonable amount of time for a fix before disclosing the problem publicly.

## Scope

In scope: the configuration in this repository (`docker-compose*.yml`, `config/`, the
`Makefile`, the env examples and the CI workflow).

Out of scope:

- vulnerabilities in the images themselves (Ollama, LiteLLM, ChromaDB, OpenTelemetry
  Collector, Jaeger, Phoenix, Postgres, Redis): report them to the upstream project;
  Dependabot keeps the pinned tags up to date;
- the projects that consume these services, such as
  [ai-agent-service](https://github.com/jmpoliveira/ai-agent-service) and
  [mcp-server](https://github.com/jmpoliveira/mcp-server), which have their own repositories.

## Known limitations

This environment is built for **local development only**:

- every host port binds to `127.0.0.1`, so the services are not reachable from other machines;
- the defaults in `.env.example` (`LITELLM_MASTER_KEY=sk-local-dev`, `POSTGRES_PASSWORD=postgres`)
  are public dev values, not secrets. Change them before binding any port to another interface;
- the services on the `docker-env-net` network trust each other and run without TLS.

A configuration that exposes a service or a secret despite these defaults is still a welcome
report. The Azure Monitor connection string is an ingestion key: keep it in `.env`, which git
ignores.
