---
name: find-release-for-commit
description: Find which Dart/Flutter releases contain a specific commit sha.
---

# Instructions

Use this skill to determine which releases a specific commit SHA (Dart or Flutter) first appeared in.
This is useful for identifying the earliest SDK version that includes a given feature, fix, or change.

## Tool Usage

Run the `tools/find_release.dart` script from the root of the SDK  (`../../../` relative to this file) to discover the releases for a given commit SHA.

```bash
dart tools/find_release.dart --commit=<sha> --channel=<channel>
```

### Arguments

1.  `--commit=<sha>` (required): The SHA of the commit.
2.  `--channel=<dev|beta|stable>` (required): The channel to search in.

### Example

To find which releases contain commit `abcdef123...` on the `stable` channel:

```bash
dart tools/find_release.dart --commit=abcdef123... --channel=stable
```

The output will include:

- Whether the commit was found in the Dart or Flutter repository.
- The lowest (earliest) git release tag containing that commit.
- The corresponding official Flutter release (if found).
- The corresponding official Dart SDK release (if found).

## Important Considerations

- **Git Tags vs. Official Releases**: The tool first identifies the lowest git tag that includes the commit. However, the presence of a tag (especially a `-dev` tag) **does not guarantee that an official SDK release has being published for that version.**
- **Verification**: You should look for the "Lowest Dart release" or "Lowest Flutter release" in the tool's output to confirm that the commit has actually reached a released state. If the tool reports "No Dart releases found that were newer than <tag>", then the commit has not yet reached any official released version on that channel.
- **Reporting**: When communicating the findings, distinguish clearly between the git tag it first appeared in and the earliest official release (if any).
