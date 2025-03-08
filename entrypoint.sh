#!/bin/bash

set +e

function arg() {
  local _format="${1}"
  local _val="${2}"

  if [[ "${#_val}" == 0 || "${_val}" == "false" ]]; then
    return
  fi

  printf " ${_format}" "${_val}"
}

function default() {
  local _default="${1}"
  local _result="${2}"
  local _val="${3}"
  local _defaultifnotset="${4}"

  if [[ "${_defaultifnotset}" == "true" ]]; then
    if [ "${#_val}" = 0 ]; then
      echo "${_default}"
      return
    fi
  fi

  if [[ "${_val}" != "${_default}" ]]; then
    echo "${_result}"
  else
    echo "${_val}"
  fi
}

INPUT_SOURCE=$(default "${GITHUB_WORKSPACE}" "${GITHUB_WORKSPACE}/${INPUT_SOURCE}" "${INPUT_SOURCE}" 'true')
INPUT_CONFIG=$(default "/.gitleaks/UDMSecretChecks.toml" "${GITHUB_WORKSPACE}/${INPUT_CONFIG}" "${INPUT_CONFIG}" 'true')
INPUT_REPORT_FORMAT=$(default 'json' "${INPUT_REPORT_FORMAT}" "${INPUT_REPORT_FORMAT}" 'true')
INPUT_REDACT=$(default 'true' 'false' "${INPUT_REDACT}" 'true')
INPUT_FAIL=$(default 'true' 'false' "${INPUT_FAIL}" 'true')
INPUT_VERBOSE=$(default 'true' 'false' "${INPUT_VERBOSE}" 'true')
INPUT_LOG_LEVEL=$(default 'info' "${INPUT_LOG_LEVEL}" "${INPUT_LOG_LEVEL}" 'true')
INPUT_EXIT_CODE=$(default '1' '0' "${INPUT_EXIT_CODE}" 'true')
INPUT_MAX_DECODE_DEPTH=$(default '0' '0' "${INPUT_MAX_DECODE_DEPTH}" 'true')
INPUT_FOLLOW_SYMLINKS=$(default 'false' 'true' "${INPUT_FOLLOW_SYMLINKS}" 'true')

echo "----------------------------------"
echo "INPUT PARAMETERS"
echo "----------------------------------"
echo "INPUT_SOURCE: ${INPUT_SOURCE}"
echo "INPUT_CONFIG: ${INPUT_CONFIG}"
echo "INPUT_BASELINE_PATH: ${INPUT_BASELINE_PATH}"
echo "INPUT_REPORT_FORMAT: ${INPUT_REPORT_FORMAT}"
echo "INPUT_NO_GIT: ${INPUT_NO_GIT}"
echo "INPUT_REDACT: ${INPUT_REDACT}"
echo "INPUT_FAIL: ${INPUT_FAIL}"
echo "INPUT_VERBOSE: ${INPUT_VERBOSE}"
echo "INPUT_LOG_LEVEL: ${INPUT_LOG_LEVEL}"
echo "INPUT_EXIT_CODE: ${INPUT_EXIT_CODE}"
echo "INPUT_LOG_OPTS: ${INPUT_LOG_OPTS}"
echo "INPUT_MAX_DECODE_DEPTH: ${INPUT_MAX_DECODE_DEPTH}"
echo "INPUT_FOLLOW_SYMLINKS: ${INPUT_FOLLOW_SYMLINKS}"
echo "----------------------------------"

echo "Setting Git safe directory (CVE-2022-24765)"
echo "git config --global --add safe.directory ${GITHUB_WORKSPACE}"
git config --global --add safe.directory "${GITHUB_WORKSPACE}"
echo "----------------------------------"

command="gitleaks detect"
if [ -f "${INPUT_CONFIG}" ]; then
  command+=$(arg '--config %s' "${INPUT_CONFIG}")
fi

command+=$(arg '--baseline-path %s' "${INPUT_BASELINE_PATH}")
command+=$(arg '--report-format %s' "${INPUT_REPORT_FORMAT}")
command+=$(arg '--redact' "${INPUT_REDACT}")
command+=$(arg '--verbose' "${INPUT_VERBOSE}")
command+=$(arg '--log-level %s' "${INPUT_LOG_LEVEL}")
command+=$(arg '--report-path %s' "${GITHUB_WORKSPACE}/gitleaks-report.${INPUT_REPORT_FORMAT}")
command+=$(arg '--exit-code %d' "${INPUT_EXIT_CODE}")
command+=$(arg '--max-decode-depth %d' "${INPUT_MAX_DECODE_DEPTH}")
command+=$(arg '--follow-symlinks' "${INPUT_FOLLOW_SYMLINKS}")

if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
  command+=$(arg '--source %s' "${GITHUB_WORKSPACE}")

  base_sha=$(git rev-parse "refs/origin/${GITHUB_BASE_REF}")
  head_sha=$(git rev-list --no-merges -n 1 "refs/remotes/${GITHUB_REF}")
  command+=$(arg '--log-opts "%s"' "--no-merges --first-parent ${base_sha}...${head_sha}")
else
  command+=$(arg '--log-opts "%s"' "${INPUT_LOG_OPTS}")
  command+=$(arg '--source %s' "${INPUT_SOURCE}")
  command+=$(arg '--no-git' "${INPUT_NO_GIT}")
fi

echo "Running gitleaks $(gitleaks version)"
echo "----------------------------------"
echo "${command}"

OUTPUT=$(eval "${command}")
exitcode=$?

if [ ${exitcode} -eq 0 ]; then
  GITLEAKS_RESULT="✅ SUCCESS! Your code is good to go"
elif [ ${exitcode} -eq 1 ]; then
  GITLEAKS_RESULT="❌ STOP! Gitleaks encountered leaks or error"
else
  GITLEAKS_RESULT="Gitleaks unknown error"
fi

echo "----------------------------------"
echo -e "${OUTPUT}"

EOF=$(dd if=/dev/urandom bs=15 count=1 status=none | base64)
echo "output<<$EOF" >>"$GITHUB_OUTPUT"
echo -e "${OUTPUT}" >>"$GITHUB_OUTPUT"
echo "$EOF" >>"$GITHUB_OUTPUT"
echo "report=gitleaks-report.${INPUT_REPORT_FORMAT}" >>"$GITHUB_OUTPUT"
echo "result=${GITLEAKS_RESULT}" >>"$GITHUB_OUTPUT"
echo "command=${command}" >>"$GITHUB_OUTPUT"
echo "exitcode=${exitcode}" >>"$GITHUB_OUTPUT"
echo -e "Gitleaks Summary: ${GITLEAKS_RESULT}\n" >>"$GITHUB_STEP_SUMMARY"
echo -e "${OUTPUT}" >>"$GITHUB_STEP_SUMMARY"

if [ ${exitcode} -eq 0 ]; then
  echo "::notice::${GITLEAKS_RESULT}"
elif [ ${exitcode} -eq 1 ]; then
  if [ "${INPUT_FAIL}" = "true" ]; then
    echo "::error::${GITLEAKS_RESULT}"
  else
    echo "::warning::${GITLEAKS_RESULT}"
    exit 0
  fi
else
  echo "::error::${GITLEAKS_RESULT}"
fi
exit ${exitcode}
