// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'impl/assert_in_declarations_phase_macro.dart';

@AssertInDeclarationsPhase(
  targetName: 'B',
  constructorsOf: ['b()'],
  expectThrowsA: 'MacroIntrospectionCycleExceptionImpl',
)
class A {
  A.a();
}

@AssertInDeclarationsPhase(
  targetName: 'A',
  constructorsOf: ['a()'],
  expectThrowsA: 'MacroIntrospectionCycleExceptionImpl',
)
class B {
  B.b();
}

void main() {}
