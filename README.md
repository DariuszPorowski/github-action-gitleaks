# GitHub Action for Gitleaks

[![GitHub - marketplace](https://img.shields.io/badge/marketplace-gitleaks--scanner-blue?logo=github&style=flat-square)](https://github.com/marketplace/actions/gitleaks-scanner)
[![GitHub - release](https://img.shields.io/github/v/release/DariuszPorowski/github-action-gitleaks?style=flat-square)](https://github.com/DariuszPorowski/github-action-gitleaks/releases/latest)
[![GitHub - license](https://img.shields.io/github/license/DariuszPorowski/github-action-gitleaks?style=flat-square)](https://github.com/DariuszPorowski/github-action-gitleaks/blob/main/LICENSE)

This GitHub Action allows you to run [Gitleaks](https://github.com/gitleaks/gitleaks) in your CI/CD workflow.

> ⚠️ `v2` of this GitHub Action supports only the latest version of Gitleaks from v8 release.

## Inputs

| Name             | Required |  Type  | Default value                   | Description                                                                      |
|------------------|:--------:|:------:|---------------------------------|----------------------------------------------------------------------------------|
| source           |  false   | string | $GITHUB_WORKSPACE               | Path to source (relative to $GITHUB_WORKSPACE)                                   |
| config           |  false   | string | /.gitleaks/UDMSecretChecks.toml | Config file path (relative to $GITHUB_WORKSPACE)                                 |
| baseline_path    |  false   | string | *not set*                       | Path to baseline with issues that can be ignored (relative to $GITHUB_WORKSPACE) |
| report_format    |  false   | string | json                            | Report file format: json, csv, sarif                                             |
| no_git           |  false   |  bool  | *not set*                       | Treat git repos as plain directories and scan those file                         |
| redact           |  false   |  bool  | true                            | Redact secrets from log messages and leaks                                       |
| fail             |  false   |  bool  | true                            | Fail if secrets founded                                                          |
| verbose          |  false   |  bool  | true                            | Show verbose output from scan                                                    |
| log_level        |  false   | string | info                            | Log level (trace, debug, info, warn, error, fatal)                               |
| exit_code        |  false   |  int   | 1                               | Exit code when leaks have been encountered                                       |
| log_opts         |  false   | string | *not set*                       | Exit code when leaks have been encountered                                       |
| max_decode_depth |  false   |  int   | 0                               | Allow recursive decoding up to this depth (default "0", no decoding is done)     |

> ⚠️ The solution provides predefined configuration (See: [.gitleaks](https://github.com/DariuszPorowski/github-action-gitleaks/tree/main/.gitleaks) path). You can override it by yours config using relative to `$GITHUB_WORKSPACE`.

## Outputs

| Name     | Description                                            |
|----------|--------------------------------------------------------|
| exitcode | Success (code: 0) or failure (code: 1) value from scan |
| result   | Gitleaks result summary                                |
| output   | Gitleaks log output                                    |
| command  | Gitleaks executed command                              |
| report   | Report file path                                       |

## Example usage

> ⚠️ You must use `actions/checkout` before the `github-action-gitleaks` step. If you are using `actions/checkout@v4` you must specify a commit depth other than the default which is 1.
>
> Using a `fetch-depth` of '0' clones the entire history. If you want to do a more efficient clone, use '2', but that is not guaranteed to work with pull requests.

### Pull Request with comment

```yaml
---
name: Secret Scan

on:
  pull_request:
  push:
    branches:
      - main

# allow one concurrency
concurrency:
  group: ${{ format('{0}-{1}-{2}-{3}-{4}', github.workflow, github.event_name, github.ref, github.base_ref, github.head_ref) }}
  cancel-in-progress: true

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        id: gitleaks
        uses: DariuszPorowski/github-action-gitleaks@v2
        with:
          fail: false

      - name: Post PR comment
        uses: actions/github-script@v7
        if: ${{ steps.gitleaks.outputs.exitcode == 1 && github.event_name == 'pull_request' }}
        with:
          github-token: ${{ github.token }}
          script: |
            const { GITLEAKS_RESULT, GITLEAKS_OUTPUT } = process.env
            const output = `### ${GITLEAKS_RESULT}

            <details><summary>Log output</summary>

            ${GITLEAKS_OUTPUT}

            </details>
            `
            github.rest.issues.createComment({
              ...context.repo,
              issue_number: context.issue.number,
              body: output
            })
        env:
          GITLEAKS_RESULT: ${{ steps.gitleaks.outputs.result }}
          GITLEAKS_OUTPUT: ${{ steps.gitleaks.outputs.output }}
```

### With SARIF report

```yaml
- name: Checkout
  uses: actions/checkout@v4
  with:
    fetch-depth: 0

- name: Run Gitleaks
  id: gitleaks
  uses: DariuszPorowski/github-action-gitleaks@v2
  with:
    report_format: sarif
    fail: false

# (optional) It's just to see outputs from the Action
# please note, the OUTPUT has to be passed via env vars!
- name: Get the output from the gitleaks step
  run: |
    echo "exitcode: ${{ steps.gitleaks.outputs.exitcode }}"
    echo "result: ${{ steps.gitleaks.outputs.result }}"
    echo "command: ${{ steps.gitleaks.outputs.command }}"
    echo "report: ${{ steps.gitleaks.outputs.report }}"
    echo "output: ${GITLEAKS_OUTPUT}"
  env:
    GITLEAKS_OUTPUT: ${{ steps.gitleaks.outputs.output }}

- name: Upload Gitleaks SARIF report to code scanning service
  if: ${{ steps.gitleaks.outputs.exitcode == 1 }}
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: ${{ steps.gitleaks.outputs.report }}
```

> ⚠️ SARIF file uploads for code scanning is not available for everyone. Read GitHub docs ([Uploading a SARIF file to GitHub](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github)) for more information.

### With JSON report and custom rules config

```yaml
- name: Checkout
  uses: actions/checkout@v4
  with:
    fetch-depth: 0

- name: Run Gitleaks
  id: gitleaks
  uses: DariuszPorowski/github-action-gitleaks@v2
  with:
    config: MyGitleaksConfigs/MyGitleaksConfig.toml

- name: Upload Gitleaks JSON report to artifacts
  uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: gitleaks
    path: ${{ steps.gitleaks.outputs.report }}
```

## Additional rules

[Jesse Houwing](https://github.com/jessehouwing) provided a Gitleaks config with most of Microsoft's deprecated CredScan rules. Consider using it if you need to scan projects based on Microsoft technologies or Azure Cloud.

- [UDMSecretChecks.toml](https://github.com/jessehouwing/gitleaks-azure/blob/main/UDMSecretChecksv8.toml)

## Contributions

If you have any feedback on `Gitleaks`, please reach out to [Zachary Rice (@zricethezav)](https://github.com/zricethezav) for creating and maintaining [Gitleaks](https://github.com/gitleaks/gitleaks).

Any feedback on the Gitleaks config for Azure `UDMSecretChecks.toml` file is welcome. Follow Jesse Houwing's GitHub repo - [gitleaks-azure](https://github.com/jessehouwing/gitleaks-azure).

Thanks to [C.J. May (@lawndoc)](https://github.com/lawndoc) for contributing 🤘

Any feedback or contribution to this project is welcome!

## How do I remove a secret from Git's history?

[GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) has a great article on this using the [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/).
