> [!warning]
> **Google Summer of Code 2020 is no longer accepting applications**.

The list of accepted projects have been announced on [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/organizations/6544944065413120/).

------------------

A list of Google Summer of Code project ideas for Dart. Students are welcome
to invent additional proposals.

For GSoC related discussions please use the [dart-gsoc group](https://groups.google.com/forum/#!forum/dart-gsoc).

**Potential mentors**
 * `alan.knight@gmail.com`
 * `bkonyi@google.com`
 * `dacoharkes@google.com`
 * `jonasfj@google.com`
 * `redbrogdon@google.com`
 * `brettmorgan@google.com`

## Project Application Process
All projects assume familiarity with Dart (and sometimes Flutter). Aspiring applicants are encouraged to [learn Dart](https://dart.dev/guides/language/language-tour) and try to write some code.

Applicants are welcome to find and fix bugs in [Dart](https://github.com/dart-lang/sdk) or some of the [packages written by the Dart team](https://pub.dev/publishers/dart.dev/packages). However, getting reviews can take a long time as code owners may be busy working on new features. So instead of requiring applicants to fix a _good first bug_, we
suggest that applicants write a working code sample relevant for the proposed project.

The code sample can be attached to the application as a secret [gist](https://gist.github.com/).
Suggested ideas for code samples include:
 * A minimal Dart console program that uses `dart:ffi` to bind a simple C API.
   (Perhaps compress a string with brotli, or make an HTTP request with libcurl)
 * A small Flutter demo application..
 * A minimal Dart library that can parse something simple.
   (Perhaps a miniscule subset of YAML).
 * A minimal Dart console program that can print the size and filename of the
   first file in a USTAR tar archive (ignoring other tar extensions).
 * Check out the _getting started_ section for each idea, invent your own small demo,
   or ask the potential mentor.

**Do not spend too much energy on this piece of sample code**, we just want to see
that you can code something relevant. Be aware that we have a limited number of
mentors available, and will only be able to accept a few applicants.

Applications can be submitted through the [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/) website. Students are encouraged to submit draft proposals, ideally linking to a Google Docs with permission for mentors to comment. See also the [student guide](https://google.github.io/gsocguides/student/writing-a-proposal) on writing a proposal.

**IMPORTANT**: Remember to submit _final proposals_ before [the March 31st deadline](https://summerofcode.withgoogle.com/how-it-works/#timeline).

## **Idea:** Additional File Formats for intl_translation

 - **Possible Mentor(s)**: `alan.knight@gmail.com`
 - **Difficulty**: Medium to advanced
 - **Skills**: Dart; some parsing; some knowledge of internationalization helpful

**Description**:
The Dart [intl_translation](https://github.com/dart-lang/intl_translation) package supports the [ARB](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification) format for reading and writing text and translations. ARB is a simple format, as it is mostly a wrapper around the ICU [MessageFormat](http://userguide.icu-project.org/formatparse/messages#TOC-MessageFormat) syntax, but it is not widely used. It would be good to support one or more additional formats. It would also be good to allow users to add formats in their own packages, without modifying intl_translation. XLIFF is one obvious choice, both because it is widely used, and because it is quite a different format. XLIFF has a lot of flexibility, so we would want to look at it in the context of a particular usage, for example, iOS. But other formats are widely used as well.

**Getting Started**
Use intl and intl_translation to produce a small program that runs with translated messages, so you understand the workflow. The parsing is done using a grammar written in [petitparser](https://github.com/petitparser/dart-petitparser), take a look at that and try writing a simple grammar. Take a brief look at the ARB, MessageFormat and XLIFF (much larger) documentation.

For the proposal, it would be valuable to include:
 - References to the documentation for the format(s) to be supported.
 - An example of a complex message (e.g. a plural with several clauses) in both the existing format and in the other format(s)
 - Discussion of any changes that would need to be made in intl_translation to support writing these in a separate package.
 - Discussion of how to test the translation workflow.

----

## **Idea:** FFI Bindings generation from header files

 - **Possible Mentor(s)**: `dacoharkes@google.com`
 - **Difficulty**: Medium
 - **Skills**: Dart programming skills; C programming skills.

**Description**:
Write a (Dart) program that generates `dart:ffi` bindings from a .h-file.
A possible approach could be to use the FFI to bind to clang.
This would greatly reduce the amount of effort developers using `dart:ffi`
would have to do. For more info [dart-lang/sdk#35843](https://github.com/dart-lang/sdk/issues/35843).

**Getting Started**
Write a Dart package that binds to a native library of your choosing to familiarize yourself with Dart and using `dart:ffi`. On top of that you could write a small Dart app to showcase using that library.

----

## **Idea:** Flutter testing sample app

 - **Possible Mentor(s)**: `redbrogdon@google.com`, `brettmorgan@google.com`
 - **Difficulty**: Medium
 - **Skills**: Dart, Flutter coding skills.

**Description**:
One area in which the [Flutter samples repo](https://github.com/flutter/samples)
is lacking is automated testing. We've always wanted a sample app set up to
demonstrate the proper techniques for testing Flutter apps -- not so much the
testing philosophy involved, but the tech that powers Dart and Flutter's testing
architecture.
This project would involve creating a simple sample application for the repo,
and include unit, widget, and integration tests as the real prize. 

**Getting Started** Try creating a small sample using [DartPad](https://dartpad.dev/), the online editor for Flutter and Dart:

 * Think of something you found challenging when learning Dart or Flutter.
 * Think of a small sample (the smaller the better!) that could have been useful to you when you were learning.
   * Maybe a demo of Rows and Columns could have helped you learn how flex layouts work?
   * Maybe a Dart sample showing a StreamController would have helped you learn how Streams work?
 * Next, code your sample in DartPad and create a gist for it (see [this guide](https://github.com/dart-lang/dart-pad/wiki/Sharing-Guide)).
 * Finally, submit your gist ID to [Awesome DartPad](https://github.com/divyanshub024/awesome-dart-pad) so the whole world can learn from it.

----

## **Idea:** Platform channel sample app

 - **Possible Mentor(s)**: `redbrogdon@google.com`, `brettmorgan@google.com`
 - **Difficulty**: Advanced
 - **Skills**: Dart programming skills; C programming skills.

**Description**:
The [Flutter samples repo](https://github.com/flutter/samples) has a few apps
that touch on platform channels, but nothing dedicated to the topic.
A sample app that showed event channels, method channels, moving structured
data, and other related topics would be a welcome addition to the codebase.

**Getting Started** Try creating a small sample using [DartPad](https://dartpad.dev/), the online editor for Flutter and Dart:

 * Think of something you found challenging when learning Dart or Flutter.
 * Think of a small sample (the smaller the better!) that could have been useful to you when you were learning.
   * Maybe a demo of Rows and Columns could have helped you learn how flex layouts work?
   * Maybe a Dart sample showing a StreamController would have helped you learn how Streams work?
 * Next, code your sample in DartPad and create a gist for it (see [this guide](https://github.com/dart-lang/dart-pad/wiki/Sharing-Guide)).
 * Finally, submit your gist ID to [Awesome DartPad](https://github.com/divyanshub024/awesome-dart-pad) so the whole world can learn from it.

----

## **Idea:** Programmatic YAML modification package

 - **Possible Mentor(s)**: `jonasfj@google.com`
 - **Difficulty**: Easy to medium
 - **Skills**: Parsing; abstract-syntax-trees; programming skills in Dart or similar language.

**Description**:
Write a Dart package for programmatically modifying a YAML file while
preserving comments. Figuring out the exact data structure and API for
modification is part of this project, though inspiration may be drawn from
[package:yaml](https://github.com/dart-lang/yaml). The goal is to use this
for implementing a `pub add <package>` command, which modifies the
`pubspec.yaml` without throwing away comments.
Stretch goal might be to preserve as much whitespace and YAML style as possible.

**Getting Started**
Try writing a small sample program that can parse a tiny subset of YAML, or
maybe parse a formula like `a + b / (c - d)`, or find and fix a bug in [package:yaml](https://github.com/dart-lang/yaml) (maybe search internet for [YAML test vectors](https://github.com/yaml/yaml-test-suite), and use that to find bugs in `package:yaml`).
For the proposal, it would be valuable to include:
 * What are the challenges with mutating YAML?
 * What is the API for this going to look like? What kind of mutations will be
   possible?
 * How do we plan to test this? What test cases can we find? How can we become
   reasonably confident the implementation handles all corner cases?
 * How is the mutation logic made robust? Will we need fallback strategies? How
   will that work?

----

## **Idea:** TAR-stream reader package

 - **Possible Mentor(s)**: `jonasfj@google.com`
 - **Difficulty**: Advanced
 - **Skills**: Dart programming skills; reading binary data; man files.

**Description**:
Write a Dart package for reading tar archives as a stream of objects, similar
to the [golang API](https://golang.org/pkg/archive/tar/), and ideally being
able to read the same test cases. A critical aspect of a streaming tar-reader is the ability to read a tar-stream `Stream<List<int>>` as a stream of file-entries with sub-streams for reading the file contents, such that a reader can read each file as a stream (never loading an entire file into memory at once).
This involves reading [man-files](https://www.freebsd.org/cgi/man.cgi?query=tar&apropos=0&sektion=5&manpath=FreeBSD+7.0-RELEASE&arch=default&format=html),
and figuring out how to represent all objects (or throw them away).
A stretch goal would be to replace the use of native `tar`
in `pub` for reading and writing tar-files. This would naturally include being
able to read all packages on [pub.dev](https://pub.dev).

**Getting Started**
Try writing a small sample program that can print the file name and size of the
first file in a USTAR tar archive. Link to the sample in a secret gist attached
to the project proposal. For the proposal, it would be valuable to include:
 * References to relevant documentation of the various TAR formats.
 * An API outline for the streaming TAR reader package.
   (Explain how a program using the package would read a tar file).
 * List of TAR features you'd suggest supporting: what are the stretch goals,
   what features do we ignore, how do we expose these features.
   (From the perspective of `pub` we mostly care about ordinary files and folders).
 * How do we plan to test this? What test cases can we find? How can we become
   reasonably confident the implementation handles all corner cases?

----

## **Idea:** SPDX license detection package

 - **Possible Mentor(s)**: `jonasfj@google.com`
 - **Difficulty**: Medium
 - **Skills**: Dart programming skills; text parsing.

**Description**:
Write a Dart package for detecting SPDX license from a `LICENSE` file following
the [SPDX License List Matching Guidelines](https://spdx.org/spdx-license-list/matching-guidelines).
A goal would be properly represent the license of a package on pub.dev with an
SPDX identifier.
Stretch goal might be to handle `LICENSE` files with multiple licenses and
display an SPDX license expression on pub.dev.

**Getting Started**
Try writing a small sample program that can fetch one of the [SPDX origin files](https://github.com/spdx/license-list-XML/tree/main/src) and print it to terminal as
markdown. Don't make it too perfect, just figure out how to parse the XML.
For the proposal, it would be valuable to include:
 * References to relevant documentation.
 * A discussion of strategies for handling complicated cases with multiple
   licenses in the same file.
 * An API outline for the package, what does the function signatures look like?
 * List of features you would consider adding? what are the stretch goals? What
   should be omitted to keep it simple/robust?
 * How do we plan to test this? What test cases can we find? How can we become
   reasonably confident the implementation handles all corner cases?


----

## **Idea:** Flutter Background Execution - Media Player Example

 - **Possible Mentor(s)**: `bkonyi@google.com`
 - **Difficulty**: Medium
 - **Skills**: Dart, Java / Kotlin, Objective-C / Swift, Flutter programming skills; Android / iOS native development experience
 - **Additional Requirements**: Access to a Mac for iOS development

**Description**:
The Flutter repository is lacking any example applications which perform tasks that
require background execution. There have been multiple requests for a [sample media player
application](https://github.com/flutter/flutter/issues/23794), which would involve building
an audio player plugin for both Android and iOS in addition to a UI in Flutter.

**Getting Started**:
Create a simple Flutter application which utilizes method channels to invoke functionality written in native code via Dart (Java or Kotlin for Android, Objective-C or Swift for iOS). This doesn't have to be anything complicated, just enough to experiment with writing code that crosses language boundaries. See Flutter documentation on [developing packages and plugins](https://flutter.dev/to/develop-packages) for information needed to get started.

It's also recommended that you read through the article on [background execution in Flutter](https://medium.com/flutter/executing-dart-in-the-background-with-flutter-plugins-and-geofencing-2b3e40a1a124). While this is slightly out of date, the general concepts are still correct and will be important for this project.

----


## Template for additional ideas

```md
## **Idea:** {{title}}

 - **Possible Mentor(s)**: `{{email}}`
 - **Difficulty**: {{easy | medium | advanced}}
 - **Skills**: {{keyword}}; ...

**Description**:
{{description}}

**Getting Started**
{{how to get started; good first bugs; ideas for code samples; warm-up exercises}}

----
```
