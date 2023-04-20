// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

/// Variables declared by a pattern are in scope in the guard.
import "package:expect/expect.dart";

var a = 'outer';

void main() {
  testSwitchStatement();
  testSwitchExpression();
  testIfCaseStatement();
  testIfCaseElement();
}

void testSwitchStatement() {
  switch ('value') {
    case var a when _guard(a):
      break;
  }

  _expectGuard('value');
}

void testSwitchExpression() {
  (switch ('value') { var a when _guard(a) => 'body', _ => 'other' });

  _expectGuard('value');
}

void testIfCaseStatement() {
  if ('value' case var a when _guard(a)) {}

  _expectGuard('value');
}

void testIfCaseElement() {
  var list = [if ('value' case var a when _guard(a)) 'element'];

  _expectGuard('value');
}

String _guardArg = '';

bool _guard(String arg) {
  _guardArg = arg;
  return true;
}

void _expectGuard(String expected) {
  Expect.equals(expected, _guardArg);
  _guardArg = '';
}
