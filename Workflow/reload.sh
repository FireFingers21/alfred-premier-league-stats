#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 8m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Get season standings
mkdir -p "${seasonDir}"
curl -sf --compressed --connect-timeout 10 -L "https://sdp-prem-prod.premier-league-prod.pulselive.com/api/v5/competitions/8/seasons/${seasonYear}/standings?live=false" -o "${seasonDir}/standings.json" && downloadStatus=1

if [[ -n "${downloadStatus}" ]]; then
    set -o extendedglob
    if [[ -f "${seasonDir}/standings.json" && ! -n ${seasonDir}/icons/*.png(#qNY1) ]]; then
        # Get Team Logos
        mkdir -p "${seasonDir}/icons"
        teamIds=$(jq -r --arg seasonYear "${seasonYear:2}" '[.tables[].entries[].team.id] | join(",")' "${seasonDir}/standings.json")
        curl -sf --compressed --parallel --output-dir "${seasonDir}/icons" -L "https://resources.premierleague.com/premierleague${seasonYear:2}/badges/{${teamIds}}.svg" -o "#1.svg"
        for file in ${seasonDir}/icons/*.svg; do
            sips -s format png -o "${file%.svg}.png" --resampleHeight 256 -p 256 256 "${file}" >/dev/null && rm "${file}"
        done
    fi
    touch "${alfred_workflow_data}"
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi