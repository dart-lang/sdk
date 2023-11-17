// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for dangling-else detection when the then-part has a label. The
// then-part of an if-then-else statement sometimes needs to be wrapped in a
// block to avoid an inner if-then 'capturing' the else part.

import 'dart:convert';
import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';

void check1(String expected, Statement then) {
  final actual = DebugPrint(
      If(VariableUse('x'), then, ExpressionStatement(VariableUse('E'))));
  Expect.equals(
      expected,
      actual,
      '\n'
      '\nexpected ${json.encode(expected)}'
      '\nactual:  ${json.encode(actual)}');
}

void check(String expected, Statement then1,
    [Statement? then2, Statement? then3, Statement? then4]) {
  check1(expected, then1);
  if (then2 != null) check1(expected, then2);
  if (then3 != null) check1(expected, then3);
  if (then4 != null) check1(expected, then4);
}

void main() {
  final y = VariableUse('y');
  final z = VariableUse('z');
  final S1 = ExpressionStatement(VariableUse('S1'));
  final S2 = ExpressionStatement(VariableUse('S2'));

  check(
    r'''
if (x)
  L:
    if (y)
      S1;
    else
      S2;
else
  E;
''',
    LabeledStatement('L', If(y, S1, S2)),
  );

  check(
    r'''
if (x) {
  L:
    if (y)
      S1;
    else
      S2;
} else
  E;
''',
    Block([LabeledStatement('L', If(y, S1, S2))]),
  );

  check(
    r'''
if (x)
  L: {
    if (y)
      S1;
    else
      S2;
  }
else
  E;
''',
    LabeledStatement('L', Block([If(y, S1, S2)])),
  );

  check(
    r'''
if (x) {
  L:
    if (y)
      S1;
} else
  E;
''',
    LabeledStatement('L', If.noElse(y, S1)),
    Block([LabeledStatement('L', If.noElse(y, S1))]),
  );

  check(
    r'''
if (x) {
  L: {
    if (y)
      S1;
  }
} else
  E;
''',
    LabeledStatement('L', Block([If.noElse(y, S1)])),
  );

  check(
    r'''
if (x)
  L: {
    if (y)
      S1;
    S2;
  }
else
  E;
''',
    LabeledStatement('L', Block([If.noElse(y, S1), S2])),
  );

  check(
    r'''
if (x) {
  L:
    if (y)
      S1;
    else if (z)
      S2;
} else
  E;
''',
    LabeledStatement('L', If(y, S1, If.noElse(z, S2))),
    Block([LabeledStatement('L', If(y, S1, If.noElse(z, S2)))]),
  );

  check(
    r'''
if (x) {
  L: {
    if (y)
      S1;
    else if (z)
      S2;
  }
} else
  E;
''',
    LabeledStatement('L', Block([If(y, S1, If.noElse(z, S2))])),
  );

  check(
    r'''
if (x) {
  L:
    if (y)
      S1;
    else {
      if (z)
        S2;
    }
} else
  E;
''',
    LabeledStatement('L', If(y, S1, Block([If.noElse(z, S2)]))),
    Block([
      LabeledStatement('L', If(y, S1, Block([If.noElse(z, S2)])))
    ]),
  );

  check(
    r'''
if (x) {
  L:
    while (y)
      if (z)
        S1;
} else
  E;
''',
    LabeledStatement('L', While(y, If.noElse(z, S1))),
    Block([LabeledStatement('L', While(y, If.noElse(z, S1)))]),
  );

  check(
    r'''
if (x) {
  L: {
    while (y)
      if (z)
        S1;
  }
} else
  E;
''',
    LabeledStatement('L', Block([While(y, If.noElse(z, S1))])),
  );

  check(
    r'''
if (x) {
  L:
    while (y) {
      if (z)
        S1;
    }
} else
  E;
''',
    LabeledStatement('L', While(y, Block([If.noElse(z, S1)]))),
  );

  check(
    r'''
if (x) {
  L:
    for (;;)
      if (z)
        S1;
} else
  E;
''',
    LabeledStatement('L', For(null, null, null, If.noElse(z, S1))),
    Block([LabeledStatement('L', For(null, null, null, If.noElse(z, S1)))]),
  );

  check(
    r'''
if (x) {
  L: {
    for (;;)
      if (z)
        S1;
  }
} else
  E;
''',
    LabeledStatement('L', Block([For(null, null, null, If.noElse(z, S1))])),
  );

  check(
    r'''
if (x) {
  L:
    for (;;) {
      if (z)
        S1;
    }
} else
  E;
''',
    LabeledStatement('L', For(null, null, null, Block([If.noElse(z, S1)]))),
  );
}
