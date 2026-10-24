# Lastbench

Lastbench is a local rotation bench for runners who keep two or more pairs. You match two lasts, log each outing as miles, and watch cost-per-mile move against the rest of the pairs you own.

## Architecture

The bench is a Match fold with four phases: Bare, Open, Matched, and Divided. An empty library is Bare. Lasts without a pair are Open. Match writes a MatchMark (`leftLastID`, `rightLastID`) and folds Open to Matched. Mile appends a MileMark on the tapped last, recomputes cost-per-mile as `(price - disposal) / max(distance, 1)`, and stays Matched. When both lasts have at least four mile marks and are at least fourteen days old, the fold files a VerdictChip for the lower cost-per-mile last and becomes Divided.

That shape fits this product because the home action is pairwise, not a list of receipts. The pair is the aggregate. Refusals are marks too: Mile on Open writes a SkidMark, and a second Match while Matched writes a JamMark and is refused. Peel drops the latest MileMark. Grades (A+ through F) are percentiles inside a library of at least five lasts that are at least seven days old. Fewer peers, or a younger last, is insufficient data.

`CompareBenchFold` is pure. `CompareBenchSession` is the main-actor snapshot the chrome will bind. `CompareLedgerStore` is the only persistence seam: one `CompareRootRecord` under `lsb.compare.root.v1`, mirrored to an atomic file in Application Support, with a debounced save after each mark.

## Why this app

Match, then mile. A split verdict appears only after both lasts have earned four outings and fourteen days. You can see which pair is actually cheaper per mile, not which one you bought most recently.

## Art

Style: documentary geometric pattern tile. Image sets are reserved and filled in a later pass: `lsb_Onboarding1`, `lsb_Onboarding2`, `lsb_Onboarding3`, `lsb_EmptyHome`, `lsb_TwistHero`, `lsb_EmptyRotationCutout`, `lsb_VerdictBadgeCutout`.

Base prompt:

Documentary geometric pattern tile aesthetic with crisp architectural precision, repeating interlocking track-lane and sole-tread tessellations, stark editorial contrast, and clean die-cut silhouettes with true transparent alpha boundaries where needed.

`lsb_Onboarding1`: base prompt, a person or object that is this product in one glance.

`lsb_Onboarding2`: base prompt, the primary action of this product, mid-gesture.

`lsb_Onboarding3`: base prompt, a later moment when the product has accumulated meaning.

`lsb_EmptyHome`: base prompt, a solid closed bowl, crate or folded cloth waiting to be used, ceramic, wood or fabric, fully opaque.

`lsb_TwistHero`: base prompt, an emblem representing this app's signature feature.

`lsb_EmptyRotationCutout`: Die-cut geometric cobbler last and track lane tessellation emblem in a documentary athletic style, solid center subject with crisp angular facets and a fully transparent PNG background.

`lsb_VerdictBadgeCutout`: Sharp geometric split-chevron verdict medallion crafted from interlocking documentary pattern tiles, solid central form with clean outer edges on a transparent PNG background.

## Difference

Same cost-per-use family as a wear log, with a different verb: mile a matched pair on a split bench, then a pairwise VerdictChip. No letter-grade quorum, no catalog scan, no remote product lookup.

## Build

```
cd apps/Lastbench
xcodegen generate
xcodebuild build-for-testing -scheme Lastbench -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```
