#!/bin/zsh --no-rcs

currentSeason="$(curl -sf --compressed --connect-timeout 10 "https://www.premierleague.com/en/tables" --stderr - | grep -E "data-season-id=\"[0-9]{4}\"")"

if [[ -n "${currentSeason}" ]]; then
    # Get standings for current/selected season
    season="${currentSeason//[^0-9]/}"
    seasonDir="${alfred_workflow_data}/${season}"
    mkdir -p "${seasonDir}"
    curl -sf --compressed "https://sdp-prem-prod.premier-league-prod.pulselive.com/api/v5/competitions/8/seasons/${season}/standings?live=false" -o "${seasonDir}/standings.json"
    set -o extendedglob
    if [[ -f "${seasonDir}/standings.json" && ! -n ${seasonDir}/icons/*.png(#qNY1) ]]; then
        # Get Team Logos
        mkdir -p "${seasonDir}/icons"
        teamIds=($(jq -r --arg currentSeason "${${currentSeason//[^0-9]/}:2}" '"https://resources.premierleague.com/premierleague\($currentSeason)/badges/" + .tables[].entries[].team.id + ".svg"' "${seasonDir}/standings.json"))
        curl -sf --compressed --parallel --output-dir "${seasonDir}/icons" --remote-name-all -L "${teamIds[@]}"
        for file in ${seasonDir}/icons/*.svg; do
            sips -s format png -o "${file%.svg}.png" --resampleHeight 256 -p 256 256 "${file}" >/dev/null && rm "${file}"
        done
    fi
    echo -nE "${season}" > "${alfred_workflow_data}/currentSeason.txt"
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi