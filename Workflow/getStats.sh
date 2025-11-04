#!/bin/zsh --no-rcs

readonly currentSeason="$(< "${alfred_workflow_data}/currentSeason.txt")"
readonly stats_file="${alfred_workflow_data}/${currentSeason}/stats/${teamId}.json"
readonly icons_dir="${alfred_workflow_data}/${currentSeason}/icons"

# Get age of stats_file in minutes
[[ -f "${stats_file}" ]] && minutes="$((($(date +%s)-$(date -r "${stats_file}" +%s))/60))"

# Download Stats Data
if [[ "${forceReload}" -eq 1 || "$(date -r "${stats_file}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -f "${stats_file}" ]]; then
    # Rate limit to only refresh if data is older than 1 minute
    if [[ "${minutes}" -gt 0 || -z "${minutes}" ]]; then
        mkdir -p "${alfred_workflow_data}/${currentSeason}/stats"
        curl -sf --compressed --connect-timeout 10 -L "https://sdp-prem-prod.premier-league-prod.pulselive.com/api/v2/competitions/8/seasons/${currentSeason}/teams/${teamId}/stats" -o "${stats_file}" && minutes=0
    fi
fi

# Format Last Updated Time
if [[ ! -f "${stats_file}" || ${minutes} -eq 0 ]]; then
    lastUpdated="Just now"
elif [[ ${minutes} -eq 1 ]]; then
    lastUpdated="${minutes} minute ago"
elif [[ ${minutes} -lt 60 ]]; then
    lastUpdated="${minutes} minutes ago"
elif [[ ${minutes} -ge 60 && ${minutes} -lt 120 ]]; then
    lastUpdated="$((${minutes}/60)) hour ago"
elif [[ ${minutes} -ge 120 && ${minutes} -lt 1440 ]]; then
    lastUpdated="$((${minutes}/60)) hours ago"
else
    lastUpdated="$(date -r "${stats_file}" +'%Y-%m-%d')"
fi

# Format Stats to Markdown
if [[ -f "${stats_file}" ]]; then
    mdOutput=$(jq -crs \
    '.[] | 40 as $spaces |
        "# "+.team.name,
        "\n**Games Played:** \(.stats.gamesPlayed//0|round)      ·      **Goals:** \(.stats.goals//0|round)      ·      **Goals Conceded:** \(.stats.goalsConceded//0|round)",
        (.stats |
        "\n***\n\n### Attack\n\n```",
        ("Goals:"|.+" "*($spaces-length))+(.goals//0|round|tostring),
        ("XG:"|.+" "*($spaces-length))+((.expectedGoals*100)//0|round/100|tostring),
        ("Shots:"|.+" "*($spaces-length))+((.shotsOnTargetIncGoals*2)//0|round|tostring),
        ("Shots On Target:"|.+" "*($spaces-length))+(.shotsOnTargetIncGoals//0|round|tostring),
        ("Shots On Target Inside the Box:"|.+" "*($spaces-length))+((.iboxBlocked+.iboxTarget)//0|round|tostring),
        ("Shots On Target Outside the Box:"|.+" "*($spaces-length))+((.oboxBlocked+.oboxTarget)//0|round|tostring),
        ("Touches in the Opposition Box:"|.+" "*($spaces-length))+(.touchesInOppBox//0|round|tostring),
        ("Penalties (Scored):"|.+" "*($spaces-length))+(.foulWonPenalty//0|round|tostring) + " ("+(.penaltyGoals//0|round|tostring)+")",
        ("Free Kicks (Scored):"|.+" "*($spaces-length))+(.freekickTotal//0|round|tostring) + " ("+(.setPiecesGoals//0|round|tostring)+")",
        ("Hit Woodwork:"|.+" "*($spaces-length))+(.hitWoodwork//0|round|tostring),
        ("Crosses (Completed %):"|.+" "*($spaces-length))+((.successfulCrossesOpenPlay+.unsuccessfulCrossesOpenPlay)//0|round|tostring) + " " +
        (((.successfulCrossesOpenPlay/(.successfulCrossesOpenPlay+.unsuccessfulCrossesOpenPlay))*100)//0|round|tostring|"("+.+"%)"),
        "```\n\n### Defence\n\n```",
        ("Interceptions:"|.+" "*($spaces-length))+(.interceptions//0|round|tostring),
        ("Blocks:"|.+" "*($spaces-length))+(.blocks//0|round|tostring),
        ("Clearances:"|.+" "*($spaces-length))+(.totalClearances//0|round|tostring),
        "```\n\n### Possession\n\n```",
        ("Passes:"|.+" "*($spaces-length))+(.totalPasses//0|round|tostring),
        ("Long Passes (Completed %):"|.+" "*($spaces-length))+((.successfulLongPasses+.unsuccessfulLongPasses)//0|round|tostring) + " " +
        (((.successfulLongPasses/(.successfulLongPasses+.unsuccessfulLongPasses))*100)//0|round|tostring|"("+.+"%)"),
        ("Corners Taken:"|.+" "*($spaces-length))+(.cornersTakenInclShortCorners//0|round|tostring),
        "```\n\n### Physical\n\n```",
        ("Dribbles (Completed %):"|.+" "*($spaces-length))+((.successfulDribbles+.unsuccessfulDribbles)//0|round|tostring) + " " +
        (((.successfulDribbles/(.successfulDribbles+.unsuccessfulDribbles))*100)//0|round|tostring|"("+.+"%)"),
        ("Duels Won:"|.+" "*($spaces-length))+(.duelsWon//0|round|tostring),
        ("Aerial Duels Won:"|.+" "*($spaces-length))+(.aerialDuelsWon//0|round|tostring),
        "```\n\n### Discipline\n\n```",
        ("Red Cards:"|.+" "*($spaces-length))+(.totalRedCards//0|round|tostring),
        ("Yellow Cards:"|.+" "*($spaces-length))+(.yellowCards//0|round|tostring),
        ("Fouls:"|.+" "*($spaces-length))+(.totalFoulsConceded//0|round|tostring),
        ("Offsides:"|.+" "*($spaces-length))+(.offsides//0|round|tostring),
        ("Own Goals:"|.+" "*($spaces-length))+(.ownGoalsAccrued//0|round|tostring),
        "```")
    ' "${stats_file}" | sed 's/\"/\\"/g')
else
    mdOutput='# '${teamName}'\n\n**Games Played:** \"N/A\"      ·      **Goals:** \"N/A\"      ·      **Goals Conceded:** \"N/A\"\n***\n*Unable to connect to Premier League stats*'
fi

# Output Formatted Stats to Text View
cat << EOB
{
    "variables": { "forceReload": 1 },
    "response": "${mdOutput//$'\n'/\n}",
    "footer": "Last Updated: ${lastUpdated}            ⌥↩ Update Now   ·   ⌘↩ Open in Browser"
}
EOB