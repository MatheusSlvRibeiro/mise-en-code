#!/usr/bin/env bash
# Move an issue's card to a Status column on the GitHub Project linked to this repo.
# Adds the issue to the Project first if it is not there yet.
# Usage: move-card.sh <issue-number> <Backlog|Ready|"In progress"|"In Review"|Done>
set -eo pipefail

issue="${1:?usage: move-card.sh <issue-number> <status>}"
status="${2:?usage: move-card.sh <issue-number> <status>}"

read -r owner repo < <(gh repo view --json owner,name --jq '"\(.owner.login) \(.name)"')
# shellcheck disable=SC2016  # $o and $r are GraphQL variables, not shell ones
number=$(gh api graphql \
  -f query='query($o:String!,$r:String!){repository(owner:$o,name:$r){projectsV2(first:1){nodes{number}}}}' \
  -f o="$owner" -f r="$repo" --jq '.data.repository.projectsV2.nodes[0].number // empty')
[ -n "$number" ] || { echo "No GitHub Project is linked to $owner/$repo." >&2; exit 1; }

project_id=$(gh project view "$number" --owner "$owner" --format json --jq .id)
fields=$(gh project field-list "$number" --owner "$owner" --format json)
field_id=$(jq -r '.fields[] | select(.name == "Status") | .id' <<<"$fields")
option_id=$(jq -r --arg s "$status" '
  .fields[] | select(.name == "Status") | .options[]
  | select((.name | ascii_downcase) == ($s | ascii_downcase)) | .id' <<<"$fields")
if [ -z "$option_id" ]; then
  echo "Unknown status '$status'. Options: $(jq -r '.fields[] | select(.name == "Status") | [.options[].name] | join(", ")' <<<"$fields")" >&2
  exit 1
fi

item_id=$(gh project item-list "$number" --owner "$owner" --limit 500 --format json |
  jq -r --argjson n "$issue" --arg repo "$owner/$repo" '
    .items[] | select(.content.number == $n and (.content.repository // "") == $repo) | .id' | head -n 1)
if [ -z "$item_id" ]; then
  item_id=$(gh project item-add "$number" --owner "$owner" \
    --url "https://github.com/$owner/$repo/issues/$issue" --format json --jq .id)
fi

gh project item-edit --id "$item_id" --project-id "$project_id" \
  --field-id "$field_id" --single-select-option-id "$option_id" >/dev/null
echo "#$issue -> $status"
