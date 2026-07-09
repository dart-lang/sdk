> [!warning]
> **Google Summer of Code 2021 is no longer accepting applications**.

---

A list of Google Summer of Code project ideas for Dart.

For GSoC related discussions please use the [dart-gsoc group](https://groups.google.com/forum/#!forum/dart-gsoc).

**Potential mentors**
 * `jonasfj@google.com`
 * `dacoharkes@google.com`
 * `jwren@google.com`

## Project Application Process
All projects assume familiarity with Dart (and sometimes Flutter). Aspiring applicants are encouraged to [learn Dart](https://dart.dev/guides/language/language-tour) and try to write some code.

Applicants are welcome to find and fix bugs in [Dart](https://github.com/dart-lang/sdk) or some of the [packages written by the Dart team](https://pub.dev/publishers/dart.dev/packages). However, getting reviews can take a long time as code owners may be busy working on new features. So instead of requiring applicants to fix a _good first bug_, we
suggest that applicants write a working code sample relevant for the proposed project.

The code sample can be attached to the application as a [gist](https://gist.github.com/), or simply GitHub repository. Suggested ideas below includes proposed "Good Sample Projects".

**Do not spend too much energy on this piece of sample code**, we just want to see
that you can code something relevant -- and that this sample code can run and do something non-trivial. Be aware that we have a limited number of
mentors available, and will only be able to accept a few applicants.

Applications can be submitted through the [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/) website. Students are encouraged to submit draft proposals, ideally linking to a Google Docs with permission for mentors to comment. See also the [student guide](https://google.github.io/gsocguides/student/writing-a-proposal) on writing a proposal.

**IMPORTANT**: Remember to submit _final proposals_ before [the April 13th deadline](https://summerofcode.withgoogle.com/how-it-works/#timeline).

----

## **Idea:** IntelliJ Live Templates

 - **Possible Mentor(s)**: `jwren@google.com`
 - **Difficulty**: medium
 - **Skills**: Dart, Flutter, Java

**Description**:

Curate and implement live templates in the Flutter and Dart IntelliJ plugins.  After this, the candidate may work in other feature areas of the Dart and Flutter IntelliJ plugin stack.

**Good Sample Project**
To start follow the directions here, https://github.com/flutter/flutter-intellij/blob/master/CONTRIBUTING.md, to get the Flutter plugin for IntelliJ compiling and running locally from source.  Review the current set of provided templates here in these files in GitHub, then review the feature in other languages and frameworks with an eye on having our live templates feel consistent with IntelliJ.

----

## **Idea:** Standalone pub-server

 - **Possible Mentor(s)**: `jonasfj@google.com`
 - **Difficulty**: medium
 - **Skills**: dart, http, html, css, jwt,

**Description**:
Write a standalone pub server following the [hosted pub repository specification](https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md). Goal could be to allow vendors to host private pub repositories for commercial packages, and/or facilitate internally mirroring of pub.dev for organizations with outgoing network restrictions. In addition to implementing a server, certain tweaks to the `pub` tool might be required for authentication with 3rd party servers.

**Good Sample Project**
Figure out how to make a webserver in Dart using [shelf](https://pub.dev/packages/shelf),
workout how to render HTML templates, convert Dart to JS for use client-side,
handle REST requests and generally familiarize yourself with the Dart server stack.
A hello world server than can serve files from disk, show some HTML and handle a simple REST request in JSON would be a good sample project.

----

## **Idea:** Extends git source in `pubspec.yaml` to understand tags

 - **Possible Mentor(s)**: `jonasfj@google.com`
 - **Difficulty**: advanced
 - **Skills**: dart, git-wizardry,

**Description**:
Currently, `pubspec.yaml` can contain
[git dependencies](https://dart.dev/tools/pub/dependencies#git-packages).
However, `pub` does not support walking through the list of tags in a git repository
and finding all versions of the `pubspec.yaml` in the repository. Hence, a git
dependency always has exactly one version. What if `pub` could find all versions
of a package from a git repository, and use those versions in the solver.

**Good Sample Project**
Explore existing support for `git` dependencies in Dart, figure out how to work
with `--references` in git repositories, as well as commands for listing a
specific file `pubspec.yaml` from various tags in a repository. Explore to what
extend tags and files can be listed remotely without downloading
the entire repository.
A good sample project, might be able to output `pubspec.yaml` for all tags in `git` given a specific git repository and path to `pubspec.yaml`.

----

## **Idea:** SPDX license detection package

 - **Possible Mentor(s)**: `jonasfj@google.com`
 - **Difficulty**: easy
 - **Skills**: Dart programming skills; text parsing.


**Description**:
Write a Dart package for detecting SPDX license from a `LICENSE` file following
the [SPDX License List Matching Guidelines](https://spdx.org/spdx-license-list/matching-guidelines)
or text similarity like [licensee](https://github.com/licensee/licensee) does.
A goal would be properly represent the license of a package on pub.dev with an
SPDX identifier.
Stretch goal might be to handle `LICENSE` files with multiple licenses and
display an SPDX license expression on pub.dev.

**Getting Started**
Try writing a small sample program that can fetch one of the [SPDX origin files](https://github.com/spdx/license-list-XML/tree/main/src) and print it to terminal as
markdown. Don't make it too perfect, just figure out how to parse the XML.
For the proposal, it would be valuable to include:
 * Comparison of text similarity approach to SPDX matching guidelines,
 * References to relevant documentation.
 * A discussion of strategies for handling complicated cases with multiple
   licenses in the same file.
 * An API outline for the package, what does the function signatures look like?
 * List of features you would consider adding? what are the stretch goals? What
   should be omitted to keep it simple/robust?
 * How do we plan to test this? What test cases can we find? How can we become
   reasonably confident the implementation handles all corner cases?

----

## **Idea:** Build a Cronet-based HTTP package with `dart:ffi` and `package:ffigen`

 - **Possible Mentor(s)**: `dacoharkes@google.com`, `mannprerak2@gmail.com`
 - **Difficulty**: advanced
 - **Skills**: Dart, `dart:ffi`, API design, HTTP

**Description**:
With `dart:ffi` binding to native libraries we have an opportunity to build more performant and more feature rich IO libraries than `dart:io`.
Building such libraries has become one step easier by [`package:ffigen`](https://pub.dev/packages/ffigen) which can generate the bindings for the native libraries.
In this project we would like to target HTTP by binding to Cronet's [native API](https://chromium.googlesource.com/chromium/src/+/main/components/cronet/native/test_instructions.md).

This project will be challenging.
It requires the whole `dart:ffi` toolbox. For example: native resource management with finalizers and asynchronous callbacks with native ports.
Moreover, we might run into the limitations of Dart and `dart:ffi`, such as not being able to choose which thread the Dart executor thread runs on.
This knowledge will be valuable in shaping future work on `dart:ffi`.

**Good Sample Project**
Try writing a small web server in Dart with `dart:io` [tutorial](https://dart.dev/tutorials/server/httpserver), and replace the `dart:io` HTTP use with your own HTTP class which uses Cronet underneath with `dart:ffi` and `package:ffigen`.
You can go one step further by comparing the performance compared to `dart:io`, or using an HTTP feature that's not enabled in `dart:io`.



----

## Template for additional ideas

```md
## **Idea:** {{title}}

 - **Possible Mentor(s)**: `{{email}}`
 - **Difficulty**: {{easy | medium | advanced}}
 - **Skills**: {{keyword}}; ...

**Description**:
{{description}}

**Good Sample Project**
{{how to get started; good first bugs; ideas for code samples; warm-up exercises}}

----
```
