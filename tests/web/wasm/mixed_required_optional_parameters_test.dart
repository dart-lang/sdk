// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  testNamedParameters();
  testPositionalParameters();
}

void testNamedParameters() {
  final reqNamed0 = getRequiredNamed(opaque(0));
  final reqNamed1 = getRequiredNamed(opaque(1));
  final reqNamed2 = getRequiredNamed(opaque(2));

  // Interface calls with arguments on required interface
  Expect.equals(42, reqNamed0(value: 42));
  Expect.equals(42, reqNamed1(value: 42));
  Expect.equals(42, reqNamed2(value: 42));

  final optNamed0 = getOptionalNamed(opaque(0));
  final optNamed1 = getOptionalNamed(opaque(1));

  // Interface calls with arguments on optional interface
  Expect.equals(42, optNamed0(value: 42));
  Expect.equals(42, optNamed1(value: 42));

  // Interface calls without arguments on optional interface
  Expect.equals(1, optNamed0());
  Expect.equals(2, optNamed1());

  // Dynamic calls with arguments
  final dynamic dynNamed0 = opaqueTrue ? reqNamed0 : Object();
  final dynamic dynNamed1 = opaqueTrue ? reqNamed1 : Object();
  final dynamic dynNamed2 = opaqueTrue ? reqNamed2 : Object();
  Expect.equals(42, dynNamed0(value: 42));
  Expect.equals(42, dynNamed1(value: 42));
  Expect.equals(42, dynNamed2(value: 42));

  // Dynamic calls with omitted optional arguments
  Expect.equals(1, dynNamed1());
  Expect.equals(2, dynNamed2());
  Expect.throws<NoSuchMethodError>(() => dynNamed0());
}

void testPositionalParameters() {
  final reqPos0 = getRequiredPositional(opaque(0));
  final reqPos1 = getRequiredPositional(opaque(1));
  final reqPos2 = getRequiredPositional(opaque(2));

  // Interface calls with arguments on required interface
  Expect.equals(42, reqPos0(42));
  Expect.equals(42, reqPos1(42));
  Expect.equals(42, reqPos2(42));

  final optPos0 = getOptionalPositional(opaque(0));
  final optPos1 = getOptionalPositional(opaque(1));

  // Interface calls with arguments on optional interface
  Expect.equals(42, optPos0(42));
  Expect.equals(42, optPos1(42));

  // Interface calls without arguments on optional interface
  Expect.equals(10, optPos0());
  Expect.equals(20, optPos1());

  // Dynamic calls with arguments
  final dynamic dynPos0 = opaqueTrue ? reqPos0 : Object();
  final dynamic dynPos1 = opaqueTrue ? reqPos1 : Object();
  final dynamic dynPos2 = opaqueTrue ? reqPos2 : Object();
  Expect.equals(42, dynPos0(42));
  Expect.equals(42, dynPos1(42));
  Expect.equals(42, dynPos2(42));

  // Dynamic calls with omitted optional arguments
  Expect.equals(10, dynPos1());
  Expect.equals(20, dynPos2());
  Expect.throws<NoSuchMethodError>(() => dynPos0());
}

int opaque(int value) => int.parse('$value');
final bool opaqueTrue = int.parse('1') == 1;

RequiredNamedCallable getRequiredNamed(int i) {
  if (i == 0) return RequiredNamed();
  if (i == 1) return OptionalNamedOne();
  return OptionalNamedTwo();
}

OptionalNamedCallable getOptionalNamed(int i) {
  if (i == 0) return OptionalNamedOne();
  return OptionalNamedTwo();
}

RequiredPositionalCallable getRequiredPositional(int i) {
  if (i == 0) return RequiredPositional();
  if (i == 1) return OptionalPositionalOne();
  return OptionalPositionalTwo();
}

OptionalPositionalCallable getOptionalPositional(int i) {
  if (i == 0) return OptionalPositionalOne();
  return OptionalPositionalTwo();
}

abstract class RequiredNamedCallable {
  int call({required int value});
}

abstract class OptionalNamedCallable {
  int call({int value = 100});
}

class RequiredNamed implements RequiredNamedCallable {
  @override
  int call({required int value}) => value;
}

class OptionalNamedOne implements RequiredNamedCallable, OptionalNamedCallable {
  @override
  int call({int value = 1}) => value;
}

class OptionalNamedTwo implements RequiredNamedCallable, OptionalNamedCallable {
  @override
  int call({int value = 2}) => value;
}

abstract class RequiredPositionalCallable {
  int call(int value);
}

abstract class OptionalPositionalCallable {
  int call([int value = 100]);
}

class RequiredPositional implements RequiredPositionalCallable {
  @override
  int call(int value) => value;
}

class OptionalPositionalOne
    implements RequiredPositionalCallable, OptionalPositionalCallable {
  @override
  int call([int value = 10]) => value;
}

class OptionalPositionalTwo
    implements RequiredPositionalCallable, OptionalPositionalCallable {
  @override
  int call([int value = 20]) => value;
}
