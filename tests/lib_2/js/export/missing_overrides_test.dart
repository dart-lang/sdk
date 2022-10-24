// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `createStaticInteropMock` checks that there aren't any missing
// overrides.

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class StaticInterop {}

extension on StaticInterop {
  external int field;
  external final int finalField;
  external int get getSet;
  external set getSet(int val);
  external void method();

  // We should ignore the non-external members for determining overrides.
  int get nonExternalGetSet => throw '';
  set nonExternalGetSet(int val) => throw '';
  void nonExternalMethod() => throw '';
}

class CorrectDart {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

class DartStatic {
  static int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

class DartUsingExtensions {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
}

extension on DartUsingExtensions {
  void method() => throw '';
}

class DartFactory {
  DartFactory();
  factory DartFactory.finalField() => DartFactory();
  int field = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

class DartFinal {
  final int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

class DartNoGet {
  int field = throw '';
  final int finalField = throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

class DartNoSet {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  void method() => throw '';
}

class DartNoMembers {}

void main() {
  createStaticInteropMock<StaticInterop, CorrectDart>(CorrectDart());
  // Static members do not qualify as an override.
  createStaticInteropMock<StaticInterop, DartStatic>(
//^
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'field', but Dart class 'DartStatic' does not have an overriding instance member.
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'field=', but Dart class 'DartStatic' does not have an overriding instance member.
      DartStatic());
  // Extension members do not qualify as an override.
  createStaticInteropMock<StaticInterop, DartUsingExtensions>(
//^
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'method', but Dart class 'DartUsingExtensions' does not have an overriding instance member.
      DartUsingExtensions());
  // Factory members with the same name do not qualify as an override.
  createStaticInteropMock<StaticInterop, DartFactory>(
//^
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'finalField', but Dart class 'DartFactory' does not have an overriding instance member.
      DartFactory());
  // Final fields can not override a setter.
  createStaticInteropMock<StaticInterop, DartFinal>(DartFinal());
//^
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'field=', but Dart class 'DartFinal' does not have an overriding instance member.
  createStaticInteropMock<StaticInterop, DartNoGet>(DartNoGet());
//^
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'getSet', but Dart class 'DartNoGet' does not have an overriding instance member.

  // Test that getters are treated differently from setters even though they
  // share the same name.
  createStaticInteropMock<StaticInterop, DartNoSet>(DartNoSet());
//^
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'getSet=', but Dart class 'DartNoSet' does not have an overriding instance member.

  // Test multiple missing members.
  createStaticInteropMock<StaticInterop, DartNoMembers>(
//^
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'field', but Dart class 'DartNoMembers' does not have an overriding instance member.
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'field=', but Dart class 'DartNoMembers' does not have an overriding instance member.
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'finalField', but Dart class 'DartNoMembers' does not have an overriding instance member.
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'getSet', but Dart class 'DartNoMembers' does not have an overriding instance member.
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'getSet=', but Dart class 'DartNoMembers' does not have an overriding instance member.
// [web] `@staticInterop` class 'StaticInterop' has external extension member 'method', but Dart class 'DartNoMembers' does not have an overriding instance member.
      DartNoMembers());

  testUsingInheritanceAndMixins();
}

// The following should classes should not contain any override errors, as they
// have all the necessary members.
class DartWithInheritance extends DartNoSet {
  set getSet(int val) => throw '';
}

class DartWithMixins with CorrectDart {}

mixin MixinSet {
  set getSet(int val) => throw '';
}

class DartWithMixinsAndInheritance extends DartNoSet with MixinSet {}

@JS()
@staticInterop
class BaseStaticInterop {}

extension on BaseStaticInterop {
  external void baseMethod();
}

@JS()
@staticInterop
class StaticInteropWithInheritance extends BaseStaticInterop
    implements StaticInterop {}

class DartImplementingInteropInheritance extends DartWithMixinsAndInheritance {
  void baseMethod() => throw '';
}

void testUsingInheritanceAndMixins() {
  // Test where Dart class implements using inherited members.
  createStaticInteropMock<StaticInterop, DartWithInheritance>(
      DartWithInheritance());
  // Test where Dart class implements using mixed-in members.
  createStaticInteropMock<StaticInterop, DartWithMixins>(DartWithMixins());
  // Test where Dart class implements using inherited and mixed-in members.
  createStaticInteropMock<StaticInterop, DartWithMixinsAndInheritance>(
      DartWithMixinsAndInheritance());
  // Missing inherited method, expect an error.
  createStaticInteropMock<
//^
// [web] `@staticInterop` class 'StaticInteropWithInheritance' has external extension member 'baseMethod', but Dart class 'DartWithMixinsAndInheritance' does not have an overriding instance member.
      StaticInteropWithInheritance,
      DartWithMixinsAndInheritance>(DartWithMixinsAndInheritance());
  // Added missing method, should pass.
  createStaticInteropMock<StaticInteropWithInheritance,
      DartImplementingInteropInheritance>(DartImplementingInteropInheritance());
}
