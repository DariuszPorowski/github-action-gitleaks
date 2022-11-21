# GitHub Action for Gitleaks

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/DariuszPorowski/github-action-gitleaks)](https://github.com/DariuszPorowski/github-action-gitleaks/releases)

This GitHub Action allows you to run [Gitleaks](https://github.com/zricethezav/gitleaks) in your CI/CD workflow.

> NOTE: v2 of this GitHub Action supports only the latest version of Gitleaks from v8 release.

## Inputs

| Name          | Required | Type   | Default value                    | Description                                              |
| ------------- | -------- | ------ | -------------------------------- | -------------------------------------------------------- |
| source        | false    | string | $GITHUB_WORKSPACE                | Path to source (relative to $GITHUB_WORKSPACE)           |
| config        | false    | string | /.gitleaks/UDMSecretChecks.toml  | Config file path (relative to $GITHUB_WORKSPACE)         |
| report_format | false    | string | json                             | Report file format: json, csv, sarif                     |
| no_git        | false    | bool   | false                            | Treat git repos as plain directories and scan those file |
| redact        | false    | bool   | true                             | Redact secrets from log messages and leaks               |
| fail          | false    | bool   | true                             | Fail if secrets founded                                  |
| verbose       | false    | bool   | true                             | Show verbose output from scan                            |
| log_level     | false    | string | info                             | Log level (debug, info, warn, error, fatal)              |

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

> **NOTE:** You must use actions/checkout before the `github-action-gitleaks` step. If you are using `actions/checkout@v3` you must specify a commit depth other than the default which is 1.
>
> Using a `fetch-depth` of '0' clones the entire history. If you want to do a more efficient clone, use '2', but that is not guaranteed to work with pull requests.

### With SARIF report

```yaml
- name: Checkout
  uses: actions/checkout@v3
  with:
    fetch-depth: 0

- name: Run Gitleaks
  id: gitleaks
  uses: DariuszPorowski/github-action-gitleaks@v2
  with:
    report_format: sarif
    fail: false

# (optional) It's just to see outputs from the Action
- name: Get the output from the gitleaks step
  run: |
    echo "exitcode: ${{ steps.gitleaks.outputs.exitcode }}"
    echo "result: ${{ steps.gitleaks.outputs.result }}"
    echo "output: ${{ steps.gitleaks.outputs.output }}"
    echo "command: ${{ steps.gitleaks.outputs.command }}"
    echo "report: ${{ steps.gitleaks.outputs.report }}"

- name: Upload Gitleaks SARIF report to code scanning service
  if: steps.gitleaks.outputs.exitcode == 1
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: ${{ steps.gitleaks.outputs.report }}
```

> **NOTE:** SARIF file uploads for code scanning is not available for everyone. Read GitHub docs ([Uploading a SARIF file to GitHub](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github)) for more information.

### With JSON report and custom rules config

```yaml
- name: Checkout
  uses: actions/checkout@v3
  with:
    fetch-depth: 0

- name: Run Gitleaks
  id: gitleaks
  uses: DariuszPorowski/github-action-gitleaks@v2
  with:
    config: "MyGitleaksConfigs/MyGitleaksConfig.toml"

- name: Upload Gitleaks JSON report to artifacts
  uses: actions/upload-artifact@v3
  if: failure()
  with:
    name: gitleaks
    path: ${{ steps.gitleaks.outputs.report }}
```

## Additional rules

[Jesse Houwing](https://github.com/jessehouwing) provided a Gitleaks config with most of Microsoft's deprecated CredScan rules. Consider using it if you need to scan projects based on Microsoft technologies or Azure Cloud.

- [UDMSecretChecks.toml](https://github.com/jessehouwing/gitleaks-azure/blob/main/UDMSecretChecksv8.toml)

## Contributions

If you have any feedback on `Gitleaks`, please reach out to [Zachary Rice](https://github.com/zricethezav) for creating and maintaining [Gitleaks](https://github.com/zricethezav/gitleaks).

Any feedback on the Gitleaks config for Azure `UDMSecretChecks.toml` file is welcome. Follow Jesse Houwing's GitHub repo - [gitleaks-azure](https://github.com/jessehouwing/gitleaks-azure).

Thanks to [C.J. May (@lawndoc)](https://github.com/lawndoc) for contributing 🤘

Any feedback or contribution to this project is welcome!

## How do I remove a secret from Git's history?

[GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) has a great article on this using the [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/).
