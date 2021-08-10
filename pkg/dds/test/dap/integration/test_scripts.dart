// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A simple empty Dart script that should run with no output and no errors.
const emptyProgram = '''
  void main(List<String> args) {}
''';

/// A simple Dart script that should run with no errors and contains a comment
/// marker '// BREAKPOINT' for use in tests that require stopping at a breakpoint
/// but require no other context.
const simpleBreakpointProgram = r'''
  void main(List<String> args) async {
    print('Hello!'); // BREAKPOINT
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
