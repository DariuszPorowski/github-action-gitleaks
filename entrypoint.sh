#!/bin/bash

function arg(){
    local _command="${1}"
    local _format="${2}"
    local _val="${3}"
    
    if [[ "${#_val}" == 0 || "${_val}" == "false" ]]
    then
        echo "${_command}"
        return
    fi
    _arg=$(printf " ${_format}" "${_val}")
    echo "${_command}${_arg}"
}

function default(){
    local _default="${1}"
    local _result="${2}"
    local _val="${3}"
    local _defaultifnotset="${4}"

    if [[ "${_defaultifnotset}" == "true" ]]
    then
        if [ "${#_val}" = 0 ]
        then
            echo "${_default}"
            return
        fi
    fi

    if [[ "${_val}" != "${_default}" ]]
    then
        echo "${_result}"
    else
        echo "${_val}"
    fi
}

INPUT_PATH=$(default "${GITHUB_WORKSPACE}" "${GITHUB_WORKSPACE}/${INPUT_PATH}" "${INPUT_PATH}" 'true')
INPUT_CONFIG_PATH=$(default "/.gitleaks/gitleaks.toml" "${GITHUB_WORKSPACE}/${INPUT_CONFIG_PATH}" "${INPUT_CONFIG_PATH}" 'true')
if [[ "${INPUT_ADDITIONAL_CONFIG}" != "false" ]]
then
    INPUT_ADDITIONAL_CONFIG=$(default "/.gitleaks/UDMSecretChecks.toml" "${GITHUB_WORKSPACE}/${INPUT_ADDITIONAL_CONFIG}" "${INPUT_ADDITIONAL_CONFIG}" 'true')
fi
INPUT_FORMAT=$(default 'json' "${INPUT_FORMAT}" "${INPUT_FORMAT}" 'true')
INPUT_REDACT=$(default 'true' 'false' "${INPUT_REDACT}" 'true')
INPUT_FAIL=$(default 'true' 'false' "${INPUT_FAIL}" 'true')
INPUT_VERBOSE=$(default 'true' 'false' "${INPUT_VERBOSE}" 'true')

echo "----------------------------------"
echo "INPUT PARAMETERS"
echo "----------------------------------"
echo "INPUT_PATH: ${INPUT_PATH}"
echo "INPUT_CONFIG_PATH: ${INPUT_CONFIG_PATH}"
echo "INPUT_ADDITIONAL_CONFIG: ${INPUT_ADDITIONAL_CONFIG}"
echo "INPUT_FORMAT: ${INPUT_FORMAT}"
echo "INPUT_BRANCH: ${INPUT_BRANCH}"
echo "INPUT_NO_GIT: ${INPUT_NO_GIT}"
echo "INPUT_REDACT: ${INPUT_REDACT}"
echo "INPUT_DEPTH: ${INPUT_DEPTH}"
echo "INPUT_FAIL: ${INPUT_FAIL}"
echo "INPUT_VERBOSE: ${INPUT_VERBOSE}"
echo "INPUT_DEBUG: ${INPUT_DEBUG}"
echo "----------------------------------"

command="gitleaks"
if [ -f "${INPUT_CONFIG_PATH}" ]
then
    command=$(arg "${command}" '--config-path=%s' "${INPUT_CONFIG_PATH}")
fi
if [ -f "${INPUT_ADDITIONAL_CONFIG}" ]
then
    command=$(arg "${command}" '--additional-config=%s' "${INPUT_ADDITIONAL_CONFIG}")
fi
command=$(arg "${command}" '--format=%s' "${INPUT_FORMAT}")
command=$(arg "${command}" '--redact' "${INPUT_REDACT}")
command=$(arg "${command}" '--verbose' "${INPUT_VERBOSE}")
command=$(arg "${command}" '--debug' "${INPUT_DEBUG}")
command=$(arg "${command}" '--report=%s' "${GITHUB_WORKSPACE}/gitleaks-report.${INPUT_FORMAT}")

if [ "${#INPUT_NO_GIT}" = 0 ]
then
    command=$(arg "${command}" '--branch=%s' "${INPUT_BRANCH}")
    command=$(arg "${command}" '--depth=%s' "${INPUT_DEPTH}")
fi

if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]
then
    git --git-dir="${GITHUB_WORKSPACE}/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/${GITHUB_BASE_REF}... > "${GITHUB_WORKSPACE}/commits.txt"
    if [ $? -eq 1 ]
    then
        echo "::error::git log fails"
        exit 1
    fi
    command=$(arg "${command}" '--path=%s' "${GITHUB_WORKSPACE}")
    command=$(arg "${command}" '--commits-file=%s' "${GITHUB_WORKSPACE}/commits.txt")
else
    command=$(arg "${command}" '--path=%s' "${INPUT_PATH}")
    command=$(arg "${command}" '--no-git' "${INPUT_NO_GIT}")
fi

echo "Running gitleaks $(gitleaks --version)"
echo "----------------------------------"
echo "${command}"
echo "::set-output name=command::${command}"
COMMAND_OUTPUT=$(eval "${command}")

if [ $? -eq 1 ]
then
    echo "----------------------------------"
    echo "${COMMAND_OUTPUT}"
    echo "::set-output name=exitcode::1"
    echo "::set-output name=output::${COMMAND_OUTPUT}"
    echo "::set-output name=report::gitleaks-report.${INPUT_FORMAT}"
    GITLEAKS_RESULT="STOP! Gitleaks encountered leaks or error"
    echo "::set-output name=result::${GITLEAKS_RESULT}"
    if [ "${INPUT_FAIL}" = "true" ]
    then
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
    echo "::set-output name=report::gitleaks-report.${INPUT_FORMAT}"
    GITLEAKS_RESULT="SUCCESS! Your code is good to go"
    echo "::set-output name=result::${GITLEAKS_RESULT}"
    echo "::notice::${GITLEAKS_RESULT}"
fi