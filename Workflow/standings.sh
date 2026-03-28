#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 8m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${alfred_workflow_data}/${seasonYear}" ]] && reload=$(./reload.sh)

# Get season files
standings_file="${seasonDir}/standings.json"
icons_dir="${seasonDir}/icons"

# Load Standings
jq -s \
   --arg icons_dir "${icons_dir}" \
   --arg favTeam "${(L)favTeam}" \
'{
    "variables": {
        "seasonYear": "'${seasonYear}'",
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
}' "${standings_file}"