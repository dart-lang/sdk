// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test test/rule_test.dart -N avoid_dynamic_calls`

import 'dart:core';
import 'dart:core' as core_top_level_prefix_as;

void explicitDynamicType(dynamic object) {
  object.foo(); // LINT
  object.bar; // LINT
}

void implicitDynamicType(object) {
  object.foo(); // LINT
  object.bar; // LINT
}

// This would likely not pass at runtime, but we're using it for inference only.
T genericType<T>() => null as T;

void inferredDynamicType() {
  var object = genericType();
  object.foo(); // LINT
  object.bar; // LINT
}

class Wrapper<T> {
  final T field;
  Wrapper(this.field);
}

void fieldDynamicType(Wrapper<dynamic> wrapper) {
  wrapper.field.foo(); // LINT
  wrapper.field.bar; // LINT
  wrapper.field(); // LINT
  (wrapper.field)(); // LINT
}

void cascadeExpressions(dynamic a, Wrapper<dynamic> b) {
  a..b; // LINT
  b..field; // OK
  b
    ..toString
    ..field.a() // LINT
    ..field.b; // LINT
}

class TearOffFunction {
  static int staticDoThing() => 0;

  int doThing() => 0;
}

void otherPropertyAccessOrCalls(dynamic a) {
  a(); // LINT
  a?.b; // LINT
  a!.b; // LINT
  a?.b(); // LINT
  a!.b(); // LINT
  (a).b; // LINT
}

void tearOffFunctions(TearOffFunction a) {
  var p = core_top_level_prefix_as.print; // OK
  core_top_level_prefix_as.print('Hello'); // OK
  p('Hello'); // OK
  var doThing = a.doThing; // OK
  doThing(); // OK
  var staticDoThing = TearOffFunction.staticDoThing; // OK
  staticDoThing(); // OK
  identical(true, false); // OK
  var alsoIdentical = identical;
  alsoIdentical(true, false); // OK
}

typedef F = void Function();

void functionExpressionInvocations(
  dynamic a(),
  Function b(),
  void Function() c,
  d(),
  F f,
  F? fn,
) {
  a(); // OK
  a()(); // LINT
  b(); // OK
  b()(); // LINT
  c(); // OK
  d(); // OK
  f.call; // OK
  f.call(); // OK
  fn?.call; // OK
  fn?.call(); // OK
}

void typedFunctionButBasicallyDynamic(Function a, Wrapper<Function> b) {
  a(); // LINT
  b.field(); // LINT
  (b.field)(); // LINT
  a.call; // OK
  a.call(); // LINT
}

void binaryExpressions(dynamic a, int b, bool c) {
  a + a; // LINT
  a + b; // LINT
  a > b; // LINT
  a < b; // LINT
  a >= b; // LINT
  a <= b; // LINT
  a ^ b; // LINT
  a | b; // LINT
  a & b; // LINT
  a % b; // LINT
  a / b; // LINT
  a ~/ b; // LINT
  a >> b; // LINT
  a << b; // LINT
  a || c; // OK; this is an implicit downcast, not a dynamic call
  a && c; // OK; this is an implicit downcast, not a dynamic call
  b + a; // OK; this is an implicit downcast, not a dynamic call
  a ?? b; // OK; this is a null comparison, not a dynamic call.
  a is int; // OK
  a is! int; // OK
  a as int; // OK
}

void equalityExpressions(dynamic a, dynamic b) {
  a == b; // OK, see lint description for details.
  a == null; // OK.
  a != b; // OK
  a != null; // OK.
}

void membersThatExistOnObject(dynamic a, Invocation b) {
  a.hashCode; // OK
  a.runtimeType; // OK
  a.noSuchMethod(); // LINT
  a.noSuchMethod(b); // OK
  a.noSuchMethod(b, 1); // LINT
  a.noSuchMethod(b, name: 1); // LINT
  a.toString(); // OK
  a.toString(1); // LINT
  a.toString(name: 1); // LINT
  '$a'; // OK
  '${a}'; // OK
}

void memberTearOffsOnObject(dynamic a, Invocation b) {
  var tearOffNoSuchMethod = a.noSuchMethod; // OK
  tearOffNoSuchMethod(b); // OK
  var tearOffToString = a.toString; // OK
  tearOffToString(); // OK
}

void assignmentExpressions(dynamic a) {
  a += 1; // LINT
  a -= 1; // LINT
  a *= 1; // LINT
  a ^= 1; // LINT
  a /= 1; // LINT
  a &= 1; // LINT
  a |= 1; // LINT
  a ??= 1; // OK
}

void prefixExpressions(dynamic a, int b) {
  !a; // LINT
  -a; // LINT
  ++a; // LINT
  --a; // LINT
  ++b; // OK
  --b; // OK
}

void postfixExpressions(dynamic a, int b) {
  a!; // OK; this is not a dynamic call.
  a++; // LINT
  a--; // LINT
  b++; // OK
  b--; // OK
}

void indexExpressions(dynamic a) {
  a[1]; // LINT
  a[1] = 1; // LINT
  a = a[1]; // LINT
}
