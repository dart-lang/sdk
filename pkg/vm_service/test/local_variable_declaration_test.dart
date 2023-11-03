// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 19;
const LINE_B = LINE_A + 9;
const LINE_C = LINE_B + 5;

void testParameters(int jjjj, int oooo, [int? hhhh, int? nnnn]) {
  debugger(); // LINE_A
}

void testMain() {
  // ignore: unused_local_variable
  int? xxx, yyyy, zzzzz;
  for (int i = 0; i < 1; i++) {
    // ignore: unused_local_variable
    final foo = () {};
    debugger(); // LINE_B
  }
  final bar = () {
    print(xxx);
    print(yyyy);
    debugger(); // LINE_C
  };
  bar();
  testParameters(0, 0);
}

String? getLine(Script script, int line) {
  final index = line - script.lineOffset! - 1;
  final lines = script.source!.split('\n');
  if (lines.length < index) {
    return null;
  }
  return lines[index];
}

String? getToken(Script script, int tokenPos) {
  final line = script.getLineNumberFromTokenPos(tokenPos);
  int? col = script.getColumnNumberFromTokenPos(tokenPos);
  if ((line == null) || (col == null)) {
    return null;
  }
  // Line and column numbers start at 1 in the VM.
  --col;
  final sourceLine = getLine(script, line);
  if (sourceLine == null) {
    return null;
  }
  final length = guessTokenLength(script, line, col);
  if (length == null) {
    return sourceLine.substring(col);
  }
  return sourceLine.substring(col, col + length);
}

bool _isOperatorChar(int c) {
  switch (c) {
    case 25: // %
    case 26: // &
    case 42: // *
    case 43: // +
    case 45: // -:
    case 47: // /
    case 60: // <
    case 61: // =
    case 62: // >
    case 94: // ^
    case 124: // |
    case 126: // ~
      return true;
    default:
      return false;
  }
}

bool _isInitialIdentifierChar(int c) {
  if (c >= 65 && c <= 90) return true; // Upper
  if (c >= 97 && c <= 122) return true; // Lower
  if (c == 95) return true; // Underscore
  if (c == 36) return true; // Dollar
  return false;
}

bool _isIdentifierChar(int c) {
  if (_isInitialIdentifierChar(c)) return true;
  return c >= 48 && c <= 57; // Digit
}

int? guessTokenLength(Script script, int line, int column) {
  String source = getLine(script, line)!;

  int pos = column;
  if (pos >= source.length) {
    return null;
  }

  final c = source.codeUnitAt(pos);
  if (c == 123) return 1; // { - Map literal

  if (c == 91) return 1; // [ - List literal, index, index assignment

  if (c == 40) return 1; // ( - Closure call

  if (_isOperatorChar(c)) {
    while (++pos < source.length && _isOperatorChar(source.codeUnitAt(pos)));
    return pos - column;
  }

  if (_isInitialIdentifierChar(c)) {
    while (++pos < source.length && _isIdentifierChar(source.codeUnitAt(pos)));
    return pos - column;
  }

  return null;
}

Future<void> verifyVariables(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final stack = await service.getStack(isolateId);
  final frames = stack.frames!;
  expect(frames.length, greaterThanOrEqualTo(1));
  // Grab the top frame.
  final frame = frames.first;
  // Grab the script.
  final script = await service.getObject(
    isolateId,
    frame.location!.script!.id!,
  ) as Script;

  // Ensure that the token at each declaration position is the name of the
  // variable.
  final variables = frame.vars!;
  for (final variable in variables) {
    final declarationTokenPos = variable.declarationTokenPos!;
    final name = variable.name!;
    final token = getToken(script, declarationTokenPos);
    // When running from an appjit snapshot, sources aren't available so the returned token will
    // be null.
    if (token != null) {
      expect(name, token);
    }
  }
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  verifyVariables,
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  // We have stopped in the anonymous closure assigned to bar. Verify that
  // variables captured in the context have valid declaration positions.
  verifyVariables,
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  verifyVariables,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'local_variable_declaration_test.dart',
      testeeConcurrent: testMain,
    );
