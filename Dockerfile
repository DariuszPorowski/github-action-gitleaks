FROM zricethezav/gitleaks:latest

LABEL "com.github.actions.name"="github-action-gitleaks"
LABEL "com.github.actions.description"="Runs gitleaks"
LABEL "com.github.actions.icon"="shield"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/DariuszPorowski/github-action-gitleaks"

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]