---
name: read_gerrit_cl
description: Fetch and display the full patch/diff or comments for a Gerrit CL.
---

# Instructions

Use this skill to inspect a Gerrit Change List (CL).
This is useful for reviewing code changes, understanding the scope of a modification, checking comments.

## Requirements

The following command-line tools are required:

- `curl`: For making HTTP requests.
- `jq`: For parsing JSON (needed for comments).
- `base64`: For decoding patch content (needed for patches).

## Scripts

### 1. Read Patch

Run the `read_patch.sh` script to fetch the unified diff of a CL.

#### Usage

```bash
./scripts/read_patch.sh <change_number> [patchset]
```

#### Arguments

1.  `change_number`: The numeric ID of the Gerrit change (e.g., `12345`).
2.  `patchset` (optional): The patchset number or `current` (default).

#### Example

To fetch the patch for CL 12345 (latest revision):

```bash
./scripts/read_patch.sh 12345
```

To fetch a specific revision (e.g. patchset 2):

```bash
./scripts/read_patch.sh 12345 2
```

The output will be the unified diff format of the patch.

### 2. Read Comments

Run the `read_comments.sh` script to fetch the comments on a CL.

#### Usage

```bash
./scripts/read_comments.sh <change_number>
```

#### Arguments

1.  `change_number`: The numeric ID of the Gerrit change (e.g., `12345`).

#### Example

To fetch comments for CL 12345:

```bash
./scripts/read_comments.sh 12345
```

The output will be a JSON object containing the comments.
