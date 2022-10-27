// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `createStaticInteropMock` checks for extension member conflicts.
// We should only require users to implement one of these conflicts (or a
// getter/setter pair).

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class SameKindConflict {}

extension E1 on SameKindConflict {
  external int get getter;
  external set setter(int val);
  external int method();
}

extension E2 on SameKindConflict {
  external String get getter;
  external set setter(int val);
  external String method();
}

@JSExport()
class DartSameKindConflict {
  String getter = '';
  set setter(int val) => throw '';
  String method() => throw '';
}

@JSExport()
class IncorrectDartSameKindConflict {
  bool getter = true;
  set setter(bool val) => throw '';
  bool method() => throw '';
}

void testSameKindConflict() {
  // No error as one of the extension members are implemented for each export
  // name.
  createStaticInteropMock<SameKindConflict, DartSameKindConflict>(
      DartSameKindConflict());
  // Error as none of them are implemented for each export name.
  createStaticInteropMock<SameKindConflict, IncorrectDartSameKindConflict>(
//^
// [web] Dart class 'IncorrectDartSameKindConflict' does not have any members that implement any of the following extension member(s) with export name 'getter': E1.getter (FunctionType(int Function())), E2.getter (FunctionType(String Function())).
// [web] Dart class 'IncorrectDartSameKindConflict' does not have any members that implement any of the following extension member(s) with export name 'method': E1.method (FunctionType(int Function())), E2.method (FunctionType(String Function())).
// [web] Dart class 'IncorrectDartSameKindConflict' does not have any members that implement any of the following extension member(s) with export name 'setter': E1.setter= (FunctionType(void Function(int))), E2.setter= (FunctionType(void Function(int))).
      IncorrectDartSameKindConflict());
}

@JS()
@staticInterop
class DifferentKindConflict {}

extension E3 on DifferentKindConflict {
  external int getSet;
  @JS('getSet')
  external void method();
}

@JSExport()
class ImplementGetter {
  int get getSet => throw '';
}

@JSExport()
class ImplementSetter {
  set getSet(int val) => throw '';
}

@JSExport()
class ImplementBoth {
  int getSet = 0;
}

@JSExport()
class ImplementMethod {
  void getSet() {}
}

void testDifferentKindConflict() {
  // Missing setter error.
  createStaticInteropMock<DifferentKindConflict, ImplementGetter>(
//^
// [web] Dart class 'ImplementGetter' has a getter, but does not have a setter to implement any of the following extension member(s) with export name 'getSet': E3.getSet= (FunctionType(void Function(int))).
      ImplementGetter());
  // Missing getter error.
  createStaticInteropMock<DifferentKindConflict, ImplementSetter>(
//^
// [web] Dart class 'ImplementSetter' has a setter, but does not have a getter to implement any of the following extension member(s) with export name 'getSet': E3.getSet (FunctionType(int Function())).
      ImplementSetter());
  // No error as both getter and setter are there, and we've satisfied an export
  // for `getSet`.
  createStaticInteropMock<DifferentKindConflict, ImplementBoth>(
      ImplementBoth());
  // No error as we've satisfied an export for `getSet`.
  createStaticInteropMock<DifferentKindConflict, ImplementMethod>(
      ImplementMethod());
}
