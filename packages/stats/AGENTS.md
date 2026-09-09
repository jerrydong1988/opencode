# Stats development

- `bun dev:stats` from the repository root starts the local site through SST with `--stage=production`.
- This can load production-linked configuration/resources. Use it only when the task authorizes that environment; do not assume it is an isolated fixture or substitute another stage without checking the project's setup.
