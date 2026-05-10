# macOS Publisher

A skill that automates notarizing macOS apps with Apple and creating professional, drag-installable DMGs for distribution outside the App Store.

## What It Does

**Complete workflow in 6 phases:**
1. Validate code signing
2. Prepare DMG contents (app + Applications symlink)
3. Create DMG disk image
4. Submit to Apple Notary Service
5. Staple notarization ticket
6. Package final ZIP for distribution

Result: A professional `.zip` file ready to ship, with a DMG that users drag-install in one click.

## Usage

### Manual Approach (Using SKILL.md)

Read [`SKILL.md`](SKILL.md) for the complete 6-phase workflow with detailed instructions.

### Automated Approach (Using Script)

```bash
bash scripts/notarize.sh /path/to/MyApp.app MyApp /output/dir
```

**Example:**
```bash
bash scripts/notarize.sh ~/projects/TodoApp/build/TodoApp.app TodoApp ~/releases/
# Output: ~/releases/TodoApp-notarized.zip
```

## Prerequisites

- macOS with Xcode Command Line Tools installed
- Developer ID certificate (Apple Developer Program)
- Apple ID with app-specific password
- Team ID (10-character alphanumeric code)

**Setup (one time):**
```bash
xcrun notarytool store-credentials apple-notary \
  --apple-id your@email.com \
  --app-password xxxx-xxxx-xxxx-xxxx \
  --team-id ABC123DEF4
```

## Files

- **SKILL.md** — Complete skill reference (6 phases, 300+ lines)
- **scripts/notarize.sh** — Automated bash script
- **evals/evals.json** — Test cases for evaluation
- **iterations/** — Test results and benchmarks

## Quick Troubleshooting

| Problem | Fix |
|---------|-----|
| "codesign -v" fails | App not signed. Sign with: `codesign --force --deep --sign "Developer ID Application: YourName (TEAMID)" /path/to/app.app` |
| Notarization rejected | Check Apple's logs: `xcrun notarytool log <submission-id> --keychain-profile apple-notary` |
| DMG has no Applications folder | Symlink failed. Run script again. |
| Users see Gatekeeper warning | Staple wasn't applied. Verify: `xattr -l app.dmg \| grep com.apple.provenance` |

## Testing

3 test cases included in `evals/evals.json`:
1. Basic notarization with existing keychain profile
2. Validation of unsigned apps
3. Full setup from credential creation

See `iterations/iteration-1/benchmark.md` for test results.

## Skill Status

✅ RED phase (baseline) complete  
✅ GREEN phase (with skill) complete  
✅ Benchmark: 82% shorter responses than without skill  
⏳ Ready for integration into Claude Code

## Contributing

To improve this skill, run the test cases and update:
1. SKILL.md (workflow)
2. evals/evals.json (test cases)
3. Create new iteration directory with results

## Author

Created for freeflew | macOS app distribution automation
