Want to contribute? Great! First, read this page (including the small print at the end).

## Ways you can contribute

You can help the Dart project in many ways, in addition to contributing code. For example, you can [report bugs](https://dartbug.com), ask and answer [Dart questions on StackOverflow](https://stackoverflow.com/questions/tagged/dart), and improve the documentation.

If you'd like to improve the documentation, you have three options:

  * Give us feedback:
    * If you're looking at a page with a **bug icon** at the **upper right**,
      click that icon to report a bug on the page.
    * To report an API doc bug,
      [create an SDK issue](https://github.com/dart-lang/sdk/issues/new?title=API%20doc%20issue:).
  * Contribute to the Dart developer websites such as [dart.dev](https://dart.dev) (repo: [dart-lang/site-www](https://github.com/dart-lang/site-www)) and [dart.dev/web](https://dart.dev/web) (repo: [dart-lang/site-webdev](https://github.com/dart-lang/site-webdev)). For more information, see [Writing for Dart and Flutter websites](https://github.com/dart-lang/site-shared/wiki/Writing-for-Dart-and-Flutter-websites).
  * Improve the API reference docs at [api.dart.dev](https://api.dart.dev) by editing doc comments in the [Dart SDK repo](https://github.com/dart-lang/sdk/tree/master/sdk/lib). For more information on how to write API docs, see [Effective Dart: Documentation](https://dart.dev/guides/language/effective-dart/documentation).

## Before you contribute

Before we can use your code, you must sign the [Google Individual Contributor License Agreement](https://developers.google.com/open-source/cla/individual) (CLA), which you can do online.  The CLA is necessary mainly because you own the copyright to your changes, even after your contribution becomes part of our codebase, so we need your permission to use and distribute your code.  We also need to be sure of various other things—for instance that you'll tell us if you know that your code infringes on other people's patents.  You don't have to sign the CLA until after you've submitted your code for review and a member has approved it, but you must do it before we can put your code into our codebase.

Before you start working on a larger contribution, you should get in touch with us first through the  [Dart Issue Tracker](https://dartbug.com) with your idea so that we can help out and possibly guide you. Coordinating up front makes it much easier to avoid frustration later on.

All submissions, including submissions by project members, require review.  We use the same code-review tools and process as the chromium project.  In order to submit a patch, you need to get the [depot\_tools](http://dev.chromium.org/developers/how-tos/depottools).

We occasionally take pull requests, e.g., for comment changes, but the main flow is to use the Rietveld review system as explained below.

## Getting the code

To work with the Dart code, you need to download and build the development branch. Active development of Dart takes place on the `master` branch, from which we push "green" versions that have passed all tests to `dev` branch. Complete instructions are found at [Getting The Source](https://github.com/dart-lang/sdk/wiki/Building#getting-the-source)

## Starting a patch with git

Note: you can be in any branch when you run `git new-branch`

```bash
git new-branch <feature name>
<write code>
git commit
<write code...>
git commit
...
```

## Keeping your branch updated with origin/master

As you work, and before you send a patch for review, you should
ensure your branch is merging cleanly to `origin/master`.

There are multiple ways to do this, but we generally recommend
running:

```bash
git rebase-update
```

Note: you can run this command from any branch.

This command will fetch
origin/master, rebase all your open branches, and delete
cleanly merged branches.

Your local workflow may vary.

## Uploading the patch for review

Upload the patch for review:

```bash
git cl upload -s
```

The above command returns a URL for the review. Attach this review to your issue in https://dartbug.com

If you have commit access, when the review is done and the patch is good to go, submit the patch on https://dart-review.googlesource.com:

```bash
git cl web # opens your review on https://dart-review.googlesource.com
```

*   Press "Submit to CQ" (CQ stands for "Commit Queue").
*   You can follow the progress by looking at the "Tryjobs" panel in your review.
*   Once the Commit Queue is green, the patch will be merged.
*   If any of the try jobs is red, you will have to fix the errors and then "Submit to CQ" once more.

If you do not have commit access, a Dart engineer will commit on your behalf, assuming the patch is reviewed and accepted.

More detailed instructions for the `git cl` tools available on https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_creating_uploading_a_cl

## For committers: Merging external contributions

If the author of a patch is not a committer, they will need help landing the patch.
Once a patch gets an LGTM, it's easy for a committer to merge it in.

* Find and open the review on https://dart-review.googlesource.com.
* Follow the instructions in the previous section to submit the patch.

## Coding style

The source code of Dart follows the:

  * [Google C++ style guide](https://google.github.io/styleguide/cppguide.html)
  * [Dart style guide](https://dart.dev/guides/language/effective-dart/style)

You should familiarize yourself with those guidelines.

All files in the Dart project must start with the following header. If you add a new file please also add this. The year should be a single number (not a range; don't use "2011-2012", even if the original code did).  If you edit an existing file you don't have to update the year

```dart
// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
```


## The small print

Contributions made by corporations are covered by a different agreement than the one above, the [Software Grant and Corporate Contributor License Agreement](https://cla.developers.google.com/about/google-corporate).

We pledge to maintain an open and welcoming environment. For details, see our [code of conduct](https://dart.dev/code-of-conduct).
