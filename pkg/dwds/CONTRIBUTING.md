## Local Development

### With Flutter tools (recommended)

1. Fork and download the [Flutter repo](https://github.com/flutter/flutter).
   Detailed instructions can be found
   [here](https://github.com/flutter/flutter/wiki/Setting-up-the-Framework-development-environment).
1. Add an alias to your `.bashrc`/`.zshrc` for Flutter Tools:

```
alias flutter_tools_debug='/YOUR_PATH/flutter/bin/dart --observe /YOUR_PATH/flutter/packages/flutter_tools/bin/flutter_tools.dart'
alias flutter_tools='/YOUR_PATH/flutter/bin/dart /YOUR_PATH/flutter/packages/flutter_tools/bin/flutter_tools.dart'
```

> **Explanation:**
>
> - `/PATH_TO_YOUR_FLUTTER_REPO/bin/dart`: This is the path to the Dart SDK that
>   Flutter Tools uses
> - `--observe`: This flag specifies we want a Dart DevTools URL for debugging.
> - `/PATH_TO_YOUR_FLUTTER_REPO/packages/flutter_tools/bin/flutter_tools.dart`:
>   This is the path to Flutter Tools itself
>
> _More details can be found at the Flutter Tools
> [README](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/README.md)._

3. In your Flutter Tools
   [`pubspec.yaml`](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/pubspec.yaml),
   change the DWDS dependency to point to your local DWDS:

```
  dwds:
    path: /YOUR_PATH/dwds
```

Note: This is even easier if you create a `pubspec_overrides.yaml` file in the `flutter_tools` directory, and then git-ignore it. This way you don't have to worry about committing your DWDS override.

4. Choose a Flutter app to run (such as the
   [Flutter Gallery app](https://github.com/flutter/flutter/tree/master/dev/integration_tests/flutter_gallery).
1. From the Flutter app repo, run your local Flutter Tools with alias you
   defined in step #2:

If you want a DevTools URL:

```
flutter_tools_debug run -d chrome
```

If you don't want a DevTools URL:

```
flutter_tools run -d chrome
```

Note: `flutter_tools_debug` can be a bit of a pain, because the app starts paused and you have to first open the DevTools URL and resume before you can do anything. Therefore, when you don't need to set breakpoints you should run `flutter_tools` instead of `flutter_tools_debug`.

6. If running with `flutter_tools_debug`, open up the **first** Dart DevTools URL you see printed:

```
...
The Dart VM service is listening on http://127.0.0.1:8181/ajXIPMLq6iI=/
The Dart DevTools debugger and profiler is available at: http://127.0.0.1:8181/ajXIPMLq6iI=/devtools/#/?uri=ws%3A%2F%2F127.0.0.1%3A8181%2FajXIPMLq6iI%3D%2Fws   <== THIS ONE!
Launching lib/main.dart on Chrome in debug mode...
...
```

7. The Dart DevTools you open is connected to your Flutter Tools, but because of
   the path dependency added in step #3, you can debug your local DWDS as well.

### With WebDev

Follow instructions in the `webdev/example` [README](/example/README.md) to run
the example app and connect to DWDS.

## Changes required when submitting a PR

- Make sure you update the `CHANGELOG.md` with a description of the change, or use
  the 'changelog-not-required' label to mark that the PR doesn't need a `CHANGELOG.md`
  entry.
- If DWDS / Webdev was just released, then you will need to update the version
  in the `CHANGELOG`, and the `pubspec.yaml` file as well (eg,
  https://github.com/dart-lang/webdev/pull/1462)
- For any directories you’ve touched, run `dart run tool/build.dart` to
  check in any file that should be built. This will make sure the integration
  tests are run against the built files.

## g3 Rolls

DWDS is rolled automatically into g3 along with the Dart SDK. For more information, or to learn how to handle breaking changes, see go/roll-dwds.

## Release steps

## Step 1: Publish DWDS to pub

- From the `/tool` directory in the mono-repo root, run: `dart run release.dart -p dwds`
- Submit a PR with those changes (example PR: https://github.com/dart-lang/webdev/pull/1456)
- Once the PR is submitted, go to https://github.com/dart-lang/webdev/releases and create a new
  release, eg https://github.com/dart-lang/webdev/releases/tag/dwds-v12.0.0. This should trigger
  the auto-publisher. Verify that the package is published.
- From the `/tool` directory in the mono-repo root, run: `dart run release.dart --reset -p dwds -v <<new version tag>>` where the new version tag is the next minor version postfixed with `-wip` ([example PR](https://github.com/dart-lang/webdev/pull/2267/files))
- Submit a PR with those changes.

> _Note: To have the right permissions for publishing, you need to be invited to
> the tools.dart.dev. A member of the Dart team should be able to add you at
> https://pub.dev/publishers/tools.dart.dev/admin._

## Step 2: Publish Webdev to pub

> _Note: DWDS is a dependency of Webdev, which is why DWDS must be published
> before Webdev can be published._

Follow instructions in the `webdev/webdev`
[CONTRIBUTING](/webdev/CONTRIBUTING.md) to release Webdev.

## Whenever the Dart SDK is updated

Whenever Dart SDK is updated to a new major or minor version (~every 2 weeks),
any PR submissions to Webdev are blocked by the min_sdk_test until the Dart min
SDK constraint is updated. Therefore, whenever your PR gets blocked by the test,
you need to:

1. Create a new PR that updates all the min SDK constraints to the new version,
   eg: https://github.com/dart-lang/webdev/pull/1463.
1. From each of the subdirectories (`/dwds`, `/frontend_server_client`,
   and `/webdev`) update dependencies with
   `dart pub upgrade`
1. Make sure to update the `CHANGELOG` to include the new version number
1. Submit your PR. At this point, you technically will be able to submit the PR
   that was blocked, but the point of the test is to make sure that DWDS and
   Webdev get released after a Dart stable release. Therefore, follow the steps
   above to publish DWDS and Webdev.

> ### Why is this necessary?
>
> This is so that we don’t need to support older versions of the SDK and test
> against them, therefore every time the Dart SDK is bumped to a new major or
> minor version, DWDS and Webdev’s min Dart SDK constraint needs to be
> changed and DWDS and Webdev have to be released. Since DWDS is dependent on
> DDC and the runtime API, if we had a looser min constraint we would need to
> run tests for all earlier stable releases of the SDK that match the
> constraint, which would have differences in functionality and therefore need
> different tests.

## Hotfixes

Sometimes you might need to do a hotfix release of DWDS. An example of why this
might be necessary is if you need to do a hotfix of DWDS into Flutter, but don't
want to release a new version of DWDS with the current untested changes on the
`main` branch. Instead you only want to apply a fix to the current version of
DWDS in Flutter.

### Instructions:

1. Create a branch off the release that needs a hotfix:

   a. In the GitHub UI's
   [commit history view](https://github.com/dart-lang/webdev/commits/main),
   find the commit that prepared the release of DWDS that you would like to
   hotfix.

   b. Click on `< >` ("Browse the repository at this point in history").

   c. At the top-left, you should see the commit hash in a dropdown. Click the
   dropdown, and type in a name for your hotfix branch (e.g.
   `16.0.2-hotfix-release`). Then select "Create branch `16.0.2-hotfix-release`
   from `commit_hash`".

   d. From your local clone of DWDS, run `git fetch upstream`. (_Note: this
   assumes you have already configured git to sync your fork with the `upstream`
   repository. If you haven't, follow
   [these instructions](https://docs.github.com/en/get-started/quickstart/fork-a-repo#configuring-git-to-sync-your-fork-with-the-upstream-repository).)_

   e. Search for the branch that you just created, e.g.
   `git branch -a | grep 16.0.2-hotfix-release` f. Track that branch with
   `git checkout --track branch_name` (e.g.
   `remotes/upstream/16.0.2-hotfix-release`)

1. Update the CI tests so that the branch tests against the appropriate Dart
   SDKs:

   a. Make the appropriate changes to DWDS' `mono_pkg.yaml` then run
   `mono_repo generate`. Submit this change to the branch you created in step
   #3, **not** `main`.

1. Make the fix:

   a. You can now make the change you would like to hotfix. From the GitHub UI,
   open a PR to merge your change into the branch you created in step #3,
   **not** `main`. See https://github.com/dart-lang/webdev/pull/1867 as an
   example.

1. Once it's merged, you can follow the instructions to
   [publish DWDS to pub](#step-2-publish-dwds-to-pub), except instead of pulling
   from `main`, pull from the branch your created in step #3.

1. If necessary, open a cherry-pick request in Flutter to update the version.
   See https://github.com/flutter/flutter/issues/118122 for an example.
