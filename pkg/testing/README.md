<!--
Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->
# Test Infrastructure without Batteries

This package:

  * Provides a way to test a compiler in multiple steps.

  * Provides a way to run standalone tests. A standalone test is a test that has a `main` method, and can be run as a standalone program.

  * Ensures all tests and implementations are free of warnings (using dartanalyzer).

This package is not:

  * A replacement for `package:test`. This package can be used to run `package:test` tests, and `package:test` can be viewed as the batteries that aren't included in this package.

## Motivation

We want to test tool chains, for example, a Dart compiler. Depending on the tool chain, it may comprise several individual steps. For example, to test dart2js, you have these steps:

  1. Run dart2js on a Dart source file to produce a Javascript output file.

  2. Run the Javascript file from step 1 on a Javascript interpreter and report if the program threw an exception.

On the other hand, to test a Dart VM, there's only one step:

  1. Run the Dart source file in the Dart VM and report if the program threw an exception.

Similarly, to test dartanalyzer, there's also a single step:

  1. Analyze the Dart source file and report if there were any problems.

In general, a tool chain can have more steps, for example, a pub transformer.

Furthermore, multiple tool chains may share the input sources and should agree on the behavior. For example, you should be able to compile `hello-world.dart` with dart2js and run it on d8 and it shouldn't throw an exception, running `hello-world.dart` on the Dart VM shouldn't throw an exception, and analysing it with dartanalyzer should report nothing.

In addition, parts of the tool chain may have been implemented in Dart and have unit tests written in Dart, for example, using [package:test](https://github.com/dart-lang/test). We want to run these unit tests, and have noticed that compiler unit tests in general run faster when run from the same Dart VM process (due to dynamic optimizations kicking in). For this reason, it's convenient to have a single Dart program that runs all tests. On the other hand, when developing, it's often convenient to run just a single test.

For this reason, we want to support running unit tests individually, or combined in one program. And we also want the Dart-based implementation to be free of problems with respect to dartanalyzer.

## Test Suites

A test suite is a collection of tests. Based on the above motivation, we have two kinds of suites:

  1. [Chain](#Chain), a test suite for tool chains.

  2. [Dart](#Dart), a test suite for Dart-based unit tests.

## Getting Started

  1. Create a [configuration file](#Configuration) named `testing.json`.

  2. Run `bin/run_tests.dart`.

## Configuration

The test runner is configured using a JSON file. A minimal configuration file is:

```json
{
}
```

### Chain

A `Chain` suite is a suite that's designed to test a tool chain and can be used to test anything that can be divided into one or more steps.

Here a complete example of a `Chain` suite:

```json
{
  "suites": [
    {
      "name": "golden",
      "kind": "Chain",
      "source": "test/golden_suite.dart",
      "path": "test/golden/",
      "status": "test/golden.status",
      "pattern": [
        "\\.dart$"
      ],
      "exclude": [
      ]
    }
  ]
}
```

The properties of a `Chain` suite are:

*name*: a name for the suite. For simple packages, `test` or the package name are good candidates. In the Dart SDK, for example, it would be things like `language`, `corelib`, etc.

*kind*: always `Chain` for this kind of suite.

*source*: a relative URI to a Dart program that implements the steps in the suite. See [below](#Implementing-a-Chain-Suite).

*path*: a URI relative to the configuration file which is the root directory of all files in this suite. For now, only file URIs are supported. Each file is passed to the first step in the suite.

*status*: a URI relative to the configuration file which lists the status of tests.

*pattern*: a list of regular expressions that match file names that are tests.

*exclude*: a list of regular expressions that exclude files from being included in this suite.

#### Implementing a Chain Suite

The `source` property of a `Chain` suite is a Dart program that must provide a top-level method with this name and signature:

```dart
Future<ChainContext> createContext(Chain suite) async { ... }
```

A suite is expected to implement a subclass of `ChainContext` which defines the steps that make up the chain and return it from `createContext`.

A step is a subclass of `Step`. The input to the first step is a `TestDescription`. The input to step n+1 is the output of step n.

Here is an example of a suite that runs tests on the Dart VM:

```dart
import 'testing.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new VmContext();
}

class VmContext extends ChainContext {
  final List<Step> steps = const <Step>[const DartVmStep()];
}

class DartVmStep extends Step<TestDescription, int, VmContext> {
  const DartVmStep();

  String get name => "Dart VM";

  Future<Result<int>> run(TestDescription input, VmContext context) async {
    StdioProcess process = await StdioProcess.run("dart", [input.file.path]);
    return process.toResult();
  }
}

main(List<String> arguments) => runMe(arguments, createContext);
```

An example with multiple steps in the chain can be found in the Kernel package's [suite](https://github.com/dart-lang/kernel/blob/closure_conversion/test/closures/suite.dart). Notice how this suite stores an `AnalysisContext` in its `TestContext` and is this way able to reuse the same `AnalysisContext` in all tests.

### Dart

The `Dart` suite is for running unit tests written in Dart. Each test is a Dart program with a main method that can be run directly from the command line.

The suite generates a new Dart program which combines all the tests included in the suite, so they can all be run (in sequence) in the same process. Such tests must be co-operative and must clean up after themselves.

You can use any test-framework, for example, `package:test` in these individual programs, as long as the frameworks are well-behaved with respect to global state, see [below](#Well-Behaved-Tests).

Here is a complete example of a `Dart` suite:

```json
{
  "suites": [
    {
      "name": "my-package",
      "path": "test/",
      "kind": "Dart",
      "pattern": [
        "_test\\.dart$"
      ],
      "exclude": [
        "/test/golden/"
      ]
    }
  ]
}
```

The properties of a `Dart` suite are:

*name*: a name for the suite. For simple packages, `test` or the package name are good candidates. In the Dart SDK, for example, the names could be the name of the component that's tested by this suite's unit tests, for example, `dart2js`.

*path*: a URI relative to the configuration file which is the root directory of all files in this suite. For now, only file URIs are supported.

*kind*: always `Dart` for this kind of suite.

*pattern*: a list of regular expressions that match file names that are tests.

*exclude*: a list of regular expressions that exclude files from being included in this suite.

#### Well-Behaved Tests

The `Dart` suite makes certain assumptions about the tests it runs.

 * All tests use the same packages configuration file.

 * An asynchronous test returns a `Future` from its `main`.

 * Tests manages global state.

All tests are imported into the same program as individual libraries, which is why they all must use the same `.packages` file. The tests aren't concatenated, so they have the lexical scope you'd normally expect from a Dart library.

Tests are run in order. In particular, the test framework will not start the next test until any future returned from the current test's `main` method complete. In addition, asynchronous tests are expected to have finished all asynchronous operations when the future returned from their `main` method completes (with or without an error).

Tests are expected to manage global state (aka static state). Simply put: clean up after yourself. But if it's simpler to ensure global state is reset before running a test and not clean up afterwards, that's also fine as long as all tests agree on how to manage their shared global state.

### Configuring Analyzed Programs

By default, all tests in `Dart` suites are analyzed by the `dartanalyzer`. It is possible to exclude tests from analysis, and it's possible to add additional files to be analyzed. Here is a complete example of a `Dart` suite and analyzer configuration:

```json
{
  "suites": [
    {
      "name": "my-package",
      "path": "test/",
      "kind": "Dart",
      "pattern": [
        "_test\\.dart$"
      ],
      "exclude": [
        "/test/golden/"
      ]
    }
  ],
  "analyze": {
    "uris": [
      "lib/",
    ],
    "exclude": [
      "/third_party/"
    ]
  }
}
```

The properties of the `analyze` section are:

*uris*: a list of URIs relative to the configuration file that should also be analyzed. For now, only file URIs are supported.

*exclude*: a list of regular expression that matches file names that should be excluded from analysis. For now, the files are still analyzed but diagnostics are suppressed and ignored.

## Integrating with Other Test Runners

### `test.dart`

To run the suite `my_suite` from `test.dart`, create a file named `mysuite_test.dart` with this content:

    import 'package:async_helper/async_helper.dart' show asyncTest;

    import 'package:testing/testing.dart' show run;

    main(List<String> arguments) => asyncTest(run(arguments, ["my_suite"]));

### `package:test`

To run the suite `my_suite` from `package:test`, create a file named `mysuite_test.dart` with this content:

    import 'package:test/test.dart' show Timeout, test;

    import 'package:testing/testing.dart' show run;

    main() {
      test("my_suite", () => run([], ["my_suite"]),
          timeout: new Timeout(new Duration(minutes: 5)));
    }
