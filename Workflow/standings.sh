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
		.[].tables[].entries | map(((.team.name|ascii_downcase) == $favTeam) as $isFavourite | {
			"title": "\(.overall.position)  \(.overall | if (.position < .startingPosition) then "↑" elif (.position > .startingPosition) then "↓" else "↔" end)  \(.team.name)  \(if ((.team.name|ascii_downcase) == $favTeam) then "★" else "" end)",
			"subtitle": "Pl: \(.overall.played)    W: \(.overall.won)    D: \(.overall.drawn)    L: \(.overall.lost)    GF: \(.overall.goalsFor)    GA: \(.overall.goalsAgainst)    GD: \(.overall.goalsFor - .overall.goalsAgainst)        Pts: \(.overall.points)",
			"icon": { "path": "\($icons_dir)/\(.team.id).png" },
			"text": { "copy": .team.name },
			"variables": { "favTeamNew": .team.name, "teamId": .team.id, "teamName": .team.name, "seq": .overall.position },
			"mods": {
				"cmd+shift": {"subtitle": "⇧⌘↩ \(if ($isFavourite) then "Unset" else "Set" end) Favourite Team"}
			}
		}) | [(.[] | select((.variables.seq != 1) and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${seasonDir}/standings.json"