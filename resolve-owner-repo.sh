set -euo pipefail

if [ "${INPUTS_DEBUG:-false}" = "true" ]; then
    KAMIDANA_OPTINOS+=(--debug)
    set -x
fi

if [ -n "${INPUTS_GIT_URL:-}" ]; then
    gh repo view "${INPUTS_GIT_URL}" --json owner,name --template 'owner={{ .owner.login }}{{ printf "\n"  }}repo={{ .name }}' >> "${GITHUB_OUTPUT}"
    return
fi

if [ -n "${INPUTS_OWNER:-}" ]; then
    echo "owner=${INPUTS_OWNER}" >> "${GITHUB_OUTPUT}"
else
    echo "owner=${GITHUB_REPOSITORY_OWNER}" >> "${GITHUB_OUTPUT}"
fi

if [ -n "${INPUTS_REPO:-}" ]; then
    echo "repo=${INPUTS_REPO}" >> "${GITHUB_OUTPUT}"
else
    echo "repo=${GITHUB_REPOSITORY#"${GITHUB_REPOSITORY_OWNER}"/}" >> "${GITHUB_OUTPUT}"
fi
