// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_client.dart';
import 'test_support.dart';

main() {
  testDap((dap) async {
    group('debug mode variables', () {
      test('provides variable list for frames', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  final myVariable = 1;
  foo();
}

void foo() {
  final b = 2;
  print('Hello!'); // BREAKPOINT
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final stack = await client.getValidStack(
          stop.threadId!,
          startFrame: 0,
          numFrames: 2,
        );

        // Check top two frames (in `foo` and in `main`).
        await client.expectScopeVariables(
          stack.stackFrames[0].id, // Top frame: foo
          'Variables',
          '''
            b: 2
          ''',
        );
        await client.expectScopeVariables(
          stack.stackFrames[1].id, // Second frame: main
          'Variables',
          '''
            args: List (0 items)
            myVariable: 1
          ''',
        );
      });

      test('provides simple exception types for frames', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  throw 'my error';
}
    ''');

        final stop = await client.hitException(testFile);
        final stack = await client.getValidStack(
          stop.threadId!,
          startFrame: 0,
          numFrames: 1,
        );
        final topFrameId = stack.stackFrames.first.id;

        // Check for an additional Scope named "Exceptions" that includes the
        // exception.
        await client.expectScopeVariables(
          topFrameId,
          'Exceptions',
          '''
            String: "my error"
          ''',
        );
      });

      test('provides complex exception types frames', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  throw ArgumentError.notNull('args');
}
    ''');

        final stop = await client.hitException(testFile);
        final stack = await client.getValidStack(
          stop.threadId!,
          startFrame: 0,
          numFrames: 1,
        );
        final topFrameId = stack.stackFrames.first.id;

        // Check for an additional Scope named "Exceptions" that includes the
        // exception.
        await client.expectScopeVariables(
          topFrameId,
          'Exceptions',
          // TODO(dantup): evaluateNames
          '''
            invalidValue: null
            message: "Must not be null"
            name: "args"
          ''',
        );
      });

      test('includes simple variable fields', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  final myVariable = DateTime(2000, 1, 1);
  print('Hello!'); // BREAKPOINT
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        await client.expectLocalVariable(
          stop.threadId!,
          expectedName: 'myVariable',
          expectedDisplayString: 'DateTime',
          expectedVariables: '''
            isUtc: false
          ''',
        );
      });

      test('includes variable getters when evaluateGettersInDebugViews=true',
          () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  final myVariable = DateTime(2000, 1, 1);
  print('Hello!'); // BREAKPOINT
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(
          testFile,
          breakpointLine,
          launch: () => client.launch(
            testFile.path,
            evaluateGettersInDebugViews: true,
          ),
        );
        await client.expectLocalVariable(
          stop.threadId!,
          expectedName: 'myVariable',
          expectedDisplayString: 'DateTime',
          expectedVariables: '''
            day: 1
            hour: 0
            isUtc: false
            microsecond: 0
            millisecond: 0
            minute: 0
            month: 1
            runtimeType: Type (DateTime)
            second: 0
            timeZoneOffset: Duration
            weekday: 6
            year: 2000
          ''',
          ignore: {
            // Don't check fields that may very based on timezone as it'll make
            // these tests fragile, and this isn't really what's being tested.
            'timeZoneName',
            'microsecondsSinceEpoch',
            'millisecondsSinceEpoch',
          },
        );
      });

      test('renders a simple list', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  final myVariable = ["first", "second", "third"];
  print('Hello!'); // BREAKPOINT
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        await client.expectLocalVariable(
          stop.threadId!,
          expectedName: 'myVariable',
          expectedDisplayString: 'List (3 items)',
          // TODO(dantup): evaluateNames
          expectedVariables: '''
            0: "first"
            1: "second"
            2: "third"
          ''',
        );
      });

      test('renders a simple list subset', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  final myVariable = ["first", "second", "third"];
  print('Hello!'); // BREAKPOINT
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        await client.expectLocalVariable(
          stop.threadId!,
          expectedName: 'myVariable',
          expectedDisplayString: 'List (3 items)',
          // TODO(dantup): evaluateNames
          expectedVariables: '''
            1: "second"
          ''',
          start: 1,
          count: 1,
        );
      });

      test('renders a simple map', () {
        // TODO(dantup): Implement this (inc evaluateNames)
      }, skip: true);

      test('renders a simple map subset', () {
        // TODO(dantup): Implement this (inc evaluateNames)
      }, skip: true);
      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);
  });
}
