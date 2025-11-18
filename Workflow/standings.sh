#!/bin/zsh --no-rcs

# Auto Update
[[ -f "${alfred_workflow_data}/currentSeason.txt" ]] && [[ "$(date -r "${alfred_workflow_data}/currentSeason.txt" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" ]] && reload=$(./reload.sh)

# Get files for current season
currentSeason="$(< "${alfred_workflow_data}/currentSeason.txt")"
standings_file="${alfred_workflow_data}/${currentSeason}/standings.json"
icons_dir="${alfred_workflow_data}/${currentSeason}/icons"

# Load Standings
jq -s \
   --arg icons_dir "${icons_dir}" \
   --arg favTeam "${(L)favTeam}" \
'{
    "variables": {
        "currentSeason": "'${currentSeason}'",
        "standings_file": "'${standings_file}'",
        "icons_dir": "'${icons_dir}'"
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		.[].tables[].entries | map({
			"title": "\(.overall.position)  \(.overall | if (.position < .startingPosition) then "↑" elif (.position > .startingPosition) then "↓" else "↔" end)  \(.team.name)",
			"subtitle": "Pl: \(.overall.played)    W: \(.overall.won)    D: \(.overall.drawn)    L: \(.overall.lost)    GF: \(.overall.goalsFor)    GA: \(.overall.goalsAgainst)    GD: \(.overall.goalsFor - .overall.goalsAgainst)        Pts: \(.overall.points)",
			"icon": { "path": "\($icons_dir)/\(.team.id).png" },
			"text": { "copy": .team.name },
			"variables": { "teamId": .team.id, "teamName": .team.name }
		}) | [(.[] | select((.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
		| [(.[] | if ((.variables.teamName|ascii_downcase) == $favTeam) then (.title |= .+"  ★") end)]
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${standings_file}"