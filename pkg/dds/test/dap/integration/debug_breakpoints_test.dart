// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  testDap((dap) async {
    group('debug mode breakpoints', () {
      test('stops at a line breakpoint', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        await client.hitBreakpoint(testFile, breakpointLine);
      });

      test('stops at a line breakpoint and can be resumed', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        // Hit the initial breakpoint.
        final stop = await client.hitBreakpoint(testFile, breakpointLine);

        // Resume and expect termination (as the script will get to the end).
        await Future.wait([
          client.event('terminated'),
          client.continue_(stop.threadId!),
        ], eagerError: true);
      });

      test('stops at a line breakpoint and can step over (next)', () async {
        final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  print('Hello!'); // BREAKPOINT
  print('Hello!'); // STEP
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');
        final stepLine = lineWith(testFile, '// STEP');

        // Hit the initial breakpoint.
        final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

        // Step and expect stopping on the next line with a 'step' stop type.
        await Future.wait([
          dap.client.expectStop('step', file: testFile, line: stepLine),
          dap.client.next(stop.threadId!),
        ], eagerError: true);
      });

      test(
          'stops at a line breakpoint and can step over (next) an async boundary',
          () async {
        final client = dap.client;
        final testFile = dap.createTestFile(r'''
Future<void> main(List<String> args) async {
  await asyncPrint('Hello!'); // BREAKPOINT
  await asyncPrint('Hello!'); // STEP
}

Future<void> asyncPrint(String message) async {
  await Future.delayed(const Duration(milliseconds: 1));
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');
        final stepLine = lineWith(testFile, '// STEP');

        // Hit the initial breakpoint.
        final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

        // The first step will move from `asyncPrint` to the `await`.
        await Future.wait([
          client.expectStop('step', file: testFile, line: breakpointLine),
          client.next(stop.threadId!),
        ], eagerError: true);

        // The next step should go over the async boundary and to stepLine (if
        // we did not correctly send kOverAsyncSuspension we would end up in
        // the asyncPrint method).
        await Future.wait([
          client.expectStop('step', file: testFile, line: stepLine),
          client.next(stop.threadId!),
        ], eagerError: true);
      });

      test('stops at a line breakpoint and can step in', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  log('Hello!'); // BREAKPOINT
}

void log(String message) { // STEP
  print(message);
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');
        final stepLine = lineWith(testFile, '// STEP');

        // Hit the initial breakpoint.
        final stop = await client.hitBreakpoint(testFile, breakpointLine);

        // Step and expect stopping in the inner function with a 'step' stop type.
        await Future.wait([
          client.expectStop('step', file: testFile, line: stepLine),
          client.stepIn(stop.threadId!),
        ], eagerError: true);
      });

      test('stops at a line breakpoint and can step out', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  log('Hello!');
  log('Hello!'); // STEP
}

void log(String message) {
  print(message); // BREAKPOINT
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');
        final stepLine = lineWith(testFile, '// STEP');

        // Hit the initial breakpoint.
        final stop = await client.hitBreakpoint(testFile, breakpointLine);

        // Step and expect stopping in the inner function with a 'step' stop type.
        await Future.wait([
          client.expectStop('step', file: testFile, line: stepLine),
          client.stepOut(stop.threadId!),
        ], eagerError: true);
      });

      test('does not step into SDK code with debugSdkLibraries=false',
          () async {
        final client = dap.client;
        final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  print('Hello!'); // BREAKPOINT
  print('Hello!'); // STEP
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');
        final stepLine = lineWith(testFile, '// STEP');

        // Hit the initial breakpoint.
        final stop = await client.hitBreakpoint(testFile, breakpointLine);

        // Step in and expect stopping on the next line (don't go into print).
        await Future.wait([
          client.expectStop('step', file: testFile, line: stepLine),
          client.stepIn(stop.threadId!),
        ], eagerError: true);
      });

      test('steps into SDK code with debugSdkLibraries=true', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  print('Hello!'); // BREAKPOINT
  print('Hello!');
}
    ''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        // Hit the initial breakpoint.
        final stop = await dap.client.hitBreakpoint(
          testFile,
          breakpointLine,
          launch: () => client.launch(
            testFile.path,
            debugSdkLibraries: true,
          ),
        );

        // Step in and expect to go into print.
        await Future.wait([
          client.expectStop('step', sourceName: 'dart:core/print.dart'),
          client.stepIn(stop.threadId!),
        ], eagerError: true);
      });

      test(
          'does not step into external package code with debugExternalPackageLibraries=false',
          () {
        // TODO(dantup): Support for debugExternalPackageLibraries
      }, skip: true);

      test(
          'steps into external package code with debugExternalPackageLibraries=true',
          () {
        // TODO(dantup): Support for debugExternalPackageLibraries
      }, skip: true);

      test('allows changing debug settings during session', () {
        // TODO(dantup): !
        // Dart-Code's DAP has a custom method that allows an editor to change
        // the debug settings (debugSdkLibraries/debugExternalPackageLibraries)
        // during a debug session.
      }, skip: true);
      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);
  });
}
