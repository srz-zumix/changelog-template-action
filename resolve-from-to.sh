#!/usr/bin/env bash
set -euo pipefail

EXIT_CODE=0

cd "${INPUTS_PATH}"

TARGET_REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

resolve_to() {
    if [ -n "${INPUTS_TO:-}" ]; then
        echo "to=${INPUTS_TO}" >> "${GITHUB_OUTPUT}"
        return
    fi
    if [ -n "${GITHUB_REF_NAME}" ]; then
        echo "to=${GITHUB_REF_NAME}" >> "${GITHUB_OUTPUT}"
        return
    fi

    echo "::error:: Failed to get end of changelog range. Specify it explicitly in \"to\" inputs."
    EXIT_CODE=1
}

resolve_from() {
    if [ -n "${INPUTS_FROM:-}" ]; then
        echo "from=${INPUTS_FROM}" >> "${GITHUB_OUTPUT}"
        return
    fi

    if [ "${GITHUB_EVENT_NAME}" == "release" ]; then
        TARGET_COMMITISH=$(jq -r '.release.target_commitish' < "${GITHUB_EVENT_PATH}")
        PREV_RELEASE_TAG_NAME=$(gh api "/repos/${TARGET_REPO}/releases" --jq ".[] | select(.target_commitish == '${TARGET_COMMITISH}') | .tag_name" | head -2 | tail -1)
    else
        if [ "${TARGET_REPO}" == "${GITHUB_REPOSITORY}" ]; then
            if [ -n "${GITHUB_REF_NAME}" ]; then
                TARGET_COMMITISH="${GITHUB_REF_NAME}"
                PREV_RELEASE_TAG_NAME=$(gh api "/repos/${TARGET_REPO}/releases" --jq ".[] | select(.target_commitish == '${TARGET_COMMITISH}') | .tag_name" | head -1)
            fi
        else
            PREV_RELEASE_TAG_NAME=$(gh api "/repos/${TARGET_REPO}/releases/latest" --jq ".[].tag_name")
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
