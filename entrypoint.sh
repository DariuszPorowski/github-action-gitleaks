#!/bin/bash

# declare INPUT_PATH=""
# declare INPUT_CONFIG_PATH=""
# declare INPUT_ADDITIONAL_CONFIG=""
# declare INPUT_FORMAT=""
# declare INPUT_BRANCH=""
# declare INPUT_NO_GIT=""
# declare INPUT_REDACT=""
# declare INPUT_DEPTH=""
# declare INPUT_FAIL=""
# declare INPUT_VERBOSE=""
# declare INPUT_DEBUG=""

# while getopts ":p:c:a:f:b:n:r:i:x:v:d:" args
# do
#     case "${args}" in
#         p)
#             INPUT_PATH=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         c)
#             INPUT_CONFIG_PATH=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         a)
#             INPUT_ADDITIONAL_CONFIG=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         f)
#             INPUT_FORMAT=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         b)
#             INPUT_BRANCH=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         n)
#             INPUT_NO_GIT=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         r)
#             INPUT_REDACT=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         i)
#             INPUT_DEPTH=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         x)
#             INPUT_FAIL=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         v)
#             INPUT_VERBOSE=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         d)
#             INPUT_DEBUG=$(echo "${OPTARG}" | awk '{$1=$1}1')
#         ;;
#         \?)
#             echo "Invalid options found: "${OPTARG}"."
#             exit 1
#         ;;
#     esac
# done
# shift $((OPTIND - 1))

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
if [ "${#INPUT_FORMAT}" = 0 ]
then
    INPUT_FORMAT="json"
fi
command=$(arg "${command}" '--format=%s' "${INPUT_FORMAT}")
command=$(arg "${command}" '--redact' "${INPUT_REDACT}")
command=$(arg "${command}" '--verbose' "${INPUT_VERBOSE}")
command=$(arg "${command}" '--debug' "${INPUT_DEBUG}")
command=$(arg "${command}" '--report=%s' "gitleaks-report.${INPUT_FORMAT}")

if [ "${#INPUT_NO_GIT}" = 0 ]
then
    command=$(arg "${command}" '--branch=%s' "${INPUT_BRANCH}")
    command=$(arg "${command}" '--depth=%s' "${INPUT_DEPTH}")
fi

if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]
then
    git --git-dir="${GITHUB_WORKSPACE}/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/${GITHUB_BASE_REF}... > commits.txt
    if [ $? -eq 1 ]
    then
        echo "::error::git log fails"
        exit 1
    fi
    command=$(arg "${command}" '--commits-file=%s' "commits.txt")
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
    echo "::set-output name=exitcode::1"
    echo "----------------------------------"
    echo "${COMMAND_OUTPUT}"
    echo "::set-output name=output::${COMMAND_OUTPUT}"
    echo "----------------------------------"
    echo "::set-output name=report::gitleaks-report.${INPUT_FORMAT}"
    echo "----------------------------------"
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
    echo "::set-output name=exitcode::0"
    echo "----------------------------------"
    echo "::set-output name=report::gitleaks-report.${INPUT_FORMAT}"
    echo "----------------------------------"
    GITLEAKS_RESULT="SUCCESS! Your code is good to go!"
    echo "::set-output name=result::${GITLEAKS_RESULT}"
    echo "::notice::${GITLEAKS_RESULT}"
fi