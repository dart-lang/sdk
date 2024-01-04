// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'impl/assert_in_declarations_phase_macro.dart';
import 'impl/assert_in_definitions_phase_macro.dart';
import 'impl/assert_in_types_phase_macro.dart';

@AssertInTypesPhase(
  targetLibrary: 'dart:core',
  targetName: 'int',
  resolveIdentifier: 'int',
)
@AssertInDefinitionsPhase(
  targetName: 'A',
  constructorsOf: ['()', 'b()', 'c()'],
  fieldsOf: ['int d', 'String e'],
  methodsOf: ['int f()', 'String g()'],
)
@AssertInDeclarationsPhase(
  targetName: 'A',
  constructorsOf: ['()', 'b()', 'c()'],
  fieldsOf: ['int d', 'String e'],
  methodsOf: ['int f()', 'String g()'],
)
abstract class A {
  A();
  A.b();
  A.c();

  final int d = 1;
  final String e = 'two';

  int f();
  String g();
}

abstract class B {
  B();
  B.h();
  B.i();

  final int j = 1;
  final String k = 'two';

  int l();
  String m();
}

@AssertInDefinitionsPhase(
  targetName: 'B',
  constructorsOf: ['()', 'h()', 'i()'],
  fieldsOf: ['int j', 'String k'],
  methodsOf: ['int l()', 'String m()'],
)
@AssertInDeclarationsPhase(
  targetName: 'B',
  constructorsOf: ['()', 'h()', 'i()'],
  fieldsOf: ['int j', 'String k'],
  methodsOf: ['int l()', 'String m()'],
)
class C {}

void main() {}
