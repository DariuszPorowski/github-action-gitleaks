# GitHub Action for Gitleaks

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/DariuszPorowski/github-action-gitleaks)](https://github.com/DariuszPorowski/github-action-gitleaks/releases)

This GitHub Action provides a way to run [Gitleaks](https://github.com/zricethezav/gitleaks) in your CI/CD workflow.

## Inputs

| Name              | Required | Default value                   | Description                                                                                                                                                    |
| ----------------- | -------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| path              | false    | $GITHUB_WORKSPACE               | Path to scan (relative to $GITHUB_WORKSPACE)                                                                                                                   |
| config_path       | false    | /.gitleaks/gitleaks.toml        | Path to config (relative to $GITHUB_WORKSPACE)                                                                                                                 |
| additional_config | false    | /.gitleaks/UDMSecretChecks.toml | Path to an additional gitleaks config to append with an existing config (relative to $GITHUB_WORKSPACE). Set to "false" if additional_config does not required |
| format            | false    | json                            | Report file format: json, csv, sarif                                                                                                                           |
| branch            | false    |                                 | Branch to scan                                                                                                                                                 |
| no_git            | false    |                                 | Treat git repos as plain directories and scan those file                                                                                                       |
| redact            | false    |                                 | Redact secrets from log messages and leaks                                                                                                                     |
| depth             | false    |                                 | Number of commits to scan                                                                                                                                      |
| fail              | false    | true                            | Fail if secrets founded                                                                                                                                        |
| verbose           | false    |                                 | Show verbose output from scan                                                                                                                                  |
| debug             | false    |                                 | Log debug messages                                                                                                                                             |

> NOTE: The solution provides predefined configuration (See: [.gitleaks](https://github.com/DariuszPorowski/github-action-gitleaks/tree/main/.gitleaks) path). You can override it by yours config using relative to `$GITHUB_WORKSPACE`.

## Outputs

| Name     | Description                                            |
| -------- | ------------------------------------------------------ |
| exitcode | Success (code: 0) or failure (code: 1) value from scan |
| result   | Gitleaks result summary                                |
| output   | Gitleaks log output                                    |
| command  | Gitleaks executed command                              |
| report   | Report file path                                       |

## Example usage

> **NOTE:** You must use actions/checkout before the `github-action-gitleaks` step. If you are using `actions/checkout@v2` you must specify a commit depth other than the default which is 1.
>
> Using a `fetch-depth` of '0' clones the entire history. If you want to do a more efficient clone, use '2', but that is not guaranteed to work with pull requests.

```yaml
- name: Checkout
  uses: actions/checkout@v2
  with:
    fetch-depth: "0"

- name: Run Gitleaks
  id: gitleaks
  uses: DariuszPorowski/github-action-gitleaks@v1
  with:
    config_path: ".gitleaks/myconfig.toml"
    format: "sarif"
    fail: false

- name: Get the output from the gitleaks step
  run: |
    echo "exitcode: ${{ steps.gitleaks.outputs.exitcode }}"
    echo "result: ${{ steps.gitleaks.outputs.result }}"
    echo "output: ${{ steps.gitleaks.outputs.output }}"
    echo "command: ${{ steps.gitleaks.outputs.command }}"
    echo "report: ${{ steps.gitleaks.outputs.report }}"

- name: Upload SARIF report
  if: steps.gitleaks.outputs.exitcode == 1
  uses: github/codeql-action/upload-sarif@v1
  with:
    sarif_file: ${{ steps.gitleaks.outputs.report }}
```

> **NOTE:** SARIF file uploads for code scanning is not available for everyone. Read GitHub docs ([Uploading a SARIF file to GitHub](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github)) for more information.

## Additional rules

[Jesse Houwing](https://github.com/jessehouwing) provided a Gitleaks config with most of Microsoft's deprecated CredScan rules. Consider using it if you need to scan projects based on Microsoft technologies or Azure Cloud.

- [UDMSecretChecks.toml](https://github.com/jessehouwing/gitleaks-azure/blob/main/UDMSecretChecks.toml)

## Contributions

Any feedback on `Gitleaks`, please reach out to [Zachary Rice](https://github.com/zricethezav) for creating and maintaining [Gitleaks](https://github.com/zricethezav/gitleaks).

Any feedback on the gitleaks config for Azure `UDMSecretChecks.toml` file is welcome. Follow Jesse Houwing's github repo - [gitleaks-azure](https://github.com/jessehouwing/gitleaks-azure).

Any feedback or contribution to this project is welcome.

## How do I remove a secret from git's history?

[GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) has a great article on this using the [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/).
