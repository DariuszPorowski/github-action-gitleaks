#!/bin/bash

declare INPUT_PATH=""
declare INPUT_CONFIG_PATH=""
declare INPUT_FORMAT=""
declare INPUT_NO_GIT=""
declare INPUT_REDACT=""
declare INPUT_DEPTH=""
declare INPUT_FAIL=""
declare INPUT_VERBOSE=""
declare INPUT_DEBUG=""

while getopts ":p:c:f:n:r:i:b:v:d:" args
do
    case ${args} in
        p)
            INPUT_PATH=${OPTARG}
        ;;
        c)
            INPUT_CONFIG_PATH=${OPTARG}
        ;;
        f)
            INPUT_FORMAT=${OPTARG}
        ;;
        n)
            INPUT_NO_GIT=${OPTARG}
        ;;
        r)
            INPUT_REDACT=${OPTARG}
        ;;
        i)
            INPUT_DEPTH=${OPTARG}
        ;;
        b)
            INPUT_FAIL=${OPTARG}
        ;;
        v)
            INPUT_VERBOSE=${OPTARG}
        ;;
        d)
            INPUT_DEBUG=${OPTARG}
        ;;
        \?)
            echo "Invalid options found: ${OPTARG}."
            exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

function arg(){
    local _command="${1}"
    local _format="${2}"
    local _val="${3}"
    
    if [ "${#_val}" = 0 ]
    then
        echo "${_command}"
        return
    fi
    _arg=$(printf " ${_format}" "${_val}")
    echo "${_command}${_arg}"
}

command="gitleaks"
if [ -f "${GITHUB_WORKSPACE}/${INPUT_CONFIG_PATH}" ]
then
    command=$(arg "${command}" '--config-path=%s' "${GITHUB_WORKSPACE}/${INPUT_CONFIG_PATH}")
fi
command=$(arg "${command}" '--format=%s' "${INPUT_FORMAT}")
command=$(arg "${command}" '--redact' "${INPUT_REDACT}")
command=$(arg "${command}" '--verbose' "${INPUT_VERBOSE}")
command=$(arg "${command}" '--debug' "${INPUT_DEBUG}")
command=$(arg "${command}" '--report=%s' "${GITHUB_WORKSPACE}/gitleaks-report.${INPUT_FORMAT}")

if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]
then
    git --git-dir="${GITHUB_WORKSPACE}/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/${GITHUB_BASE_REF}... > commits.txt
    command=$(arg "${command}" '--commits-file=%s' "${GITHUB_WORKSPACE}/commits.txt")
    command=$(arg "${command}" '--depth=%s' "${INPUT_DEPTH}")
    command=$(arg "${command}" '--path=%s' "${GITHUB_WORKSPACE}")
else
    command=$(arg "${command}" '--path=%s' "${INPUT_PATH}")
    command=$(arg "${command}" '--no-git' "${INPUT_NO_GIT}")
fi

echo "Running gitleaks $(gitleaks --version)"
echo "${command}"
CAPTURE_OUTPUT=$(eval "${command}")

if [ $? -eq 1 ]
then
    echo "----------------------------------"
    echo "::set-output name=exitcode::1"
    echo "----------------------------------"
    echo "${CAPTURE_OUTPUT}"
    echo "::set-output name=result::${CAPTURE_OUTPUT}"
    echo "----------------------------------"
    echo "::set-output name=report::${GITHUB_WORKSPACE}/gitleaks-report.${INPUT_FORMAT}"
    echo "----------------------------------"
    GITLEAKS_RESULT="STOP! Gitleaks encountered leaks or error"
    echo -e "\e[31m🛑 ${GITLEAKS_RESULT}"
    if [ "${INPUT_FAIL}" = "true" ]
    then
        echo "::error::${GITLEAKS_RESULT}"
        exit 1
    else
        echo "::warning::${GITLEAKS_RESULT}"
    fi
else
    echo "----------------------------------"
    echo "::set-output name=exitcode::0"
    echo "----------------------------------"
    echo "::set-output name=report::${GITHUB_WORKSPACE}/gitleaks-report.${INPUT_FORMAT}"
    echo "----------------------------------"
    GITLEAKS_RESULT="SUCCESS! Your code is good to go!"
    echo -e "\e[32m✅ ${GITLEAKS_RESULT}"
    echo "::notice::${GITLEAKS_RESULT}"
fi