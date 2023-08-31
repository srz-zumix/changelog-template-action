#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="${INPUTS_OWNER:-$1}"
REPO_NAME="${INPUTS_REPO:-$2}"
COMMIT_FROM="${INPUTS_FROM:-$3}"
COMMIT_TO=${INPUTS_TO:-$4}

if [ "${INPUTS_DEBUG:-false}" = "true" ]; then
    KAMIDANA_OPTINOS+=(--debug)
    set -x
fi

COMMIT_COUNT=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/compare/${COMMIT_FROM}...${COMMIT_TO}" \
  --jq .total_commits)

gh api graphql -F owner="${REPO_OWNER}" -F repo="${REPO_NAME}" -F to="${COMMIT_TO}" -F count="${COMMIT_COUNT}" -F query='
query($owner: String!, $repo: String!, $to: String!, $count: Int!) {
  repository(owner: $owner, name: $repo) {
    object(expression: $to) {
      ... on Commit {
        history(first: $count) {
          nodes {
            message
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
' --jq '.data.repository.object.history.nodes[].associatedPullRequests.edges[].node' | jq -s 'unique_by(.number) | { pull_requests: . }'
