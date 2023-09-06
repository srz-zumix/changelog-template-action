#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="${INPUTS_OWNER:-${1:-}}"
REPO_NAME="${INPUTS_REPO:-${2:-}}"
COMMIT_FROM="${INPUTS_FROM:-${3:-}}"
COMMIT_TO="${INPUTS_TO:-${4:-}}"

if [ "${INPUTS_DEBUG:-false}" = "true" ]; then
    set -x
fi

COMMIT_COUNT=$(gh api \
  "/repos/${REPO_OWNER}/${REPO_NAME}/compare/${COMMIT_FROM}...${COMMIT_TO}" \
  --jq .total_commits)

# shellcheck disable=SC2016
TO_OID=$(gh api graphql -F owner="${REPO_OWNER}" -F repo="${REPO_NAME}" -F sha="${COMMIT_TO}" -F query='
query($owner: String!, $repo: String!, $sha: String!) {
  repository(owner: $owner, name: $repo) {
    object(expression: $sha) {
      ... on Commit {
        oid
      }
    }
  }
}
' --jq '.data.repository.object.oid')

START_CURSOR="${TO_OID} ${COMMIT_COUNT}"
REQUEST_COUNT=$(("${COMMIT_COUNT}"<100 ? "${COMMIT_COUNT}":100))

# Note
# gh api --paginate detect endCursor, using a trick to make endCursor an alias for startCursor
# shellcheck disable=SC2016
gh api graphql --paginate -F owner="${REPO_OWNER}" -F repo="${REPO_NAME}" -F to="${COMMIT_TO}" -F count="${REQUEST_COUNT}" -F endCursor="${START_CURSOR}" -F query='
query($owner: String!, $repo: String!, $to: String!, $count: Int!, $endCursor: String) {
  repository(owner: $owner, name: $repo) {
    object(expression: $to) {
      ... on Commit {
        history(last: $count, before: $endCursor) {
          pageInfo {
            endCursor: startCursor
            hasNextPage
          }
          nodes {
            associatedPullRequests(first: 1) {
              edges {
                node {
                  assignees(first: 10) {
                    nodes {
                      ... Account
                    }
                  }
                  author {
                    ... Account
                  }
                  baseRefName
                  body
                  bodyText
                  closed
                  closedAt
                  createdAt
                  headRefName
                  headRepository {
                    name
                  }
                  labels(first: 10) {
                    nodes {
                      name
                      description
                    }
                  }
                  mergeCommit {
                    oid
                  }
                  merged
                  mergedAt
                  mergedBy {
                    ... Account
                  }
                  milestone {
                    title
                    description
                  }
                  number
                  permalink
                  reviews(first: 10) {
                    nodes {
                      author {
                        ... Account
                      }
                      state
                    }
                  }
                  state
                  title
                  url
                  updatedAt
                }
              }
            }
          }
        }
      }        
    }
  }
}

fragment Account on User {
  company
  email
  login
  name
} 
' --jq '.data.repository.object.history.nodes[].associatedPullRequests.edges[].node' | jq -s 'unique_by(.number) | reverse | { pull_requests: . }'
