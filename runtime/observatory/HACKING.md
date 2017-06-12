# Hacking Observatory

These instructions will guide you through the Observatory development and
testing workflow.

## SDK Setup & Build
Getting ready to start.

Before you start to hack on Observatory, follow the [instructions][build_sdk] to
have a working environment in which you are able to build and test the Dart SDK.

### Develop with Dartium ~ Suggested
If you want to avoid triggering a new compilation to JavaScript for each edit
you do, you can use a modified version of Chromium named Dartium that will
interpret your dart code directly.

You can obtain Dartium in two different ways:
1. [Download][download_dartium] the binaries
2. [Build][build_dartium] Dartium from the source code


## Run existing tests
Before hacking Observatory let's run the existing Observatory tests.
We suggest to run all the test in __debug__ mode.

First build the sdk in debug mode
```
$ ./tools/build.py --mode debug create_sdk
```

From the root of the sdk repository run:
```
$ ./tools/test.py -mdebug service
```

## Serve Observatory
Observatory is built as part of building the sdk, but when working on
Observatory we recommend that you use __pub serve__ so you can avoid the
overhead of building the sdk for each change.

Use __pub__ to __serve__ Observatory:
```
[...]/runtime/observatory$ pub serve
```

## Open Observatory
You can open the development version of Observatory from
Chrome/Chromium/__Dartium__ by navigating to [localhost:8080][open_observatory]

Every change you make to the Observatory source code will be visible by simply
__refreshing__ the page in the browser.

## Connect to a VM
Start a Dart VM with the ``--observe`` flag (as explained in the
[get started guide][observatory_get_started]) and connect your Observatory
instance to that VM.

Example script (file name ```clock.dart```):
```dart
import 'dart:async' show Timer, Duration;

main() {
  bool tick = true;
  new Timer.periodic(const Duration(seconds: 1), (Timer t) {
    print(tick ? 'tick' : 'tock');
    tick = !tick;
  });
}
```
Start the script:
```
$ dart --disable-service-origin-check --observe clock.dart
```

## Code Reviews
The development workflow of Dart (and Observatory) is based on code reviews.

Follow the code review [instructions][code_review] to be able to successfully
submit your code.

The main reviewers for Observatory related CLs are:
  - turnidge
  - johnmccutchan
  - rmacnak

## Write a new service test
All the service tests are located in the ```tests/service``` folder.
Test file names follow the convention ```<description>_test.dart```
(e.g. ```a_brief_description_test.dart```).

The test is generally structured in the following way.
```dart
import 'package:test/test.dart';

main() {
  // Some code that you need to test.
  var a = 1 + 2;

  // Some assertions to check the results.
  expect(a, equal(3));
}
```
See the official [test library][test_library] instructions;

The ```test_helper.dart``` file expose some functions that allow to run a part
of the code into another __VM__.

To test synchronous operations:
```dart
import 'test_helper.dart';

code() {
  // Write the code you want to be execute into another VM.
}

var tests = [
  // A series of tests that you want to run against the above code.
  (Isolate isolate) async {
    await isolate.reload();
    // Use the isolate to communicate to the VM.
  }
];

main(args) => runIsolateTestsSynchronous(args,
                                        tests,
                                        testeeConcurrent: code);
```

In order to test asynchronous operations:
```dart
import 'test_helper.dart';

code() async {
  // Write the asynchronous code you want to be execute into another VM.
}

var tests = [
  // A series of tests that you want to run against the above code.
  (Isolate isolate) async {
    await isolate.reload();
    // Use the isolate to communicate to the VM.
  }
];

main(args) async => runIsolateTests(args,
                                    tests,
                                    testeeConcurrent: code);
```

Both ```runIsolateTests``` and ```runIsolateTestsSynchronous``` have the
following named parameters:
 - __testeeBefore__ (void()) a function that is going to be executed before
the test
 - __testeeConcurrent__ (void()) test that is going to be executed
 - __pause_on_start__ (bool, default: false) pause the Isolate before the first
instruction
 - __pause_on_exit__ (bool, default: false) pause the Isolate after the last
instruction
 - __pause_on_unhandled_exceptions__ (bool, default: false) pause the Isolate at
an unhandled exception
 - __trace_service__ (bool, default: false) trace VM service requests
 - __trace_compiler__ (bool, default: false) trace compiler operations
 - __verbose_vm__ (bool, default: false) verbose logging


Some common and reusable test are available from ```service_test_common.dart```:
 - hasPausedFor
   - hasStoppedAtBreakpoint
   - hasStoppedWithUnhandledException
   - hasStoppedAtExit
   - hasPausedAtStartcode_review
and utility functions:
 - subscribeToStream
 - cancelStreamSubscription
 - asyncStepOver
 - setBreakpointAtLine
 - resumeIsolate
 - resumeAndAwaitEvent
 - resumeIsolateAndAwaitEvent
 - stepOver
 - getClassFromRootLib
 - rootLibraryFieldValue

## Run your tests
See: __Run existing tests__

[build_sdk]: https://github.com/dart-lang/sdk/wiki/Building "Building the Dart SDK"
[download_dartium]: https://webdev.dartlang.org/tools/dartium/ "Download Dartium"
[build_dartium]: https://github.com/dart-lang/sdk/wiki/Building-Dartium "Build Dartium"
[open_observatory]: http://localhost:8080/ "Open Observatory"
[observatory_get_started]: https://dart-lang.github.io/observatory/get-started.html "Observatory get started"
[code_review]: https://github.com/dart-lang/sdk/wiki/Code-review-workflow-with-GitHub-and-reitveld "Code Review"
[test_library]: https://pub.dartlang.org/packages/test "Test Library"
