---
name: update-native-rev
description: Updates the native_rev dependency in the DEPS file with all correct verification, sync, and testing procedures
---

<!-- Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
     for details. All rights reserved. Use of this source code is governed by a
     BSD-style license that can be found in the LICENSE file. -->

# Instructions

Use this skill when you are requested to roll or update the `native_rev` variable (the hash of `third_party/pkg/native` repository) in the `DEPS` file.

## 0. Initial Synchronization

Before beginning the roll, **ask the user** if the SDK git repository should be switched to the `main` branch and synchronized.
If they confirm, run:
```bash
git checkout main && git pull && gclient sync -D -f
```

## 1. Commit Selection Rules

> [!IMPORTANT]
> **CRITICAL RULE**: NEVER EVER pick a local commit or a commit from a custom branch/PR branch. You MUST only pick remote commits that have already landed on the remote `main` branch.

To select the correct commit SHA:
1. **Ask the user** if the newest hash/commit should be taken directly from **GitHub** (e.g., if the googlesource mirror is lagging behind or the desired change is only on GitHub main).
   * **If the user says YES**:
     1. First, temporarily change the repository URL and host permissions in the `DEPS` file by following the instructions in the **[Troubleshooting Sync Failures](#troubleshooting-sync-failures)** section (changing `third_party/pkg/native` under `deps` to use `"https://github.com/dart-lang/native.git"` and adding `'github.com'` to `allowed_hosts` in `DEPS`).
     2. Run `gclient sync` from the SDK root to update the checkout mapping to GitHub.
     3. Navigate to the `native` package subdirectory: `third_party/pkg/native`.
     4. Run `git fetch origin` to fetch the latest commits from the GitHub remote (origin will now point to GitHub).
     5. After checking commits, **immediately set the repository URL and host permissions in `DEPS` back to googlesource** (reverting the changes made in sub-step 1), so that subsequent steps and the final commit only roll the commit hash without permanently keeping GitHub host settings.
   * **If the user says NO / default**:
     1. Proceed with the default mirrored googlesource setup.
     2. Navigate to the `native` package subdirectory: `third_party/pkg/native`.
     3. Run `git fetch origin` to fetch the latest commits from the mirror.
2. Inspect the commits on remote `origin/main` of the `native` repository:
   ```bash
   git log origin/main -n 10 --oneline
   ```
3. Obtain the full SHA of the newest commit on remote `origin/main` (or the specific one that contains the required change):
   ```bash
   git rev-parse origin/main
   ```
4. **Revert Host to GoogleSource**:
   * **IMPORTANT**: If the host was set to GitHub, you **MUST** now revert the repository URL and allowed hosts changes in the `DEPS` file back to the mirrored googlesource URL, removing `github.com` from `allowed_hosts`. Do this before updating `native_rev` so that the final committed change only rolls the commit hash, not checkout hosts.

## 2. Updating DEPS and Synchronizing

1. Locate `native_rev` in the `DEPS` file (typically under `vars`):
   ```python
   "native_rev": "<old_sha>", # rolled manually while record_use is experimental
   ```
2. Replace the hash with the chosen remote `origin/main` commit SHA.
3. If not already done in step 4 above, ensure the `DEPS` host and URL configuration are reverted to the googlesource mirror, leaving only the updated `native_rev` hash.
4. Run `gclient sync -f` from the SDK root directory to update the checkout of the dependencies and regenerate the package configuration using the mirror.

### Troubleshooting Sync Failures
If the synchronization fails because of host restrictions:
1. Temporarily modify the repository configuration under `deps` in `DEPS` to use:
   `https://github.com/dart-lang/native.git` as the git repo.
2. Temporarily add `'github.com'` to the `allowed_hosts` list in `DEPS`.
3. Re-run `gclient sync -f` to complete the update.
4. **IMPORTANT**: Immediately after successful syncing, revert the host and URL changes in the `DEPS` file, removing `github.com` from `allowed_hosts` and returning to the mirrored googlesource URL, but keep the newly synced native commit hash.

## 3. Mandatory Testing and Verification

Before completing the update, you must run the following tests:

### Native Assets Package Tests
Build the target SDK and run the primary native asset tests:
```bash
RBE_exec_strategy=racing tools/build.py -mrelease create_sdk runtime ffi_test_functions runtime_precompiled && tools/test.py -n unittest-asserts-release-mac-arm64 pkg/dartdev/test/native_assets/
```

### Record Use Optimization Tests
Since `record_use` integrates closely with `native_rev` updates, these tests must be validated for both backends (Wasm and VM).

1. Build the required target backends and run all record use tests:
   ```bash
   RBE_exec_strategy=racing tools/build.py -mrelease create_sdk dart2wasm runtime ffi_test_functions runtime_precompiled && xcodebuild/ReleaseARM64/dart-sdk/bin/dart pkg/compiler/test/record_use/record_use_test.dart && xcodebuild/ReleaseARM64/dart-sdk/bin/dart pkg/dart2wasm/test/record_use_test.dart && xcodebuild/ReleaseARM64/dart-sdk/bin/dart pkg/vm/test/transformations/record_use_test.dart
   ```
2. **Updating Expectations**:
   > [!IMPORTANT]
   > If the record_use tests fail, **DO NOT** update the expectations automatically. You **MUST** first ask the user for confirmation/permission and clarify if updating expectations is the correct course of action.

   If the user confirms that the expectations should be updated to match the new behavior:
   * Run the test command with `-DupdateExpectations=true`:
     ```bash
     RBE_exec_strategy=racing tools/build.py -mrelease create_sdk dart2wasm runtime ffi_test_functions runtime_precompiled && xcodebuild/ReleaseARM64/dart-sdk/bin/dart pkg/compiler/test/record_use/record_use_test.dart -DupdateExpectations=true && xcodebuild/ReleaseARM64/dart-sdk/bin/dart pkg/dart2wasm/test/record_use_test.dart -DupdateExpectations=true && xcodebuild/ReleaseARM64/dart-sdk/bin/dart pkg/vm/test/transformations/record_use_test.dart -DupdateExpectations=true
     ```
   * **Note**: Always run the VM test one last when updating expectations. The expect files are stored in the VM directory.
3. **Running Individual Tests**:
   To debug or verify a single test:
   ```bash
   python3 tools/test.py -n wasm-unittest-asserts-mac pkg/dart2wasm/test/record_use_test.dart
   ```

## 4. Pre-Completion Protocol

Follow these final validation steps before announcing completion:

1. **Format touched files**: Run `dart format` on all modified Dart files.
2. **Analyze touched files**: Run `dart analyze` to ensure there are no lint or static analysis issues.
3. **Presubmit checks**: Run `git cl presubmit` to ensure build/format sanity.
4. **Update Coverage (Front-End changes only)**:
   If any related changes were also introduced in the `front_end` directory, regenerate test coverage:
   ```bash
   dart --enable-asserts pkg/front_end/test/coverage_suite.dart --tasks=5 --add-and-remove-comments
   ```
   * *Critical*: Revert the coverage comment changes in any files that you did not otherwise modify.

## 5. Branching and Committing

After all tests pass and formatting/analysis is clean:
1. **Ask the user** if they want to create a roll branch and commit the changes.
2. If confirmed, get the current date in `YYYYMMDD` format (e.g., `20260630`) and run:
   ```bash
   git new-branch roll-<YYYYMMDD>
   git commit -a -m "[deps] Roll dart-lang/native"
   ```
