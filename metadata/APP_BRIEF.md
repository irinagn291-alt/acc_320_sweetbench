<!-- gf-brief source=eb9dc9b871b7a3d16b689c01ffca75a3decbf408e8cf46237c7d67f0217d4897 written=2026-10-24T21:38:59+03:00 -->
# Sweetbench
## What it is
Sweetbench is a dark, on-device log for shoes a person already owns. They add each shoe with a purchase price and an optional disposal value, pair two shoes, and log the distance of each outing. The bench then shows a US-dollar cost per mile and, once both shoes have enough history, names the cheaper one.

## Launch and onboarding
Cold launch opens on a dimmed, non-tappable copy of the Mile screen. If loading takes a moment, a spinner appears over it. The first time, that gives way to a three-page introduction. Each page has a picture, a large capital headline, one sentence, "Skip", and a primary button.

1. Headline "PAIRS". "Log miles on shoes you own. See what each pair costs per mile." Primary button "Next".
2. Headline "MILE". "Pair two shoes, then log the distance from today's run." Primary button "Next".
3. Headline "SPLIT". "After four runs and fourteen days on both shoes, the bench names the cheaper pair." Primary button "Start".

"Skip" on any page, or "Start" on the last page, marks the introduction done and opens Mile. "Next" only advances the page. There is no account step and no permission prompt.

## Screens
There is no tab bar. Mile is the home screen. The other screens open as sheets from the "BENCH" list and each has a "Close" control at the top left.

### Mile
The title is the capital headline "MILE". Under it, one of these lines:

- "Closet empty. Add a shoe you own."
- "Unpaired. Pair two shoes, then log a mile."
- "Log today's distance on the left shoe."
- "Split filed. The cheaper shoe is named."

Two plates sit under that line. With nothing paired they are titled "Left shoe" and "Right shoe", each with the grade "Need peers" and "No miles yet." After a pair is filed, each plate uses that shoe's nickname, a grade chip, and a US-dollar figure followed by "per mile".

The distance row is labelled in capitals with the left shoe's nickname, or "LEFT SHOE" when none is paired. The field prompt is "Type miles". Beside it the unit reads "mi" or "km". The field uses a decimal keyboard. The keyboard bar says "Done" until the last field, which is not on this screen. "Done" dismisses the keyboard. Scrolling also dismisses it.

"Log mile" records the typed distance on the left shoe. The second button reads "Log right shoe", or "Log" plus the right shoe's nickname once one is paired, and records the same typed distance on the right shoe. A successful log clears the field and adds an outing. A refusal stays on screen as one of these sentences: "Mile refused. Pair two shoes first.", "Distance refused. Enter a number above zero.", or "Mile refused. That shoe is outside the pair." Both log buttons ignore taps for a brief moment after a tap.

If a split has been filed, a block labelled "SPLIT CALL" shows the lower US-dollar cost, the word "beats", the higher cost, and the cheaper shoe's nickname. If the name is missing it says "Cheaper shoe".

"LATEST OUTING" shows the newest shoe name, distance, and "mi" or "km", or "No outing yet." "Undo outing" removes the newest outing. It stays faded until at least one outing exists.

"BENCH" lists these rows. Each opens a sheet:

- "Closet"
- "Pair shoes"
- "Split call"
- "Ranks"
- "Outings"
- "Preferences"

### Closet
Title "Closet". "Close" dismisses it.

When the closet has no shoes, the empty state is "The closet is empty." and "Add a shoe you own." The button "Add shoe" reveals the form.

The form is titled "Add shoe" and has three fields: "Nickname", "Purchase price", and "Disposal value". The keyboard bar says "Next" on the first two fields and "Done" on the last. "Next" moves to the next field. "Done" dismisses the keyboard. "Save shoe" adds the shoe and clears the form. Refusals appear above the button: "Name refused. Enter a nickname.", "Price refused. Enter zero or more.", or "Disposal refused. Enter zero or more." A blank disposal value is saved as zero. Prices are zero or more. A nickname cannot be blank.

Each saved shoe shows its nickname, a US-dollar cost or the word "unknown", a grade chip, an age such as "12" then "days", the purchase price in US dollars, and "Archive". Archived shoes also say "Archived", stay in the list, and their "Archive" button is faded. Active shoes are listed before archived ones. "Archive" opens "Archive this shoe?" with "The shoe stays on this device and leaves the active closet.", "Archive shoe", and "Cancel". "Archive shoe" archives it. "Cancel" leaves it active.

If the closet cannot be read, the sheet shows "Closet failed. Try again.", a short note, and "Retry". "Retry" reloads. The notes are "Recovered the last good rotation.", "The rotation file could not be read. Starting empty.", "The rotation could not be saved. It stays on screen.", "Save wait ended early.", or "Reset could not remove a leftover rotation file."

### Pair shoes
Title "Pair shoes". "Close" dismisses it.

The headline is "Pair". The status line is "Choose two shoes. Then log miles." or, once a pair exists, "Bench already paired." A refusal replaces that line.

With fewer than two shoes, the empty state is "Need two shoes." and "Add a shoe you own." The button is "Close", which dismisses the sheet.

With two or more shoes, two capital headings, "LEFT SHOE" and "RIGHT SHOE", each list every shoe. A shoe's button reads "Choose" or "Selected". "Pair these" is faded until two different shoes are chosen and the bench is not already paired. Tapping it files the pair, then closes the sheet. After a pair exists, "Pair these" stays faded and "Pair again" appears. "Pair again" is tappable when two different shoes are chosen, but it does not replace the pair. The status becomes "Pair refused. Bench already paired." The other refusal is "Pair refused. Add two shoes first."

### Split call
Title "Split call". "Close" dismisses it.

The headline is "Split". The sentence is "Both shoes need four logged runs and fourteen days. Then the bench names the cheaper one."

With no pair, the empty state is "No pair yet." and "Pair two shoes on the bench." Its button is "Retry", which only reloads this sheet.

With a pair, each side is labelled "LEFT SHOE" or "RIGHT SHOE", then the nickname, a count "of" "4" "runs", and an age "of" "14" "days". "Log a run" or "Log a run on" plus the nickname of the shoe with fewer runs adds a distance of 1 on that shoe. If the counts match, it logs the left shoe. The button ignores taps for a brief moment after a tap. "Pair shoes" switches this sheet to the Pair shoes sheet.

When a split is filed, a block labelled "Cheaper" shows the lower US-dollar cost. A load problem shows the same notes as Closet, plus "Retry".

### Ranks
Title "Ranks". "Close" dismisses it.

The line is "Grades are relative to this closet." With no shoes, the empty state is "No ranks yet." and "Add a shoe you own." The button is "Retry", which only reloads.

Otherwise the first shoe is under "LOWEST COST", with its nickname, a US-dollar figure or "unknown", "per mile", and a grade chip. The remaining shoes follow, each with a nickname, a grade, and a cost or "unknown", ordered from lowest cost to highest. A load problem shows "Ranks failed. Try again.", the note, and "Retry".

### Outings
Title "Outings". "Close" dismisses it.

With no outings and no filed pairs, the empty state is "No outings yet." and "Log a mile on the bench." The button is "Close", which returns to Mile.

Otherwise the newest outing is under "NEWEST", with the shoe name, distance, "mi" or "km", and the date and time. Older outings follow with the same facts. "PAIRS FILED" lists each pair as the left name, "+", and the right name. "Undo outing" removes the newest outing and is faded when there is nothing to remove. A missing shoe name reads "Unknown". A load problem shows "Outings failed. Try again.", the note, and "Retry".

### Preferences
Title "Preferences". "Close" dismisses it.

If the closet is empty, the title line is "No shoes on the bench."

"DISTANCE UNIT" has "Miles" and "Kilometres". The active one is marked "Selected". The note is "Logged numbers stay as entered." Changing the unit changes the "mi" or "km" label. It does not convert numbers already logged. The app starts on miles.

"ARCHIVED SHOES" lists archived nicknames, or "No archived shoes."

"Show introduction" returns to the three-page introduction and keeps the closet, pair, and outings. "Contact support" leaves the app and opens the support page. "Delete rotation" opens "Delete every shoe and outing?" with "The closet, distances, and split call are removed from this device.", "Delete rotation", and "Cancel". Confirming removes the closet, distances, and split call from this device, closes Preferences, and shows the introduction again. A load problem shows "Preferences failed. Try again.", the note, and "Retry".

## Features
- Introduction with "Skip", "Next", and "Start", and "Show introduction" to see it again.
- Closet of shoes, each with a "Nickname", "Purchase price", and "Disposal value".
- "Archive" so a shoe leaves the active closet and stays on this device, marked "Archived".
- Pairing two shoes as the left shoe and the right shoe.
- Logging a distance with "Log mile" and "Log" plus the right shoe's name.
- "Undo outing" for the newest distance, from Mile and from Outings.
- US-dollar cost per mile on the paired shoes, in the closet, and in Ranks.
- Grade chips "Need peers", "A+", "A", "B", "C", "D", and "F".
- "Split call" after both shoes have four logged runs and fourteen days, naming the cheaper cost.
- "Ranks" ordered from lowest cost, with "Lowest cost" on the first shoe.
- "Outings" history and "Pairs filed".
- Distance unit "Miles" or "Kilometres", shown as "mi" or "km".
- "Delete rotation" to remove the closet, distances, and split call from this device.
- "Contact support".

## Behaviours that can look like bugs
- "Log mile" and the right-shoe log button can be tapped before a pair exists. The distance is not saved. The line is "Mile refused. Pair two shoes first." Pair two shoes, then log again.
- A blank, zero, or unreadable distance is refused with "Distance refused. Enter a number above zero." Enter a number above zero.
- After a pair is filed, "Pair these" stays faded. "Pair again" can be tapped, then says "Pair refused. Bench already paired." The first pair stays. There is no control that replaces it.
- "Undo outing" stays faded until an outing exists. Log a distance first. If there is nothing to remove, the line is "Undo refused. No outing to remove."
- "Save shoe" refuses a blank nickname, a negative or unreadable price, or an unreadable disposal value, with "Name refused. Enter a nickname.", "Price refused. Enter zero or more.", or "Disposal refused. Enter zero or more." A blank disposal value is accepted as zero.
- "Archive" is faded on a shoe that already says "Archived".
- The distance prompt stays "Type miles" after "Kilometres" is selected. The unit beside the field changes to "km". "Logged numbers stay as entered." Old numbers are not converted.
- Costs are always shown in US dollars, including when the device is outside the United States.
- A paired shoe can show a "per mile" dollar figure before any distance is logged. The figure is the purchase price minus the disposal value until a distance is logged. "No miles yet." is only shown on the unpaired "Left shoe" and "Right shoe" plates.
- Grade "Need peers" remains until five shoes are each at least seven days old. Shoes younger than seven days stay on "Need peers" even if the closet is large. Grades are only relative to this closet. Lower cost ranks higher. The bands are "A+", "A", "B", "C", "D", and "F".
- "Split call" does not name a cheaper shoe until both shoes show 4 of 4 runs and 14 of 14 days. "Log a run on" plus a nickname adds 1 to the shoe that is behind, which may not match a distance typed on Mile.
- On Split call, "No pair yet." offers "Retry", which reloads and does not open pairing. Use "Pair shoes" on Mile. On Ranks, "No ranks yet." offers "Retry", which does not open the closet. Use "Closet" and "Add shoe".
- Both log buttons, and "Log a run", ignore a second tap for a brief moment. They are not permanently disabled.
- "Delete rotation" also returns to the introduction.
- A new calendar day updates ages and can move a shoe from "Need peers" to a letter grade, or complete the fourteen-day side of a split, without a new outing.
- If saving fails, the current closet stays on screen and "The rotation could not be saved. It stays on screen." appears, with "Retry" on the sheet that failed.

## Starter content and resume
None on a device install. The closet starts empty and the introduction is shown. Shoes, the pair, distances, the split call, the distance unit, and whether the introduction is finished all come back on the next launch. A distance typed but not logged, and a half-filled "Add shoe" form, are not kept. "Undo outing" can remove the newest distance after it has been logged.

## Permissions
None.

## Absent
Login or accounts, in-app purchase, ads, analytics, user-generated content shared with anyone else, an account deletion flow, and an App Tracking Transparency prompt are all absent. "Delete rotation" removes the local closet only. There is no account to delete.

## Data and support
Shoes, prices, distances, the pair, the split call, and the distance unit stay on this device. "Contact support" on Preferences opens the support page. Archive copy says "The shoe stays on this device and leaves the active closet." Delete copy says "The closet, distances, and split call are removed from this device."

## Scanning and health
None. The app does not scan barcodes or QR codes. It does not show health, medical, or product-health information, and it has no citations. Cost per mile is a money figure for the shoes in the closet.

## Platform
English only. No region lock. Money is shown in US dollars. Distances use the device's decimal style and the chosen unit, "mi" or "km", starting on miles. The interface is dark. iPhone supports portrait and both landscapes. iPad supports portrait, upside down, and both landscapes. It runs on iPhone and iPad, full screen, and requires iOS 17.0.

## Category
Lifestyle.
