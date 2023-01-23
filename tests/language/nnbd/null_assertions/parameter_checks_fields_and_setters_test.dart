// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for null assertions for parameters in NNBD weak mode.

// Requirements=nnbd-weak
// VMOptions=--enable-asserts -DcheckString=false
// dart2jsOptions=--enable-asserts -DcheckString=false
// SharedOptions=--null-assertions

// Opt out of Null Safety:
// @dart = 2.6

import "package:expect/expect.dart";

import 'parameter_checks_opted_in.dart' as null_safe;

bool Function(Object) asserted(String name) {
  if (const bool.fromEnvironment('checkString', defaultValue: true)) {
    return (e) => e is AssertionError && e.toString().contains("$name != null");
  } else {
    return (e) => e is AssertionError;
  }
}

void use(bool x) {
  if (x != null && x) {
    print('hey');
  }
}

bool topLevelField = false;
int get topLevelGetterSetterPair => 0;
set topLevelGetterSetterPair(int i) => null;
set topLevelSetterOnly(String s) => null;

abstract class Abs {
  int field;
  Abs([int init]) {
    field = init ?? 20;
  }
}

class Impl extends Abs {
  @override
  final int field;

  Impl([int init])
      : field = init ?? 10,
        super();
}

// NOTE - All class definitions should be identical to the same implementations
// in the null safe library so the difference in behavior can be observed.

/// Base class.
class A {
  int get getterSetterPair => 0;
  set getterSetterPair(int i) => null;
  set setterOnly(String s) => null;
  int field = 0;
  static bool staticField = false;
  static int get staticGetterSetterPair => 0;
  static set staticGetterSetterPair(int i) => null;
  static set staticSetterOnly(String s) => null;

  void instanceMethod(String s) => print(s);
  static void staticMethod(String s) => print(s);
}

/// Overrides the getters but inherits the setters.
class B extends null_safe.A {
  @override
  int get getterSetterPair => 999;
  @override
  int get field => 999;
}

/// Overrides the setters.
class C extends null_safe.A {
  @override
  set getterSetterPair(int i) => null;
  @override
  set setterOnly(String s) => null;
  @override
  set field(int i) => null;
}

/// Overrides field with a field.
class D extends null_safe.A {
  @override
  int field = 10;
}

main() {
  // Top level definitions in opted out library allow null without errors.
  topLevelField = null;
  use(topLevelField); // Make sure topLevelField is not tree-shaken.
  topLevelGetterSetterPair = null;
  topLevelSetterOnly = null;

  // Same definitions in a null safe library throw when set to null.
  Expect.throws(() {
    null_safe.topLevelField = null;
  }, asserted('topLevelField'));
  use(null_safe.topLevelField); // Make sure topLevelField is not tree-shaken.
  Expect.throws(() {
    null_safe.topLevelGetterSetterPair = null;
  }, asserted('i'));
  Expect.throws(() {
    null_safe.topLevelSetterOnly = null;
  }, asserted('s'));

  // Class defined in opted out library allows null.
  var a = A();
  a.getterSetterPair = null;
  a.setterOnly = null;
  a.field = null;
  A.staticGetterSetterPair = null;
  A.staticSetterOnly = null;
  A.staticField = null;
  use(A.staticField); // Make sure A.staticField is not tree-shaken.

  // Same class as above defined in a null safe library, throws on null.
  var nullSafeA = null_safe.A();
  Expect.throws(() {
    nullSafeA.getterSetterPair = null;
  }, asserted('i'));
  Expect.throws(() {
    nullSafeA.setterOnly = null;
  }, asserted('s'));
  Expect.throws(() {
    nullSafeA.field = null;
  }, asserted('field'));
  Expect.throws(() {
    null_safe.A.staticGetterSetterPair = null;
  }, asserted('i'));
  Expect.throws(() {
    null_safe.A.staticSetterOnly = null;
  }, asserted('s'));
  Expect.throws(() {
    null_safe.A.staticField = null;
  }, asserted('staticField'));
  use(null_safe.A.staticField); // Make sure A.staticField is not tree-shaken.

  // Class defined in opted out library overrides getters but inherited
  // implementations throw.
  var b = B();
  Expect.throws(() {
    b.getterSetterPair = null;
  }, asserted('i'));
  Expect.throws(() {
    b.setterOnly = null;
  }, asserted('s'));
  Expect.throws(() {
    b.field = null;
  }, asserted('field'));

  // Same class as above defined in and inherited from null safe library throw.
  var nullSafeB = null_safe.B();
  // Should not throw because the inherited setter does allow null even though
  // the getter has an override and is non-nullable.
  nullSafeB.nullableField = null;
  Expect.throws(() {
    nullSafeB.getterSetterPair = null;
  }, asserted('i'));
  Expect.throws(() {
    nullSafeB.setterOnly = null;
  }, asserted('s'));
  Expect.throws(() {
    nullSafeB.field = null;
  }, asserted('field'));

  // Class defined in opted out library, overrides all setters, doesn't throw.
  var c = C();
  c.getterSetterPair = null;
  c.setterOnly = null;
  c.field = null;

  // Same class as above defined in null safe library throws.
  var nullSafeC = null_safe.C();
  Expect.throws(() {
    nullSafeC.getterSetterPair = null;
  }, asserted('i'));
  Expect.throws(() {
    nullSafeC.setterOnly = null;
  }, asserted('s'));
  Expect.throws(() {
    nullSafeC.field = null;
  }, asserted('i'));

  // Class defined in opted out library overrides field, doesn't throw.
  var d = D();
  d.field = null;

  // Same class as above defined in null safe library throws.
  var nullSafeD = null_safe.D();
  // Should not throw because the inherited setters do allow null even though
  // the getter has an override and is non-nullable.
  nullSafeD.nullableField = null;
  nullSafeD.nullableGetterSetterPair = null;
  Expect.throws(() {
    nullSafeD.field = null;
  }, asserted('field'));

  var s = Impl();
  // Should not throw because the setter is defined in a library that has not
  // yet migrated to null safety.
  //
  // The Impl class has no setter, but the field has a setterType of `Never`
  // which is non-nullable. This acts as a regression test to ensure we don't
  // introduce a null check because of the strange setter type.
  s.field = null;
}
