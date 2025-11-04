# <img src='Workflow/icon.png' width='45' align='center' alt='icon'> Premier League Stats

View the latest Premier League standings & stats in Alfred

## Setup

This workflow requires [jq](https://jqlang.github.io/jq/) to function, which comes preinstalled on macOS 15 Sequoia and later.

## Usage

View the latest [Premier League](https://www.premierleague.com) standings via the `pls` keyword. Type to filter by Team or Position.

![Using the pls keyword](Workflow/images/about/keyword.png)

* <kbd>↩</kbd> View Team Stats in Alfred.
* <kbd>⌘</kbd><kbd>↩</kbd> Open Team Stats in Browser.

Additional Team Stats can be viewed directly within Alfred. This includes Attack, Defence, Possession, Physical, and Discipline Stats.

![Viewing team stats in the Text View](Workflow/images/about/stats.png)

* <kbd>⌘</kbd><kbd>↩</kbd> Open in Browser.
* <kbd>⌥</kbd><kbd>↩</kbd> Refresh Team Stats.

Append `::` to the configured [Keyword](https://www.alfredapp.com/help/workflows/inputs/keyword) to access other actions, such as manually reloading the standings cache.

![Other actions](Workflow/images/about/inlineSettings.png)

Configure the [Hotkey](https://www.alfredapp.com/help/workflows/triggers/hotkey/) as a shortcut for viewing standings.