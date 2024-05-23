> [!warning]
> **Google Summer of Code 2022 is no longer accepting applications**.

---

A list of Google Summer of Code project ideas for Dart.

For GSoC related discussions please use the [dart-gsoc group](https://groups.google.com/forum/#!forum/dart-gsoc).

**Potential mentors**
 * Jonas Jensen ([jonasfj](https://github.com/jonasfj)) `jonasfj@google.com`
 * Daco Harkes ([dcharkes](https://github.com/dcharkes)) `dacoharkes@google.com`
 * Sighurd Meldgaard ([sigurdm](https://github.com/sigurdm))‎ `sigurdm@google.com`
 * Liam Appelbe‎ ([liamappelbe](https://github.com/liamappelbe)) `liama@google.com`
 * Majid Hajian ([mhadaily](https://github.com/mhadaily))
 * Simon Lightfoot ([slightfoot](https://github.com/slightfoot))
 * Miguel Beltran ([miquelbeltran](https://github.com/miquelbeltran))

## Project Application Process
All projects assume familiarity with Dart (and sometimes Flutter). Aspiring applicants are encouraged to [learn Dart](https://dart.dev/guides/language/language-tour) and try to write some code.

Applicants are welcome to find and fix bugs in [Dart](https://github.com/dart-lang/sdk) or some of the [packages written by the Dart team](https://pub.dev/publishers/dart.dev/packages). However, getting reviews can take a long time as code owners may be busy working on new features. So instead of requiring applicants to fix a _good first bug_, we
suggest that applicants write a working code sample relevant for the proposed project.

The code sample can be attached to the application as a [**secret** gist](https://gist.github.com/) (please use _secret gists_, and do not share these with other applicants). Suggested ideas below includes proposed "Good Sample Projects".

**Do not spend too much energy on this piece of sample code**, we just want to see
that you can code something relevant -- and that this sample code can run and do something non-trivial. Be aware that we have a limited number of
mentors available, and will only be able to accept a few applicants.

Applications can be submitted through the [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/) website. Students are encouraged to submit draft proposals, ideally linking to a Google Docs with permission for mentors to comment. See also the [student guide](https://google.github.io/gsocguides/student/writing-a-proposal) on writing a proposal.

**IMPORTANT**: Remember to submit _final proposals_ before [the April 19th deadline](https://developers.google.com/open-source/gsoc/timeline).

----

## **Idea:** JNI interop for Dart

 - **Possible Mentor(s)**: `dacoharkes@google.com`, `liama@google.com`
 - **Difficulty**: Hard
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, Java, C

**Description**:
Use `dart:ffi` to bind Java library in Flutter through [JNI](https://developer.android.com/training/articles/perf-jni). This would ideally encompass ergonomic Dart bindings for [JNI C interface](https://github.com/openjdk/jdk/blob/master/src/java.base/share/native/include/jni.h) and a bindings generator that can scan Java code or JARs and generate Dart bindings which uses JNI.

1. This project requires a way to scan Java code or JARs. For inspiration: package:ffigen scans C header files with libclang.
2. Design data structures to hold the information. And generate the C JNI code + Dart bindings.
3. This project needs an architecture design as well. Does it fit in package:ffigen? Or should we make a new package?
4. Make the package work for a killer use case. What Java library would you want to use from Dart?

**Good Sample Project**
Create a Flutter app that (1) calls a Java method from Dart with JNI, and (2) calls a Dart method from Java with JNI.

## **Idea:** Detecting Semantic Version Violations

 - **Possible Mentor(s)**: `jonasfj@google.com`, `sigurdm@google.com`
 - **Difficulty**: Hard
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, Static Analysis

**Description**:
Dart packages on pub.dev use [semantic versioning](https://semver.org/). We should be able to detect obvious compatibility violations. For each version of a package we can generate a JSON file with a summary of public methods/types/properties and their signatures. By comparing the summary of two package versions (which are supposed to be compatible), we should be able to detect obvious cases where semantic versioning was violated because class, member, property or type was removed or changed in a backwards incompatible manner.

Naturally, not all semantic version violations can be detected. But a subset would be detectable. This could be used for scoring on pub.dev, or offered as a utility package authors can run in CI before publishing their package.

A project proposal for this idea is encouraged to outline what the JSON format might look like. It would also be great to have some examples of semantic version violations that can be detected along with a brief description of how. Doing this it's probably also useful to think about a few examples of cases where we cannot detect semantic version violations, included a few such examples also helps demonstrate what limits exist. The project proposal doesn't have to outline the complete JSON format, or a completely list of heuristics, but a few examples showing the possibilities and limitations would be interesting.

**Good Sample Project**
Create a command-line Dart application that given a Dart file will use `package:analyzer` to print a list of all exported top-level symbols.
For example, given [`retry.dart`](https://github.com/google/dart-neats/blob/master/retry/lib/retry.dart) this application should print two lines containing `RetryOptions` and `retry`. Feel free to expand it print additional information about exported symbols, such as type, methods, etc.


## **Idea:** Changelog Parser for pub.dev

 - **Possible Mentor(s)**: `jonasfj@google.com`, `sigurdm@google.com`
 - **Difficulty**: Medium
 - **Project size**: Small (175 hours)
 - **Skills**: Dart, Parsing

**Description**:
Most packages on pub.dev contain a `CHANGELOG.md` file. When rendering this
file we would like to parse it and link versions to sections. There is already
some rudimentary code for parsing changelogs, but this doesn't handle
complex cases and does not link to versions. This project would be to write
a Dart package for parsing changelogs. Ideally, we should be able to parse
a large percentage of the existing changelogs on pub.dev correctly. This is
difficult because changelogs are written by hand, and different packages
have slightly different formats.

Goal is to integrate this with pub.dev, document a simple format for writing
changelogs and successfully parse the vast majority of changelogs on pub.dev.

## **Idea:** Flutter Community Admin Dashboard

 - **Possible Mentor(s)**: Majid Hajian ([mhadaily](https://github.com/mhadaily)), Simon Lightfoot ([slightfoot](https://github.com/slightfoot))
 - **Difficulty**: medium
 - **Project size**: large
 - **Skills**: Dart, Flutter

**Description**:
The Flutter Community (FC) is providing several packages to the community and pub. dev that is all maintained differently. It’s hard for Flutter Community admins to engage with all of the changes, releases, changelogs, and activities on all packages. 

One of the main challenges is keeping track of releases, especially allowing maintainers to trigger package releases on pub dev without giving them super admin access. 

The FC dashboard would be an intelligent platform where it would gather information including issues, latest activity on repositories, maintainers, level of access, trigger to build and deploy to pub.dev, and more for all Admins as well as maintainers with different levels of permission. 

Naturally, This dashboard is going to be an assistant to admins to figure out inactivities on different repositories and try to ping maintainers or admins in order to engage with PRs or users. 

The publishing to pub.dev would also be maintained and managed on the dashboard instead of pub.dev, therefore, we would have a history of releases with full logs on who has done what. 

Last but not least, it would be great to make the dashboard even smarter by adding some AI tooling that can potentially recognize issues that are not active or need to be closed or help maintainer to organize their way of working on their packages. We potentially like to see the UI done in Flutter so that we can deploy the app on all platforms if we need to! 

Tasks:

* [ ] Simple login with Github only
* [ ] Gather information and show them as graphs, numbers and etc. to give a better understanding of the overall performance of the organization 
* [ ] Details of each repo under the orgs, such as number of issues, in active issues, closing and maintainers 

Ideally the dashboard can be hosted using Firebase. A project proposal for this idea is encouraged to include an outline of what metrics/information/graphs that would be surfaced in the dashboard. 


**Good Sample Project** Authentication with Github and access level (authorization) and keep track of all issues grouped by packages/repositories.

Org: https://github.com/fluttercommunity

## **Idea:** Write integration Test for Plus Plugins 

 - **Possible Mentor(s)**: Majid Hajian ([mhadaily](https://github.com/mhadaily)), Miguel Beltran ([miquelbeltran](https://github.com/miquelbeltran))
 - **Difficulty**: medium to hard
 - **Project size**: small
 - **Skills**: Dart, Flutter

**Description**:
The [plus plugins](https://plus.fluttercommunity.dev/) as provided by fluttercommunity are important as they expose many platform specific APIs. These plus plugins were forked from packages maintained by Flutter a few years ago, after which additional platform support and features have been introduced.

Thousands of users use the plugins! The plus team spends a lot of time handling issues, addressing issues and reviewing pull-requests to fix bugs, add new features and support additional platforms. This work is time consuming because minor bugs can negatively impact developers who rely on these packages for creating apps. Thus, great care is required when reviewing code and additional new features or platforms.

Adding integration tests for all plus plugin packages could help reduce the risk of introducing bugs when fixing bugs and adding new features or platforms.

This project idea is to write integration tests for all plus packages using the `integration_test` package. At a minimum it is desirable to have some tests for each plugin. But depending on much time is available, it would be attractive to expand the project to include:
 * Testing most of the functionality using integration tests.
 * Integration tests that work on multiple platforms.
 * Running integration in continuous integration (Github Actions, when possible)
 * Collecting code coverage from integration tests.
 * Submitting code coverage statistics to coveralls.io

Links:
 * [Example](https://github.com/fluttercommunity/plus_plugins/blob/main/packages/android_alarm_manager_plus/example/integration_test/android_alarm_manager_plus.dart)
 * [Repository](https://github.com/fluttercommunity/plus_plugins/)

**Good Sample Project** contribute to the [plus_plugins repository](https://github.com/fluttercommunity/plus_plugins/) by fixing small issues.


