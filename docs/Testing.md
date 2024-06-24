> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

A programming language and its core libraries sits near the bottom of a
developer's technology stack. Because of that, they expect it to be reliable and
bug free. They expect new releases of the Dart SDK to not break any of their
existing programs, even in rare, strange edge cases. At the scale of Dart today,
even the darkest corner of the language or libraries still has users who care
about its behavior.

We engineer that reliability using automated tests. The tests for the language
and core libraries, which is what this doc is about, live in the SDK repo under
`tests/`. As of this writing, there are 25,329 Dart files in there, containing
over 1.5 million lines of code and over 95,000 individual assertions. Making
this even harder is that Dart includes a variety of tools and
implementations. We have multiple compilers, runtimes, and static analyzers.
Each supports several platforms and options. All told, we currently have 476
supported, tested configurations.

Since our testing needs are both complex and unique, we have several custom test
formats and our own test runner for executing those tests. This doc explains how
to work with tests and use the test runner.

## Concepts

There are several workflows that share the same concepts and terms, so let's get
those out of the way first.

*   **"test.py"**, **"test.dart"**, **test_runner** - The tool that runs tests.
    For many years, it had no real name, so was simply called "test.py" after
    the main entrypoint script used to invoke it. (It was originally written in
    Python before we had any functioning Dart implementations.) When we started
    migrating away from status files, we created a new entrypoint script,
    "test.dart". The pub package that contains all of the real code is named
    "test_runner" and lives at `pkg/test_runner`.

*   **Test suite** - A collection of test files that can be run. Most suites
    correspond to a top level directory under `tests/`: `language_2`, `lib_2`,
    and `co19_2` are each test suites. There are a couple of special suites
    like `pkg` whose files live elsewhere and have special handling in the test
    runner.

    Directories with the `_2` suffix contain pre-null-safety tests, while the
    corresponding suites without `_2` are the null-safe tests. (The `_2`
    suffix is a vestige of the migration from Dart 1.0 to Dart 2.0.)

*   **Test** - A test is a Dart file (which may reference other files) that the
    test runner will send to a Dart implementation and then validate the
    resulting behavior. Most test files are named with an `_test.dart` suffix.

*   **Configuration** - A specific combination of tools and options that can be
    used to invoke a test. For example, "run on the VM on Linux in debug mode"
    is a configuration, "compile to JavaScript with DDC and then run in
    Chrome", or "analyze using the analyzer package with its asserts enabled".
    Each configuration is a combination of architecture, mode, operating system,
    compiler, runtime and many other options. There are thousands of potential
    combinations. We officially support hundreds of points in that space by
    testing them on our bots.

*   **Bots**, **BuildBots**, **builders** - The infrastructure for automatically
    running the tests in the cloud across a number of configurations. Whenever a
    change lands on main, the bots run all of the tests to determine what
    behavior changed.

## Expectations, outcomes, status files, and the results database

This concept is so important it gets its own section. The intent of the test
corpus is to ensure that the behavior we ship is the behavior we intend to ship.
In a perfect world, at every commit, every configuration of every tool would
pass every test. Alas, there are many complications:

*   Some tests deliberately test the error-reporting behavior of a tool. Compile
    errors are also specified behavior, so we have tests to guarantee things
    like "this program reports a compile error". In that case "pass" does *not*
    mean "executes the program without error" because the intent of the test is
    to report the error.

*   Some tests validate behavior that is not supported by some configurations.
    We have tests for "dart:io", but that library is not supported on the web.
    That means all of the "dart:io" tests "fail" on DDC and dart2js, but we of
    course intend and expect that to be true.

*   Some tests are for features that aren't implemented yet. We're constantly
    evolving and at any point in time, there is often some lag between the
    state of various tests and implementations.

*   Some tests are failing that shouldn't be, but they have been for some time
    and we don't currently intend to fix what's causing the failure. We should
    at some point, but we don't want this constant failure to drown out other,
    newer, unexpected failures.

All this means that it's not as simple as "run test and if no errors then great,
otherwise blow up." At a high level, what we really want is:

* To encode the behavior we *intend* to ship.
* To know what behavior *are* shipping.
* To know when that behavior *changes* and what commits cause it.

### Expectation

You can think of each test as having an intent. A human reading the test's code
(and any special comments in it) should be able to predict the behavior the test
produces. For most tests, the intent is to run to completion without error. For
example:

```dart
import 'package:expect/expect.dart';

main() {
  Expect.equals(3, 1 + 2);
}
```

The `Expect.equals()` method throws an exception if the two arguments aren't
equal. So this test will complete silently if `1 + 2` is `3`. Otherwise, it will
throw an uncaught exception, which the test runner detects. So the intent is to
"pass" where "pass" means "run to completion".

Other tests exist to validate the error reporting behavior of the system:

```dart
main() {
  int i = "not int"; //# 01: compile-time error
}
```

This test (a "multitest", see below), says that a conforming tool should produce
a compile time error when the second line of code is included.

Before running a test, the test runner parses the test file and infers an
**expectation** from it&mdash;what the human author says a tool should do when
it runs the test. By default, the expectation is "pass", but some tests are
expected to produce runtime errors or compile-time errors.

### Outcome

When the test runner runs a test on some tool, the tool does some thing. It can
report a compile error or report a runtime error. Maybe it hangs indefinitely
and the test runner has to shut it down and consider it a time out. If it does
none of those things and exits cleanly, it "passes".

We call this the **outcome**. It's the actual observed behavior of the tool.

### Status

In order to tell if a behavior *changes*, we need to record what the previous
behavior was the last time we ran the test under some configuration. We call
this the test's **status**.

In the past, status was recorded in a separate set of
[**status files**](Status-files.md). These live in the repo under `tests/`.
In order to change the expected
behavior of a test, you had to manually change the status file and then commit
that change. In practice, we found this doesn't scale to the number of tools and
configurations we have today.

Instead, we now store the results of previous test runs in a **results
database**. This database is updated automatically by the bots when tests
complete. Every time a bot runs a test suite for some configuration it gathers
up the outcome of every test and records that in the database, associated with
the commit that it ran against. That database is queried by tools (including the
test runner itself) to determine the status of any test for any supported
configuration, at any point in the commit stream.

#### Viewing the current status

The [current results app](https://dart-current-results.web.app/) shows the
current status of all tests, with the ability to filter by test name (path
prefix).

The [results feed](https://dart-ci.firebaseapp.com/) shows the most recent
changes to test statuses, with a tab for unapproved changes.

### Skips and slows

However, we have not yet completely eliminated status files. They are still
around because they are still the source of truth for some hand-authored data
about what a test *should* do. In particular, some tests don't make sense for a
certain configuration at all and should be **skipped**. For example, there's no
point in running the "dart:io" tests on dart2js.

Today, the place a human says "skip these 'dart:io' tests if the configuration
uses dart2js" is in the *status* files. Likewise, some tests are particularly
slow on some configurations and we want to give the test runner more time before
it declares them timing out. That data is also stored in the status files.

Eventually, we hope to move this data into the test itself.

### Comparison and confusion

The previous three sections lay things out in a nice clean way, but the reality
is much more muddled. This is largely because we end up overloading words and don't have clear ways to talk about the *combinations* of outcome, expectation, and status.

For example, if a test "passes", it could mean:

*   The *outcome* is that it completes without error, even though the
    *expectation* is that it should not.
*   The *outcome* is that it completes without error and the *expectation* is
    that it does that.
*   The *expectation* is that it produces a compile error and the outcome is
    that it correctly produces that error.
*   The *outcome* matches the *status*, regardless of what they are.

If a test "fails", it could be:

*   The *outcome* is that it reports an error.
*   The *outcome* is that it does *not* and the *expectation* is that it
    *should*.
*   The *outcome* is that it reports an error, the *expectation* is that it
    should *not*, but the *status* is that it *does*.

Ugh, I could go on. All this really means is that the combination of outcome,
expectation, and status makes things confusing and you have to be careful when
talking about tests and trying to understand the output of tools. Now that
you're nice and confused...

## How the test runner works

When you invoke the test runner, it walks all of the files in the specified
test suites. For each test file:

1.  **Parse the test file to figure out its expectation.** As you'll see below,
    there are a enough of special marker comments you can use in a test to tell
    the test runner what the intent of the test is.

2.  **Figure out what commands to execute with what arguments.** For a simple VM
    test, that may be just "run the VM and give it the path to the test file".
    For a web test, it's multiple commands: One to compile the test to
    JavaScript, and then a separate command to run the result in a JavaScript
    environment. There is custom code in the test runner for each pair of
    compiler and runtime to do this.

3.  **Run the commands and wait for them to complete.** There's a whole little
    dependency graph build system in there that knows which commands depend on
    which ones and tries to run stuff in parallel when it can.

4.  **Analyze the result of the commands to determine the test's outcome.** For
    each command the test runner invokes, it has code to parse the command's
    output. This is usually some combination of looking at the exit code,
    stdout, and stderr.

5.  **Compare the expectation to the outcome.** This produces a new value that
    the test runner vaguely calls "actual". It's sort of a higher-order outcome
    relative to the expectation. We should figure out a better word for it. Some
    examples:

    ```text
    expectation      + outcome          -> actual
    --------------------------------------------------
    Pass             + Pass                Pass
    CompileTimeError + CompileTimeError -> Pass
    Pass             + CompileTimeError -> CompileTimeError
    CompileTimeError + Pass             -> MissingCompileTimeError
    ```

    In other words, if the outcome and the expectation align, that's a "pass" in
    that the tool does what a human says it's supposed to. If they disagree,
    there is some kind of "failure"&mdash;either an error was supposed to
    reported and wasn't, or an unexpected error occurred.

6.  **Compare actual to the status and report any difference.** Now we know what
    the tool did relative to what a human said it's supposed to do. Next is
    figuring out how that result compares to the tool's *previous* behavior.

    If the result and status are the same, the test runner reports the test as
    passing. Otherwise, it reports a failure and shows you the both the result
    and status. To make things profoundly confusing, it refers to the status as
    "expectation".

### A confusing example

The fact that we have three levels of "result" which then get mixed together is
what makes this so confusing, but each level does serve a useful function. The
tools could definitely be clearer about how it's presented.

Here's a maximally tricky example. Let's say we decide to change Dart and make
it a static error to add doubles and ints. You create this test:

```
void main() {
  1 + 2.3; //# 00: compile-time error
}
```

You run it on analyzer before the analyzer team has had a chance to implement
the new behavior. This test is brand new, so it has no existing status and
defaults to "Pass". You'll get:

*   Expectation: CompileTimeError. That's what the multitest marker comment
    means.
*   Outcome: Pass. In Dart today, this code has no errors, so the analyzer
    doesn't report any compile error.
*   Actual: MissingCompileTimeError. There was supposed to be an error reported,
    but the tool didn't report any, so the result was a failure to report an
    expected error.
*   Status: Pass. This is the default status since it's a new test.

Then the test runner prints out something like:

```
FAILED: dart2analyzer-none release_x64 language_2/int_double_plus_test/00
Expected: Pass
Actual: MissingCompileTimeError
```

If you change the status to `MissingCompileTimeError` then it will "pass" and
not print a failure. If, instead, the analyzer team implements the new error,
then the outcome will become CompileTimeError. Since that aligns with the
expectation, the actual becomes Pass. That in turn matches the status, so the
whole test will report as successful.

In short: **When the test runner reports a test as succeeding it means the
difference between the tool's actual behavior and intended behavior has not
changed since the last time a human looked at it.**

## Running tests locally

There are two ways to run tests (cue surprisingly accurate "the old deprecated
way and the way that doesn't work yet" joke).

### Using test.py

The old entrypoint is "test.py":

```sh
./tools/test.py -n analyzer-mac language_2/spread_collections
```

The `-n analyzer-mac` means "run the tests using the 'analyzer-mac' named
configurations". Configurations are defined in the "test matrix", which is a
giant JSON file at `tools/bots/test_matrix.json`. The
`language_2/spread_collections` argument is a "selector". The selector syntax is
a little strange but it's basically a test suite name followed by an optional
somewhat glob-like path for the subset of tests you want to run.

When running the test runner through the `test.py` entrypoint, it does not look
up the current test status from the results database. Instead it just uses the
old status files. This is dubious because those status files are no longer being
maintained, so you will likely get spurious failures simply because the status
is out of date even the tool is doing what it should.

Eventually, this way of running tests should be removed, along with the status
files.

### Using test.dart

The new entrypoint is "test.dart":

```sh
$ ./tools/sdks/dart-sdk/bin/dart tools/test.dart -n analyzer-asserts-mac
```

This ultimately uses the same test runner and works similar to "test.py",
except reads test status from the **results database**.

### Finding a configuration

Reading a several thousand line JSON file to find the name of the configuration
that matches the way you want to run a batch of tests is not fun. Usually, you
know what compiler and runtime you want to test, and you want something that
can run on your local machine. To help you find a configuration that matches
that, the test runner has a `--find-configurations` option.

Pass that, and the test runner prints out the list of configuration names that
match an optional set of filters you provide, which can be any combination of:

```
-m, --mode
      Mode in which to run the tests.

-c, --compiler
      How the Dart code should be compiled or statically processed.

-r, --runtime
      Where the tests should be run.

    --nnbd
      Which set of non-nullable type features to use.

-a, --arch
      The architecture to run tests for.

-s, --system
      The operating system to run tests on.
```

If you don't provide them, then `mode` defaults to `release`, `system` to your
machine's OS, and `arch` to `x64`. If you don't want those default filters, you
can use `all` for any of those options to not filter by that.

Pass `--help` to the test runner to see the allowed values for all of these.

### Local configurations

You typically want to run the tests locally using the same configuration that
the status results are pulled from. It would be strange, for example, to use the
status of some dart2js configuration to define the expected outcome of a batch
of VM tests.

But the bots don't always test every configuration and sometimes there is a
"nearby" configuration to what you want to run that will work for what you're
testing locally. The common case is if you're running tests on a Mac but the bot
only tests a Linux config. Results don't often vary by platform, so you can just
use the Linux results for your local run. To do that, there is an extra flag:

```sh
$ ./tools/sdks/dart-sdk/bin/dart tools/test.dart -n analyzer-asserts-linux \
    -N analyzer-asserts-mac
```

The `-n` (lowercase) flag says "use the results for this config". The `-N`
(uppercase) flag says "run this configuration locally". By default, when you
omit `-N`, it runs the same config locally that it gets results from.

## Running tests on the bots and commit queue

Once you have some code working to your satisfaction, the next step is getting
it landed. This is where the bots come into play. Your first interaction with
them will be the **trybots** on the **commit queue**. When you send a change out
for code review, a human must approve it before you can land it. But it must
also survive a gauntlet of robots.

The commit queue is a system that automatically runs your not-yet-landed change
on a subset of all of the bots. This subset is the trybots. They run a selected
set of configurations to balance good coverage against completing in a timely
manner. If all of those tests pass the change can land on main. Here "pass"
means that the test result is *the same as it was before your change.* A
*change* in status is what's considered "failure".

Of course, many times getting something working and changing the outcome of a
test from failing to passing is your exact goal! In that case, you can *approve*
the changes. This is how a human tells the bots that the change in status is
deliberate and desired.

This workflow is still in flux as part of the move away from status files.
**TODO: Rewrite or remove this once the approval workflow is gone or complete.**

Once you please all of the trybots, the change can land on main. After that
*all* of the bots pick up the change and run the tests on all of the supported
configurations against your change. Assuming we've picked a good set of trybots,
these should all pass. But sometimes you encounter a test that behaves as
expected on the subset of trybots but still changes the behavior on some other
configuration. So failures can happen here and the bots "turn red". When this
happens, you'll need to either approve the new outcomes, revert the change, or
land a fix.

## Working on tests

Your job may mostly entail working on a Dart implementation, but there's still
a good chance you'll end up touching the tests themselves. If you are designing
or implementing a new feature, you will likely edit or add new tests. Our tests
have an unfortunate amount of technical debt, including bugs, so you may end up
finding and needing to fix some of that too.

SDK tests are sort of like "integration tests". They are complete Dart programs
that validate some Dart tool's behavior by having the tool run the program and
then verifying the tool's externally visible behavior. (Most tools also have
their own set of white box unit tests, but those are out of scope for this doc.)

The simplest and most typical test is simply a Dart script that the tool should
run without error and then exit with exit code zero. For example:

```dart
import 'package:expect/expect.dart';

main() {
  Expect.equals(3, 1 + 2);
}
```

We don't use the ["test"][test pkg] package for writing language and core
library tests. Since the behavior we're testing is so low level and fundamental,
we try to minimize the quantity and complexity of the code under test. The
"test" package is great but it uses tons of language and core library
functionality. If you're trying to fix a bug in that same functionality, it's no
fun if your test framework itself is broken by the same bug.

[test pkg]: https://pub.dev/packages/test

Instead, we have a much simpler package called ["expect"][expect pkg]. It's [a
single Dart file][expect lib] that exposes a rudimentary JUnit-like API for
making assertions about behavior. Fortunately, since the behavior we're testing
is also pretty low-level, that API is usually sufficient.

[expect pkg]: https://github.com/dart-lang/sdk/tree/main/pkg/expect
[expect lib]: https://github.com/dart-lang/sdk/blob/main/pkg/expect/lib/expect.dart

The way it works is that if an assertion fails, it throws an exception. That
exception unwinds the entire callstack and a Dart implementation then exits in
some failed way that the test runner can detect and determine that a runtime
error occurred.

If you are writing asynchronous tests, there is a separate tiny
["async_helper"][async pkg] package that talks to the test runner to ensure all
asynchronous operations performed by the test have a chance to complete.

[async pkg]: https://github.com/dart-lang/sdk/tree/main/pkg/async_helper

With these two packages, it's straightforward to write tests of expected correct
runtime behavior. You can also write tests for validating runtime *failures* by
using the helper functions for checking that certain exceptions are thrown:

```dart
import 'package:expect/expect.dart';

main() {
  var list = [0, 1];
  Expect.throwsRangeError(() {
    list[2];
  });
}
```

This test correctly passes if executing `list[2]` throws a RangeError.

We also need to pin down the *static* behavior of Dart programs. The set of
compile errors are specified by the language and tools are expected to report
them correctly. Plain tests aren't enough for that because a test containing a
static error can't be run at all. To handle that, the test runner has built-in
support for other kinds of tests. They are:

### Multitests

A simple multitest looks like this:

```dart
// language_2/abstract_syntax_test.dart
class A {
  foo(); //# 00: compile-time error
  static bar(); //# 01: compile-time error
}
```

Each line containing `//#` marks that line as being owned by a certain multitest
section. The identifier after that is the name of the section. It's usually just
a number like `00` and `01` here, but can be anything. Then, after the colon,
you have an expected outcome.

The test runner takes this file and splits it into several new test files, one
for each section, with an extra one for the "no sections". Each file contains
all of the unmarked lines as well as the lines marked for a certain section. So
the above test gets split into three files:

```dart
// language_2/abstract_syntax_test/none.dart
class A {


}
```

```dart
// language_2/abstract_syntax_test/00.dart
class A {
  foo(); //# 00: compile-time error

}
```

```dart
// language_2/abstract_syntax_test/01.dart
class A {

  static bar(); //# 01: compile-time error
}
```

This is literally done textually. Then the test runner runs each of those files
separately. The expectation for the file is whatever was set in its section's
marker. The "none" file is always expected to pass.

So, in this case, it expects `none.dart` to compile and run without error. It
expects `00.dart` and `01.dart` to report some kind of compile-time error
anywhere in the file.

A single file can contain multiple distinct sections which lets you test for
multiple different errors in a single file. It can distinguish between reporting
a compile-time error versus a runtime error. It's the best we had for a long
time, and works pretty well, so there are many many multitests.

But they aren't great. A single test file containing 20 multitest section gets
split into 21 files, each of which has to pass through the entire compilation
and execution pipeline independently. That's pretty slow. You get better
granularity, but still not perfect. As long as *some* error is reported
*somewhere* in the file that contains the section's lines, it considers that
good enough.

We see a lot of multitests that incorrectly pass because they are supposed to
detect some interesting static type error reported by the type checker. But they
actually pass because the author had a typo somewhere, which gets reported as a
syntax error at compile time.

To try to more precisely and easily write tests for static errors, there is a
yet another kind of test...

### Static error tests

This is the newest form of test. These tests are *only* for validating static
errors reported by one of the two front ends: CFE and analyzer. For all other
configurations, they are automatically skipped.

The previous multitest converted to a static error test looks like this:

```dart
class A {
//    ^
// [cfe] The non-abstract class 'A' is missing implementations for these members:
  foo();
//^^^^^^
// [analyzer] STATIC_WARNING.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER

  static bar();
//            ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected a function body or '=>'.
}
```

Each group of adjacent line comments here defines an **error expectation**. The
first comment line defines the error's location. The line is the preceding line,
the column is the column containing the first caret, and the length is the
number of carets. If the preceding line is itself part of some other error
expectation, it will be skipped over, so you can define multiple errors that
are reported on the same line:

```dart
int i = "not int" / 345;
//      ^^^^^^^^^
// [analyzer] STATIC_WARNING.SOME_ERROR
//                  ^^^
// [analyzer] STATIC_WARNING.ANOTHER_ERROR
```

In cases where the location doesn't neatly fit into this syntax&mdash;it either
starts before column 2 or spans multiple lines&mdash;an explicit syntax can be
used instead:

```dart
var obj1 = [...(123)];
// [error line 1, column 17, length 3]
// [analyzer] CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH
// [cfe] Error: Unexpected type 'int' of a spread.  Expected 'dynamic' or an Iterable.
```

After the location comment line are line defining how analyzer and CFE
should report the error. First, a line comment starting with `[analyzer]`
followed by an analyzer error code specifies that analyzer should report an
error at this location with this error code. If omitted, analyzer is not
expected to report this error.

Finally, a line comment starting with "[cfe] " followed by an error message
specifies that CFE should report an error with the given text at this location.
If omitted, the CFE is not expected to report an error here. If the CFE error
message is longer than a single line, you can have further line comments after
the initial `// [cfe]` one:

```dart
var obj1 = [...(123)];
//             ^^^^^
// [cfe] Error: Unexpected type 'int' of a spread.
// Expected 'dynamic' or an Iterable.
// Another line of error message text.
```

When the test runner runs a test, it looks for and parses all error
expectations. If it finds any, the test is a static error test. It runs the test
once under the given configuration and validates that it produces all of the
expected errors at the expected locations. The test passes if all errors are
reported at the right location. With the analyzer front end, all expected error
codes must match. For the CFE, error messages must match.

Using a single invocation to report all errors requires our tools to do decent
error recovery and detect and report multiple errors. But our users expect that
behavior anyway, and this lets us validate that and get a significant
performance benefit.

#### Web static errors

Most static errors are reported by all Dart tools. The implementation of that
error reporting either comes from analyzer or the CFE and the above two static
error categories `[analyzer]` and `[cfe]` cover almost all static error tests.

However, the web compilers DDC and dart2js also have a few additional static
restrictions they place on Dart. Code that fails to meet those restrictions
produces compile-time errors. We have static error tests for those too, and
they use a separate `[web]` marker comment. Those tests are run on DDC and
dart2js to ensure the error is reported.

#### Divergent errors

Since we don't validate analyzer error messages or CFE error codes, there is
already some flexibility when the two front ends don't report identical errors.
But sometimes one front end may not report an error at all, or at a different
location.

To support that, the error code or message can be omitted. An error expectation
with no error code is ignored on analyzer. Conversely one with no message is
ignored on CFE. Note in the above example that CFE reports the error about
`foo()` on the class declaration while analyzer reports it at the declaration of
`foo()` itself. Those are two separate error expectations.

#### Unspecified errors

A good tool takes into account the processes around it. One challenge for us is
that tests for new errors are often authored before the implementations exist.
In the case of co19, those tests are authored by people outside of the team in a
separate Git repo. At that point in time, we don't know what the precise error
code or message will be.

To make this a little less painful, we allow an error to be "unspecified":

```dart
var obj1 = [...(123)];
//             ^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
```

The special word `unspecifed` in place of an error code or message means the
error must be reported on the given line, but that any code or message is
acceptable. Also, the column and length information is ignored. That enables
this workflow:

1.  Someone adds a test for an unimplemented feature using `unspecified` lines.
2.  The analyzer or CFE team implements the feature and lands support. The tests
    start passing.
3.  In order to pin down the precise behavior now that it's known, someone goes
    back and replaces `unspecified` with the actual error code or message. Now,
    any minor change will cause the test to break so we notice if, for example,
    a syntax error starts masking a type error.
4.  The other front end team does the same.
5.  Now the test is fully precise and passing.

The important points are that the tests start passing on step 2 and continue to
pass through the remaining steps. The syntax above is chosen to be easily
greppable so we can keep track of how many tests need to be made more precise.

#### Automatic error generation

Step three in the above workflow is a chore. Run a test on some front end. Copy
the error output. Paste it into the test file in the right place. Turn it into a
comment. This needs to happen both for new tests and any time the error
reporting for a front end changes, which is frequent. The analyzer and CFE folks
are always improving the usability of their tools by tweaking error messages and
locations.

To make this less painful, we have a tool that will automatically take the
current output of either front end and insert the corresponding error
expectation into a test file for you. It can also remove existing error
implementations.

The tool is:

```sh
$ dart pkg/test_runner/tool/update_static_error_tests.dart -u "**/abstract_syntax_test.dart"
```

It takes a couple of flags for what operation to perform (insert, remove,
update) and for what front end (analyzer, CFE, both) followed by a glob for
which files to modify. Then it goes through and updates all of the matching
tests.

This should give us very precise testing of static error behavior without
much manual effort and good execution performance.
