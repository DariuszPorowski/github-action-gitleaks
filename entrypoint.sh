#!/bin/bash

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
INPUT_CONFIG=$(default "/.gitleaks/GitleaksUdmCombo.toml" "${GITHUB_WORKSPACE}/${INPUT_CONFIG}" "${INPUT_CONFIG}" 'true')
INPUT_REPORT_FORMAT=$(default 'json' "${INPUT_REPORT_FORMAT}" "${INPUT_REPORT_FORMAT}" 'true')
INPUT_REDACT=$(default 'true' 'false' "${INPUT_REDACT}" 'true')
INPUT_FAIL=$(default 'true' 'false' "${INPUT_FAIL}" 'true')
INPUT_VERBOSE=$(default 'true' 'false' "${INPUT_VERBOSE}" 'true')
INPUT_LOG_LEVEL=$(default 'info' "${INPUT_LOG_LEVEL}" "${INPUT_LOG_LEVEL}" 'true')

echo "----------------------------------"
echo "INPUT PARAMETERS"
echo "----------------------------------"
echo "INPUT_SOURCE: ${INPUT_SOURCE}"
echo "INPUT_CONFIG: ${INPUT_CONFIG}"
echo "INPUT_REPORT_FORMAT: ${INPUT_REPORT_FORMAT}"
echo "INPUT_NO_GIT: ${INPUT_NO_GIT}"
echo "INPUT_REDACT: ${INPUT_REDACT}"
echo "INPUT_FAIL: ${INPUT_FAIL}"
echo "INPUT_VERBOSE: ${INPUT_VERBOSE}"
echo "INPUT_LOG_LEVEL: ${INPUT_LOG_LEVEL}"
echo "----------------------------------"

echo "Setting Git safe directory (CVE-2022-24765)"
echo "git config --global --add safe.directory ${INPUT_SOURCE}"
git config --global --add safe.directory "${INPUT_SOURCE}"
echo "----------------------------------"

command="gitleaks detect"
if [ -f "${INPUT_CONFIG}" ]; then
    command+=$(arg '--config %s' "${INPUT_CONFIG}")
fi

command+=$(arg '--report-format %s' "${INPUT_REPORT_FORMAT}")
command+=$(arg '--redact' "${INPUT_REDACT}")
command+=$(arg '--verbose' "${INPUT_VERBOSE}")
command+=$(arg '--log-level %s' "${INPUT_LOG_LEVEL}")
command+=$(arg '--report-path %s' "${GITHUB_WORKSPACE}/gitleaks-report.${INPUT_REPORT_FORMAT}")

if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
    command+=$(arg '--source %s' "${GITHUB_WORKSPACE}")

    base_sha=$(git rev-parse "refs/remotes/origin/${GITHUB_BASE_REF}")
    head_sha=$(git rev-parse "refs/remotes/pull/${GITHUB_REF_NAME}")
    command+=$(arg '--log-opts "%s"' "${base_sha}^..${head_sha}")
else
    command+=$(arg '--source %s' "${INPUT_SOURCE}")
    command+=$(arg '--no-git' "${INPUT_NO_GIT}")
fi

echo "Running gitleaks $(gitleaks version)"
echo "----------------------------------"
echo "${command}"
echo "::set-output name=command::${command}"
COMMAND_OUTPUT=$(eval "${command}")

if [ $? -eq 1 ]; then
    echo "----------------------------------"
    echo "${COMMAND_OUTPUT}"
    echo "::set-output name=exitcode::1"
    echo "::set-output name=output::${COMMAND_OUTPUT}"
    echo "::set-output name=report::gitleaks-report.${INPUT_REPORT_FORMAT}"
    GITLEAKS_RESULT="STOP! Gitleaks encountered leaks or error"
    echo "::set-output name=result::${GITLEAKS_RESULT}"
    if [ "${INPUT_FAIL}" = "true" ]; then
        echo "::error::${GITLEAKS_RESULT}"
        exit 1
    else
        echo "::warning::${GITLEAKS_RESULT}"
    fi
else
    echo "----------------------------------"
    echo "${COMMAND_OUTPUT}"
    echo "::set-output name=exitcode::0"
    echo "::set-output name=output::${COMMAND_OUTPUT}"
    echo "::set-output name=report::gitleaks-report.${INPUT_REPORT_FORMAT}"
    GITLEAKS_RESULT="SUCCESS! Your code is good to go"
    echo "::set-output name=result::${GITLEAKS_RESULT}"
    echo "::notice::${GITLEAKS_RESULT}"
fi

echo "Gitleaks Summary: ${GITLEAKS_RESULT}" >>$GITHUB_STEP_SUMMARY
