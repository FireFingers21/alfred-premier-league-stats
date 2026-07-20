#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 8m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${alfred_workflow_data}/${seasonYear}" ]] && reload=$(./reload.sh)

# Load Standings
jq -cs \
   --arg alfred_workflow_keyword "${alfred_workflow_keyword}" \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
   --arg icons_dir "${seasonDir}/icons" \
   --arg seasonYear "${seasonYear}" \
'{
    "variables": {
        "keyword": $alfred_workflow_keyword,
        "icons_dir": $icons_dir,
        "seasonYear": $seasonYear
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		.[].tables[].entries | map({
			"title": "\(.overall.position)  \(.overall | if (.position < .startingPosition) then "↑" elif (.position > .startingPosition) then "↓" else "↔" end)  \(.team.name)",
			"subtitle": "Pl: \(.overall.played)    W: \(.overall.won)    D: \(.overall.drawn)    L: \(.overall.lost)    GF: \(.overall.goalsFor)    GA: \(.overall.goalsAgainst)    GD: \(.overall.goalsFor - .overall.goalsAgainst)        Pts: \(.overall.points)",
			"icon": { "path": "\($icons_dir)/\(.team.id).png" },
			"text": { "copy": .team.name },
			"variables": { "teamId": .team.id, "teamName": .team.name, "seq": .overall.position }
		}) | [(.[] | select((.variables.seq != 1) and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
		| [(.[] | if ((.variables.teamName|ascii_downcase) == $favTeam) then (.title |= .+"  ★") end)]
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${seasonDir}/standings.json"