> [!warning]
> **Google Summer of Code 2023 is no longer accepting applications**.

---

A list of Google Summer of Code project ideas for Dart.

For GSoC related discussions please use the [dart-gsoc group](https://groups.google.com/forum/#!forum/dart-gsoc).

**Potential mentors**
 * Jonas Jensen ([jonasfj](https://github.com/jonasfj)) `jonasfj@google.com`
 * Daco Harkes ([dcharkes](https://github.com/dcharkes)) `dacoharkes@google.com`
 * Sigurd Meldgaard ([sigurdm](https://github.com/sigurdm))‎ `sigurdm@google.com`
 * Liam Appelbe‎ ([liamappelbe](https://github.com/liamappelbe)) `liama@google.com`
 * Hossein Yousefi‎ ([HosseinYousefi](https://github.com/HosseinYousefi)) `yousefi@google.com`
 * Majid Hajian ([mhadaily](https://github.com/mhadaily)) `mhadaily@gmail.com`
 * Brian Quinlan ([bquinlan](https://github.com/brianquinlan)) `bquinlan@google.com`

## Project Application Process
All projects assume familiarity with Dart (and sometimes Flutter). Aspiring applicants are encouraged to [learn Dart](https://dart.dev/guides/language/language-tour) and try to write some code.

Applicants are welcome to find and fix bugs in [Dart](https://github.com/dart-lang/sdk) or some of the [packages written by the Dart team](https://pub.dev/publishers/dart.dev/packages). However, getting reviews can take a long time as code owners may be busy working on new features. So instead of requiring applicants to fix a _good first bug_, we
suggest that applicants write a working code sample relevant for the proposed project.

The code sample can be attached to the application as a [**secret** gist](https://gist.github.com/) (please use _secret gists_, and do not share these with other applicants). Suggested ideas below includes proposed "Good Sample Projects".

**Do not spend too much energy on this piece of sample code**, we just want to see
that you can code something relevant -- and that this sample code can run and do something non-trivial. Be aware that we have a limited number of
mentors available, and will only be able to accept a few applicants.

Applications can be submitted through the [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/) website. Applicants are encouraged to submit draft proposals, linking to Google Docs with permission for mentors to comment. See also the [contributor guide](https://google.github.io/gsocguides/student/writing-a-proposal) on writing a proposal.

**IMPORTANT**: Remember to submit _final proposals_ before [the April 4th deadline](https://developers.google.com/open-source/gsoc/timeline).


## **Idea:** GOgen (or Rustgen, or ...)

 - **Possible Mentor(s)**: dacoharkes@google.com, liama@google.com
 - **Difficulty**: Hard
 - **Project size**: / Large (350 hours)
 - **Skills**: Dart, Go

**Description**: Package [FFIgen](https://github.com/dart-lang/ffigen) makes interop with C and Objective-C seamless, and the (experimental) package [JNIgen](https://github.com/dart-lang/jnigen) does the same for Java and Kotlin. However, what about [Go](https://go.dev/)?

In this project we would parse Go files and generate C wrappers and Dart bindings to those C wrappers so that developers can easily interop with Go from Dart.

1. Design a way to interop with Go. We can explore [cgo](https://pkg.go.dev/cmd/cgo), is this at the right abstraction level for interop? Or would we want a more high level interaction? For example, since Go is garbage collected, can we have handles to Go data structures from Dart that prevent them from being Garbage collected?
2. Design an approach to get the right information from a Go API. This will likely involve a Go parser and static analysis tool. That data structure then needs to be made accessible in Dart (either serialization such as in JNIgen or with direct FFI as in FFIgen).
3. Generate the code that does 1 and 2.
4. Profit!

(Alternatively, we could also do this project for another language. IDL, C++, Rust, …)

**Good Sample Project**: (1) Build a small sample project where you interop with a Go library. (2) Build a prototype for generating the bindings for that library, and (3) use a Go parser to generate those bindings.



## **Idea:** Testing documentation comments

 - **Possible Mentor(s)**: `jonasfj@google.com`, `sigurdm@google.com`
 - **Difficulty**: Hard
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, static analysis

**Description**: When writing Dart code it is useful to write
[documentation comments](https://dart.dev/guides/language/effective-dart/documentation#doc-comments),
such comments will be included in automatically generated documentation created by `dartdoc`.
Documentation comments for `dartdoc` are written in markdown, which allows authors to
embed [code samples](https://dart.dev/guides/language/effective-dart/documentation#consider-including-code-samples-in-doc-comments).
This project aims to create tools for testing _code samples_ embedded in documentation comments.

This will likely involve:
 * Using `package:analyzer` to extract documentation comments.
 * Using `package:markdown` to extract code samples.
 * Testing these code samples by:
   * Running `dart analyze` on the code sample,
   * Passing the code sample through `dart format`, and/or,
   * Running the code sample in an isolate and compare stdout to comments from the sample.

For this project, we'll finish the [`dartdoc_test`](https://pub.dev/packages/dartdoc_test) package, such that it can be used by
package authors who wish to test code samples in their documentation comments.

As part of this project, we'll likely have to define conventions for what is expected of a
code sample in documentation comments:

 * What libraries (if any) are implicitly imported?
 * Can you make code samples that are excluded from testing?
 * Can comments inside the code sample be used to indicate expected output in stdout?
 * How should code be written?
    * Do all code samples need a `main` function?
    * Do we wrap top-level code in an implicit `main` to keep it simple?
    * Do we run the top-level function if it has a name other than `main`?
 * Do we allow dead-code in samples (without an `// ignore: unreachable` comment)?
 * What lints do we apply to sample code (same as the top-level project).

Some of these questions might be debated in the project proposal.
A project proposal should also discuss how package authors would run the code sample tests.
Finally, a project proposal is encouraged to outline implementation stages, including stretch goals.


**Good Sample Project**: Create a function that given some Dart code will use `package:analyzer` to do static analysis of the code and count static errors. Additional step would be to try and use `package:analyzer` to extract documentation comments from source code and use `package:markdown` to extract code-snippets from source code comments, and then run analysis on the extracted source code snippets. Ideally, all of this could be done, in-memory without writing files to disk.


## **Idea:** Build a Dart HTTP client using Java APIs

 - **Possible Mentor(s)**: `bquinlan@google.com`, `yousefi@google.com`

 - **Difficulty**: Hard
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, Java, Android

**Description**: Write a HTTP client that conforms to the [`package:http` `Client` interface](https://pub.dev/documentation/http/latest/http/Client-class.html) and uses [native Java APIs](https://docs.oracle.com/en/java/javase/12/docs/api/java.net.http/java/net/http/package-summary.html) through [`package:jnigen`](https://pub.dev/packages/jnigen). This will allow us to provide several features requested by our users such as:

 * Support for `KeyStore` `PrivateKey`s ([#50669](https://github.com/dart-lang/sdk/issues/50669))
 * Support for the system proxy ([#50434](https://github.com/dart-lang/sdk/issues/50434))
 * Support for user-installed certificates ([#50435](https://github.com/dart-lang/sdk/issues/50435))

Successfully completely this project will likely involve:

  * Determining exactly what APIs should be make available in Dart.
  * Creating a JNI bindings for those APIs using [`package:jnigen`](https://pub.dev/packages/jnigen).
  * Creating a higher-level interface over the JNI bindings e.g. so the Dart developer can work with [Dart URIs](https://api.dart.dev/stable/dart-core/Uri-class.html) rather than [java.net.URI](https://developer.android.com/reference/java/net/URI).
  * Creating a [`package:http` `Client`](https://pub.dev/documentation/http/latest/http/Client-class.html) implementation using the interface above.
  * Verifying that the `Client` implementation passes the [conformance tests](https://github.com/dart-lang/http/tree/main/pkgs/http_client_conformance_tests).

You'll like working on this project because:

 * It will be easy to implement incrementally. After the basic functionality is present, more advanced APIs can be added as time permits.
 * There are existing [conformance tests](https://github.com/dart-lang/http/tree/master/pkgs/http_client_conformance_tests) to validate the correctness of the work.
 * Dart users want it!

A good project proposal will describe what Java APIs are necessary to implement the [`package:http` `Client` interface](https://pub.dev/documentation/http/latest/http/Client-class.html) and an *excellent* project proposal will discuss what features [`package:jnigen`](https://pub.dev/packages/jnigen) needs to use those APIs from Dart.

**Good Sample Project**: Try writing a small [Flutter](https://flutter.dev/) application that makes HTTP requests using Java API bindings created with [`package:jnigen`](https://pub.dev/packages/jnigen).



## **Idea:** Refactor Plus packages to utilize new Dart 3 language features 

 - **Possible Mentor(s)**: Majid Hajian <mhadaily@gmail.com>
 - **Difficulty**: Hard
 - **Project size**: / Medium (175 hours)
 - **Skills**: Dart

**Description**: Dart 3 introduces a few new language features. There are several features such as Records, pattern matching and new direct platform library interop which potentially helps to improve code readability and better API design for packages. 

We would like to explore the possibilities of the new language features that could help to improve packages and create a new API (potentially) or refactor internal coding that make the package to take full advantage of Dart 3. We would like to also prepare a guideline after this refactoring for other maintainers to figure out what could be improved or changed.

We are using [Federated plugins](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#federated-plugins)  therefore this is likely to involve:
 
* refactoring `platform_interface` class for each package,
* refactoring app-facing and platform-specific-implementation packages,
* potentially removing native code and replacing it with direct dart API calls,
* rewriting the entire package unit and e-2-e tests,
* replacing CI/CD existing workflow making it compatible with upcoming language feature, and
* potentially breaking the API and releasing a new major version.

Some of these questions might be debated in the project proposal. A project proposal is encouraged to outline implementation stages, including stretch goals.

**Good Sample Project**: Create new packages for both [Device_Info](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/device_info_plus) or [Connectivity_Plus](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/connectivity_plus) and redesign part of the APIs including in platform interface and use Dart 3 language features, then create a Flutter project from main branch and then use these packages with latest Flutter and Dart 3 version that uses all APIs.




