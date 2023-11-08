// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

/// A marker used in some test scripts/tests for where to set breakpoints.
const breakpointMarker = '// BREAKPOINT';

/// A simple empty Dart script that should run with no output and no errors.
const emptyProgram = '''
  void main(List<String> args) {}
''';

/// A simple async Dart script that when stopped at the line of '// BREAKPOINT'
/// will contain SDK frames in the call stack.
const sdkStackFrameProgram = '''
  void main() {
    [0].where((i) {
      return i == 0; $breakpointMarker
    }).toList();
  }
''';

/// A simple Dart script that registers a simple service extension that returns
/// its params and waits until it is called before exiting.
const serviceExtensionProgram = '''
  import 'dart:async';
  import 'dart:convert';
  import 'dart:developer';

  void main(List<String> args) async {
    // Using a completer here causes the VM to quit when the extension is called
    // so use a flag.
    // https://github.com/dart-lang/sdk/issues/47279
    var wasCalled = false;
    registerExtension('ext.service.extension', (method, params) async {
      wasCalled = true;
      return ServiceExtensionResponse.result(jsonEncode(params));
    });
    while (!wasCalled) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
''';

/// A simple Dart script that prints its arguments.
const simpleArgPrintingProgram = r'''
  void main(List<String> args) async {
    print('Hello!');
    print('World!');
    print('args: $args');
  }
''';

/// A simple Dart script that prints to stderr without throwing/terminating.
///
/// The output will contain stack traces include both the supplied file, package
/// and dart URIs.
String stderrPrintingProgram(Uri fileUri, Uri packageUri, Uri dartUri) {
  return '''
  import 'dart:io';
  import '$packageUri';

  void main(List<String> args) async {
    stderr.writeln('Start');
    stderr.writeln('#0      main ($fileUri:1:2)');
    stderr.writeln('#1      main2 ($packageUri:3:4)');
    stderr.writeln('#2      main3 ($dartUri:5:6)');
    stderr.write('End');
    await Future.delayed(const Duration(seconds: 1));
  }
''';
}

/// Returns a simple Dart script that prints the provided string repeatedly.
String stringPrintingProgram(String text) {
  // jsonEncode the string to get it into a quoted/escaped form that can be
  // embedded in the string.
  final encodedTextString = jsonEncode(text);
  return '''
  import 'dart:async';

  main() async {
    Timer.periodic(Duration(milliseconds: 10), (_) => printSomething());
  }

  void printSomething() {
    print($encodedTextString);
  }
''';
}

/// A simple Dart script that just loops forever sleeping for 1 second each
/// iteration.
///
/// A breakpoint marker is included before the loop.
const infiniteRunningProgram = '''
  void main(List<String> args) async {
    print('Looping'); $breakpointMarker
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
''';

/// A Dart script that loops forever sleeping for 1 second each
/// iteration.
///
/// A top-level String variable `myGlobal` is available with the value
/// `"Hello, world!"`.
const globalEvaluationProgram = '''
  var myGlobal = 'Hello, world!';
  void main(List<String> args) async {
    while (true) {
      print('.');
      await Future.delayed(const Duration(seconds: 1));
    }
  }
''';

/// A simple async Dart script that when stopped at the line of '// BREAKPOINT'
/// will contain multiple stack frames across some async boundaries.
const simpleAsyncProgram = '''
  import 'dart:async';

  Future<void> main() async {
    await one();
  }

  Future<void> one() async {
    await two();
  }

  Future<void> two() async {
    await three();
  }

  Future<void> three() async {
    await Future.delayed(const Duration(microseconds: 1));
    four();
  }

  void four() {
    print('!'); $breakpointMarker
  }
''';

/// A simple Dart script that should run with no errors and contains a comment
/// marker '// BREAKPOINT' for use in tests that require stopping at a breakpoint
/// but require no other context.
const simpleBreakpointProgram = '''
  void main(List<String> args) async {
    print('Hello!'); $breakpointMarker
  }
''';

/// A simple Dart script that prints the numbers from 1 to 5.
///
/// A breakpoint marker is on the line that prints '1' and the subsequent 4
/// lines are valid targets for breakpoints.
const simpleMultiBreakpointProgram = '''
  void main(List<String> args) async {
    print('1'); $breakpointMarker
    print('2');
    print('3');
    print('4');
    print('5');
  }
''';

final simpleBreakpointProgramWith50ExtraLines = '''
  void main(List<String> args) async {
    print('Hello!'); $breakpointMarker
    ${'await null;\n' * 50}
  }
''';

/// A Dart script that uses [Isolate.run] to run a short-lived isolate and has
/// a `debugger()` call after the isolate completes to ensure the app does not
/// immediately exit.
const isolateSpawningProgram = '''
  import 'dart:developer';
  import 'dart:isolate';

  Future<void> main() async {
    await Isolate.run(_compute);
    debugger();
  }

  Future<void> _compute() async {}
''';

/// A simple Dart script that should run with no errors and contains a comment
/// marker '// BREAKPOINT' on a blank line where a breakpoint should be resolved
/// to the next line.
const simpleBreakpointResolutionProgram = '''
  void main(List<String> args) async {
    $breakpointMarker
    print('Hello!');
  }
''';

/// A simple Dart script that has a blank line before its breakpoint, used to
/// ensure breakpoints that resolve to the same place are handled correctly.
const simpleBreakpointWithLeadingBlankLineProgram = '''
  void main(List<String> args) async {

    print('Hello!'); $breakpointMarker
  }
''';

/// A simple Dart script that has a breakpoint and an exception used for
/// testing whether breakpoints and exceptions are being paused on (for example
/// during detach where they should not).
const simpleBreakpointAndThrowProgram = '''
  void main(List<String> args) async {
    print('Hello!'); $breakpointMarker
    throw 'error';
  }
''';

/// A simple Dart script that throws an error and catches it in user code.
const simpleCaughtErrorProgram = r'''
  void main(List<String> args) async {
    try {
      throw 'error';
    } catch (e) {
      print('Caught!');
    }
  }
''';

/// A simple package:test script that has a single group named 'group' with
/// tests named 'passing', 'failing' and 'skipped' respectively.
///
/// The 'passing' test contains a [breakpointMarker].
const simpleTestProgram = '''
  import 'package:test/test.dart';

  void main() {
    group('group 1', () {
      test('passing test', () {
        expect(1, equals(1)); $breakpointMarker
      });
      test('failing test', () {
        expect(1, equals(2));
      });
      test('skipped test', () {
        expect(1, equals(2));
      }, skip: true);
    });
  }
''';

/// A simple package:test script with a single failing test.
const simpleFailingTestProgram = '''
  import 'package:test/test.dart';

  void main() {
    test('failing test', () {
      expect(1, equals(2));
    });
  }
''';

/// A simple test that should pass and contains a comment marker
/// '// BREAKPOINT' on a blank line where a breakpoint should be resolved
/// to the next line.
const simpleTestBreakpointResolutionProgram = '''
  import 'package:test/test.dart';

  void main() {
    group('group 1', () {
      test('passing test', () {
        $breakpointMarker
        expect(1, equals(1));
      });
    });
  }
''';

final simpleTestBreakpointProgramWith50ExtraLines = '''
  import 'package:test/test.dart';

  void main() {
    group('group 1', () {
      test('passing test', () async {
        expect(1, equals(1)); $breakpointMarker
        ${'await null;\n' * 50}
      });
    });
  }
''';

/// A simple test that prints the numbers from 1 to 5.
///
/// A breakpoint marker is on the line that prints '1' and the subsequent 4
/// lines are valid targets for breakpoints.
const simpleTestMultiBreakpointProgram = '''
  import 'package:test/test.dart';

  void main() {
    group('group 1', () {
      test('passing test', () {
        print('1'); $breakpointMarker
        print('2');
        print('3');
        print('4');
        print('5');
        expect(1, equals(1));
      });
    });
  }
''';

/// Matches for the expected output of [simpleTestProgram].
final simpleTestProgramExpectedOutput = [
  // First test
  '✓ group 1 passing test',
  // Second test
  'Expected: <2>',
  '  Actual: <1>',
  // These lines contain paths, so just check the non-path parts.
  allOf(startsWith('package:matcher'), endsWith('expect')),
  endsWith('main.<fn>.<fn>'),
  '✖ group 1 failing test',
  '! group 1 skipped test',
  // Exit
  '',
  'Exited (1).',
];

/// A simple Dart script that throws in user code.
const simpleThrowingProgram = r'''
  void main(List<String> args) async {
    throw Exception('error text');
  }
''';

/// A simple Dart script that sends a `navigate` event to the `ToolEvent`
/// stream.
const simpleToolEventProgram = r'''
  import 'dart:developer';

  void main(List<String> args) async {
    postEvent(
      'navigate',
      {
        'uri': 'file:///file.dart',
      },
      stream: 'ToolEvent',
    );
  }
''';

/// A simple Dart script that sends a `navigate` event to the `ToolEvent`
/// stream using a dart:core URI.
const simpleToolEventWithDartCoreUriProgram = r'''
  import 'dart:developer';

  void main(List<String> args) async {
    postEvent(
      'navigate',
      {
        'uri': 'dart:core',
      },
      stream: 'ToolEvent',
    );
    // resolving postEvent URIs is async, so we need to ensure the program
    // does not immediately terminate. The test script should terminate it when
    // it has had the event.
    await Future.delayed(const Duration(seconds: 10));
  }
''';

/// A marker used in some test scripts/tests for where to expected steps.
const stepMarker = '// STEP';
