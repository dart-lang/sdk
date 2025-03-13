> [!warning]
> **Google Summer of Code 2025 is not accepting applications yet**.

------

A list of Google Summer of Code project ideas for Dart.

For GSoC related discussions please use the [dart-gsoc group](https://groups.google.com/forum/#!forum/dart-gsoc).

**Potential mentors**
 * Jonas Jensen ([jonasfj](https://github.com/jonasfj)) `jonasfj@google.com`
 * Daco Harkes ([dcharkes](https://github.com/dcharkes)) `dacoharkes@google.com`
 * Hossein Yousefi ([HosseinYousefi](https://github.com/HosseinYousefi)) `yousefi@google.com`
 * Liam Appelbe ([liamappelbe](https://github.com/liamappelbe)) `liama@google.com`
 * Huan Lin  ([hellohuanlin](https://github.com/hellohuanlin)) `huanlin@google.com`
 * Justin McCandless ([justinmc](https://github.com/justinmc)) `jmccandless@google.com`
 * Mudit Somani ([TheComputerM](https://github.com/TheComputerM)) `mudit.somani00@gmail.com`
 * More to come!

## Project Application Process
All projects assume familiarity with Dart (and sometimes Flutter). Aspiring applicants are encouraged to [learn Dart](https://dart.dev/guides/language/language-tour) and try to write some code.

Applicants are welcome to find and fix bugs in [Dart](https://github.com/dart-lang/sdk) or some of the [packages written by the Dart team](https://pub.dev/publishers/dart.dev/packages). However, getting reviews can take a long time as code owners may be busy working on new features. So instead of requiring applicants to fix a _good first bug_, we
suggest that applicants write a working code sample relevant for the proposed project.

The code sample can be attached to the application as a [**secret** gist](https://gist.github.com/) (please use _secret gists_, and do not share these with other applicants). Suggested ideas below includes proposed "Good Sample Projects".

**Do not spend too much energy on this piece of sample code**, we just want to see
that you can code something relevant -- and that this sample code can run and do something non-trivial. Be aware that we have a limited number of
mentors available, and will only be able to accept a few applicants.

Applications can be submitted through the [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/) website. Applicants are encouraged to submit draft proposals, linking to Google Docs with permission for mentors to comment. See also the [contributor guide](https://google.github.io/gsocguides/student/writing-a-proposal) on writing a proposal.

**IMPORTANT**: Remember to submit _final proposals_ before [the April 2nd deadline](https://developers.google.com/open-source/gsoc/timeline).

## **Idea:** Exception testing for `package:webcrypto`

 - **Possible Mentor(s)**: `jonasfj@google.com`,
 - **Difficulty**: Hard
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, FFI, JS

**Description**: `package:webcrypto` ([github.com/google/webcrypto.dart](https://github.com/google/webcrypto.dart)) is a cross-platform implementation of the [Web Cryptography API](https://www.w3.org/TR/WebCryptoAPI/).
It is important that it behaves the same way whether it's running on Windows, Linux, Mac, Android, iOS, Chrome, Firefox, or Safari. Towards that end, it has a lot of test cases. We could and should probably make more test cases.
But we should also test that it throws the types of exceptions when given incorrect parameters. This probably needs a small test framework to ensure good test coverage.

We expect a proposal for this project to include:
 * A sample showing how to test exceptions for `RsaPssPrivateKey.generateKey`.
   Ideally, the sample project includes parts of a generalized framework for testing exceptions.
 * An outline of what kind of exceptions should be tested?
 * A design for extending `TestRunner`, or creating a new framework, to test exceptions thrown by all methods.
   * Illustrative code for how test cases would be configured
   * Pros and cons of the design (especially when multiple choices are available)
 * Timeline for the project

**Good Sample Project**:
Write a test cases that tests the different kinds of errors and exceptions that can be thrown by `RsaPssPrivateKey.generateKey`, run the tests across desktop, Chrome and Firefox. Consider extending the tests to cover all members of `RsaPssPrivateKey`.
Try to generalize these test cases to avoid repetitive code, see the existing [TestRunner](https://github.com/google/webcrypto.dart/blob/5e6d20f820531d2b7b05935c1d78f38a036035e8/lib/src/testing/utils/testrunner.dart#L227) for inspiration.

**Expected outcome**: PRs that land in `package:webcrypto` and increases our confidence in correctness cross-platforms.


## **Idea:** Use an LLM to translate Java/Kotlin tutorial snippets into Dart JNIgen code

 - **Possible Mentor(s)**: `dacoharkes@google.com`, `yousefi@google.com`
 - **Difficulty**: Hard
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, FFI, Java

**Description**: This project will be very exploratory. We’ll explore how much is needed to make an LLM generate Dart snippets that call JNIgen-generated code. The snippets should be the equivalent of the original native code. How much will be needed? Is a single shot prompt enough? Or do we need to teach an AI how to run JNIgen and make it generate code that is subsequently analyzed with the Dart analyzer and the errors are fed back in to the AI to improve its answer.

If we get this working, we’ll want to explore how to make such a tool useful to users. For example, we could make a browser extension that automatically adds the generated code snippets to documentation websites.

Inspired by this issue: https://github.com/dart-lang/native/issues/1240

**Good Sample Project**:
* Get a Gemini API key https://ai.google.dev/gemini-api/docs/api-key
* Follow https://developers.google.com/learn/pathways/solution-ai-gemini-getting-started-dart-flutter
* Write a Dart script that invokes the API with a prompt containing a Java snippet (for example from https://developer.android.com/media/camera/camerax/take-photo#take_a_picture) and try to come up with a prompt that will make it generate code that would work on the Dart API generated with JNIgen for this Java/Kotlin API.

**Expected outcome**: A tool for translating code samples usable by users.


## **Idea:** package:coverage + LLM = test generation

 - **Possible Mentor(s)**: `liama@google.com`
 - **Difficulty**: Medium
 - **Project size**: Medium (175 hours)
 - **Skills**: Dart, LLMs

**Description**: This is a very experimental project. The idea is to use `package:coverage` to identify uncovered code, use an LLM to decide if that code needs a test (not all code actually needs to be tested), then use an LLM to write tests that hit those cases, and then use `package:coverage` to verify that those lines are covered.

**Good Sample Project**:
* Get a Gemini API key https://ai.google.dev/gemini-api/docs/api-key
* Follow https://developers.google.com/learn/pathways/solution-ai-gemini-getting-started-dart-flutter
* Try generating tests for any old Dart API. Don't try to integrate `package:coverage` yet.

**Expected outcome**: A package on pub.dev for increasing test coverage.


## **Idea:** Secure Paste Custom Actions on iOS

 - **Possible Mentor(s)**: `huanlin@google.com`, `jmccandless@google.com`
 - **Difficulty**: Hard
 - **Project size**:  Large (350 hours)
 - **Skills**: Dart, Objective-C

**Description**: Support custom action items for native edit menu on iOS. It's a pretty impactful project requested by many developers (main issue here: https://github.com/flutter/flutter/issues/103163). This project is one of the key milestones: https://github.com/flutter/flutter/issues/140184.

Project:
* Prepare: Learn basic git commands; Setup flutter engine dev environment; Read style guide, etc;
* Design new dart API for custom items in context menu (Related API: https://api.flutter.dev/flutter/widgets/SystemContextMenu-class.html)
* Design engine <-> framework communication API using method channel
* Implement both framework part (in Dart) and engine part (in Objective-C)
* Go through code review process and land the solution
* The final product should allow developers to add custom items to the iOS native edit menu.

**Good Sample Project**: ...

* Build a sample project in Flutter with a text field that shows custom actions in the context menu. (Hint: use https://docs.flutter.dev/release/breaking-changes/context-menus).
* Build a sample project in UIKit that shows custom actions in the native edit menu (Hint: use https://developer.apple.com/documentation/uikit/uieditmenuinteraction?language=objc). You can either use ObjC or Swift, but ObjC is preferred.

**Expected outcome**: A PR merged in Flutter

## **Idea:** TUI framework for dart

 - **Possible Mentor(s)**: `mudit.somani00@gmail.com`
 - **Difficulty**: Medium
 - **Project size**: Medium (175 hours)
 - **Skills**: Dart, CLIs

**Description**: Dart is already used to create GUI applications through Flutter, it would be great if it can also be used to develop good looking TUI applications. Currently the language of choice for TUI development would be either Golang or Python due to their developed package ecosystems (like [charm](https://charm.sh/) or [textual](https://www.textualize.io/)) so a package that makes TUI development easier and faster on dart would increase its adoption in that space.

Project:
* Design composable methods to render components and text on the terminal
* Include popular components like inputs, checkboxes and tables by default
* Intuitive way to create your own custom components for the terminal
* Ensure library works with popular state management libraries in dart

**Good Sample Project**:

* Composable methods to style text on the terminal (kinda like [libgloss](https://github.com/charmbracelet/lipgloss)).
* Component based model to render and interact with terminal based text inputs and checkboxes (kinda like [bubbles](https://github.com/charmbracelet/bubbles)).

**Expected outcome**: A package on pub.dev with terminal primitives like text styling, inputs, checkboxes, tables, layouts, spinners etc.


## TODO: More ideas as they come!

# Template:

Copy this template.

## **Idea:** ...

 - **Possible Mentor(s)**:
 - **Difficulty**: Easy / Hard
 - **Project size**: Small (90) / Medium (175 hours) / Large (350 hours)
 - **Skills**: ...

**Description**: ...

**Good Sample Project**: ...

**Expected outcome**: ...
