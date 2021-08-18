// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/// A simple Dart script that throws in user code.
const simpleThrowingProgram = r'''
  void main(List<String> args) async {
    throw 'error';
  }
''';

/// A marker used in some test scripts/tests for where to expected steps.
const stepMarker = '// STEP';
