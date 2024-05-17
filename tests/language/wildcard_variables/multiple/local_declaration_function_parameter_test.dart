// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests multiple wildcard function parameters.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

class Constructor {
  final _;

  // TODO(kallentu): Update this once the behaviour of super._ is finalized.
  // https://github.com/dart-lang/language/issues/3792
  Constructor.multiple(_, this._, void _()) {}
  Constructor.parameter(_, _, this._) {}
  Constructor.functionType(this._, void _(), void _()) {}
}

bool topLevelFunction(int _, int _) => true;
bool topLevelFunction2(_, _) => true;
bool topLevelFunction_functionType(void _(), void _()) => true;

class InstanceMethod {
  bool instanceMethod(int _, int _) => true;
  bool instanceMethod2(_, _) => true;
  bool instanceMethod_functionType(void _(), void _()) => true;

  // User-defined operators
  int operator +(int _) => 42;
  void operator []=(int _, _) {}

  // Inherited `Object` methods
  dynamic noSuchMethod(Invocation _) => true;
  bool operator ==(Object _) => true;
}

abstract class AbstractMethod {
  bool abstractMethod(int _, int _);
  bool abstractMethod2(_, _);
  bool abstractMethod_functionType(void _(), void _());
}

class AbstractMethodSubclass extends AbstractMethod {
  bool abstractMethod(int _, int _) => true;
  bool abstractMethod2(_, _) => true;
  bool abstractMethod_functionType(void _(), void _()) => true;
}

class Setter {
  int _x;
  Setter(this._x);

  int get x => _x;
  set x(int _) => _x = 2;
}

class StaticMethod {
  static int staticMethod(int _, int _) => 2;
  static int staticMethod2(_, _) => 2;
  static int staticMethod_functionType(void _(), void _()) => 2;
  static int staticMethod_functionTypeNested(
          void _(_, _), void _(int _, int _)) =>
      2;
  static int staticMethod_functionTypeNew(
          void Function(int _, int _) _, void Function(int _, int _) _) =>
      2;
  static int staticMethod_functionTypeGeneric(
          void Function<_, _>(int _, int _) _, void _<_>(_, _)) =>
      2;
}

void main() {
  // Function expression
  var list = [true];
  list.where(
    (_, [_]) => true,
  );

  // Abstract methods
  var abstractMethod = AbstractMethodSubclass();
  abstractMethod.abstractMethod(1, 2);
  abstractMethod.abstractMethod2(1, 2);
  abstractMethod.abstractMethod_functionType(() {}, () {});

  // Static methods
  StaticMethod.staticMethod(1, 2);
  StaticMethod.staticMethod2(1, 2);
  StaticMethod.staticMethod_functionType(() {}, () {});
  StaticMethod.staticMethod_functionTypeNested((e, x) {}, (e, x) {});
  StaticMethod.staticMethod_functionTypeNew((e, x) {}, (e, x) {});
  StaticMethod.staticMethod_functionTypeNested((_, _) {}, (_, _) {});
  StaticMethod.staticMethod_functionTypeNew((_, _) {}, (_, _) {});

  // Top level functions
  topLevelFunction(1, 2);
  topLevelFunction2(1, 2);
  topLevelFunction_functionType(() {}, () {});

  // Instance methods
  var instanceMethod = InstanceMethod();
  instanceMethod.instanceMethod(1, 2);
  instanceMethod.instanceMethod2(1, 2);
  instanceMethod.instanceMethod_functionType(() {}, () {});
  Expect.equals(42, instanceMethod + 2);
  instanceMethod[1] = 2;
  Expect.isTrue(instanceMethod == 2);
  Expect.isTrue((instanceMethod as dynamic).noMethod());

  // Constructor
  Constructor.multiple(1, 2, () {});
  Constructor.parameter(1, 2, 3);
  Constructor.functionType(() {}, () {}, () {});

  // Setter
  var setter = Setter(1);
  setter.x = 2;
}
