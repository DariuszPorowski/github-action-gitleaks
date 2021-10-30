# GitHub Action for Gitleaks

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/DariuszPorowski/github-action-gitleaks)](https://github.com/DariuszPorowski/github-action-gitleaks/releases)

This GitHub Action provides a way to run [Gitleaks](https://github.com/zricethezav/gitleaks) in your CI/CD pipeline.

## Inputs

| Name        | Required | Default value           | Description                                              |
| ----------- | -------- | ----------------------- | -------------------------------------------------------- |
| path        | false    | ${{ github.workspace }} | Path to scan                                             |
| config-path | false    | .github/.gitleaks.toml  | Path to config (relative to $GITHUB_WORKSPACE)           |
| format      | true     | json                    | Report file format: json, csv, sarif                     |
| no-git      | false    |                         | Treat git repos as plain directories and scan those file |
| redact      | false    |                         | Redact secrets from log messages and leaks               |
| depth       | false    |                         | Number of commits to scan                                |
| fail        | false    | true                    | Fail if secrets founded                                  |
| verbose     | false    |                         | Show verbose output from scan                            |
| debug       | false    |                         | Log debug messages                                       |

## Outputs

| Name     | Description                         |
| -------- | ----------------------------------- |
| exitcode | Success for failure value from scan |
| result   | Gitleaks log output                 |
| report   | Report file path                    |

## Example usage

```yaml
- name: Checkout
  uses: actions/checkout@v2
- name: Run Gitleaks
  id: gitleaks
  uses: DariuszPorowski/github-action-gitleaks@v1.0.3
  with:
    config-path: ".github/.myconfig.toml"
    format: "sarif"
    fail: false
- name: Get the output from the gitleaks step
  run: |
    echo "exitcode: ${{ steps.gitleaks.outputs.exitcode }}"
    echo "result: ${{ steps.gitleaks.outputs.result }}"
    echo "report: ${{ steps.gitleaks.outputs.report }}"
- name: Upload SARIF report
  uses: github/codeql-action/upload-sarif@v1
  with:
    sarif_file: ${{ steps.gitleaks.outputs.report }}
```
