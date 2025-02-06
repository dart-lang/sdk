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
