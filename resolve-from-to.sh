#!/usr/bin/env bash
set -euo pipefail

EXIT_CODE=0

if [ "${INPUTS_DEBUG:-false}" = "true" ]; then
    KAMIDANA_OPTINOS+=(--debug)
    set -x
fi

TARGET_REPO="${INPUTS_OWNER}/${INPUTS_REPO}"

resolve_to() {
    if [ -n "${INPUTS_TO:-}" ]; then
        echo "to=${INPUTS_TO}" >> "${GITHUB_OUTPUT}"
        return
    fi
    if [ "${TARGET_REPO}" == "${GITHUB_REPOSITORY}" ]; then
        if [ -n "${GITHUB_HEAD_REF}" ]; then
            echo "to=${GITHUB_HEAD_REF}" >> "${GITHUB_OUTPUT}"
            return
        fi
        if [ -n "${GITHUB_REF_NAME}" ]; then
            echo "to=${GITHUB_REF_NAME}" >> "${GITHUB_OUTPUT}"
            return
        fi
    fi

    echo "::error:: Failed to get end of changelog range. Specify it explicitly in \"to\" inputs."
    EXIT_CODE=1
}

resolve_from() {
    if [ -n "${INPUTS_FROM:-}" ]; then
        echo "from=${INPUTS_FROM}" >> "${GITHUB_OUTPUT}"
        return
    fi

    PREV_RELEASE_TAG_NAME=
    if [ "${GITHUB_EVENT_NAME}" == "release" ]; then
        TARGET_COMMITISH=$(jq -r '.release.target_commitish' < "${GITHUB_EVENT_PATH}")
        PREV_RELEASE_TAG_NAME=$(gh api "/repos/${TARGET_REPO}/releases" --jq ".[] | select(.target_commitish == \"${TARGET_COMMITISH}\") | .tag_name" | head -n 2 | tail -1)
    else
        if [ "${TARGET_REPO}" == "${GITHUB_REPOSITORY}" ]; then
            TARGET_COMMITISH_LIST=("${GITHUB_BASE_REF}" "refs/heads/${GITHUB_BASE_REF}" "${GITHUB_REF_NAME}" "${GITHUB_REF}")
            for TARGET_COMMITISH in "${TARGET_COMMITISH_LIST[@]}"; do
                if [ -n "${TARGET_COMMITISH}" ] && [ -z "${PREV_RELEASE_TAG_NAME}" ]; then
                    PREV_RELEASE_TAG_NAME=$(gh api "/repos/${TARGET_REPO}/releases" --jq ".[] | select(.target_commitish == \"${TARGET_COMMITISH}\") | .tag_name" | head -1)
                fi
            done
        else
            PREV_RELEASE_TAG_NAME=$(gh api "/repos/${TARGET_REPO}/releases/latest" --jq ".tag_name")
        fi
    fi

    if [ -n "${PREV_RELEASE_TAG_NAME}" ]; then
        echo "from=${PREV_RELEASE_TAG_NAME}" >> "${GITHUB_OUTPUT}"
        return
    fi

    echo "::error:: Failed to get end of changelog range. Specify it explicitly in \"from\" inputs."
    EXIT_CODE=1
}

resolve_to
resolve_from

exit ${EXIT_CODE}
