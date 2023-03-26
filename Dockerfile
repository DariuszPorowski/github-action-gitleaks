# FROM zricethezav/gitleaks:latest
FROM ghcr.io/gitleaks/gitleaks:latest

LABEL "com.github.actions.name"="Gitleaks Scanner"
LABEL "com.github.actions.description"="Runs Gitleaks in your CI/CD workflow"
LABEL "com.github.actions.icon"="shield"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/DariuszPorowski/github-action-gitleaks"

COPY .gitleaks/* /.gitleaks/
COPY entrypoint.sh /entrypoint.sh
USER root
ENTRYPOINT ["/entrypoint.sh"]
