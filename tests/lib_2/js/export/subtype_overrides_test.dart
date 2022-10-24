// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `createStaticInteropMock` checks that overrides exist and are
// subtypes.

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class StaticInterop {}

extension on StaticInterop {
  external int field;
  external final int finalField;
  external int get getSet1;
  external set getSet1(int val);
  external int get getSet2;
  external set getSet2(int val);
  external void method();
}

@JSExport()
class CorrectDart {
  int field = throw '';
  final int finalField = throw '';
  int get getSet1 => throw '';
  set getSet1(int val) => throw '';
  int get getSet2 => throw '';
  set getSet2(int val) => throw '';
  void method() => throw '';
}

@JSExport()
class IncorrectDart {
  IncorrectDart();
  // Factories do not count.
  factory IncorrectDart.method() => IncorrectDart();
  // Setter is not implemented.
  final int field = throw '';
  // Static members do not count.
  static final int finalField = throw '';
  // Getter is not implemented.
  set getSet1(int val) => throw '';
  int get getSet2 => throw '';
}

extension on IncorrectDart {
  // Extension members do not count.
  set getSet2(int val) => throw '';
}

void testMissingOverrides() {
  createStaticInteropMock<StaticInterop, CorrectDart>(CorrectDart());
  createStaticInteropMock<StaticInterop, IncorrectDart>(IncorrectDart());
//^
// [web] Dart class 'IncorrectDart' does not have any members that implement any of the following extension member(s) with export name 'finalField': <unnamed>.finalField (FunctionType(int Function())).
// [web] Dart class 'IncorrectDart' does not have any members that implement any of the following extension member(s) with export name 'method': <unnamed>.method (FunctionType(void Function())).
// [web] Dart class 'IncorrectDart' has a getter, but does not have a setter to implement any of the following extension member(s) with export name 'field': <unnamed>.field= (FunctionType(void Function(int))).
// [web] Dart class 'IncorrectDart' has a getter, but does not have a setter to implement any of the following extension member(s) with export name 'getSet2': <unnamed>.getSet2= (FunctionType(void Function(int))).
// [web] Dart class 'IncorrectDart' has a setter, but does not have a getter to implement any of the following extension member(s) with export name 'getSet1': <unnamed>.getSet1 (FunctionType(int Function())).
}

// Set up a simple type hierarchy.
class A {
  const A();
}

class B extends A {
  const B();
}

class C extends B {
  const C();
}

@JS()
@staticInterop
class SimpleInterop {}

extension SimpleInteropExtension on SimpleInterop {
  external B field;
  external final B finalField;
  external B get getSet;
  external set getSet(B val);
  external B method(B b);
}

// Implement using the exact same types.
@JSExport()
class SimpleDart {
  B field = throw '';
  final B finalField = throw '';
  B get getSet => throw '';
  set getSet(B val) => throw '';
  B method(B b) => throw '';
}

void testExactTypes() {
  createStaticInteropMock<SimpleInterop, SimpleDart>(SimpleDart());
}

// Implement using subtypes.
@JSExport()
class SubtypeSimpleDart {
  B field = throw '';
  final C finalField = throw '';
  C get getSet => throw '';
  set getSet(A val) => throw '';
  C method(A a) => throw '';
}

void testSimpleSubtyping() {
  createStaticInteropMock<SimpleInterop, SubtypeSimpleDart>(
      SubtypeSimpleDart());
}

// Implement using supertypes (which shouldn't work).
@JSExport()
class SupertypeSimpleDart {
  A field = throw '';
  final A finalField = throw '';
  // Getter must be subtype of setter, so only the setter should be an error.
  C get getSet => throw '';
  set getSet(C val) => throw '';
  A method(C c) => throw '';
}

void testIncorrectSimpleSubtyping() {
  createStaticInteropMock<SimpleInterop, SupertypeSimpleDart>(
//^
// [web] Dart class 'SupertypeSimpleDart' does not have any members that implement any of the following extension member(s) with export name 'finalField': SimpleInteropExtension.finalField (FunctionType(B Function())).
// [web] Dart class 'SupertypeSimpleDart' does not have any members that implement any of the following extension member(s) with export name 'method': SimpleInteropExtension.method (FunctionType(B Function(B))).
// [web] Dart class 'SupertypeSimpleDart' has a getter, but does not have a setter to implement any of the following extension member(s) with export name 'getSet': SimpleInteropExtension.getSet= (FunctionType(void Function(B))).
// [web] Dart class 'SupertypeSimpleDart' has a setter, but does not have a getter to implement any of the following extension member(s) with export name 'field': SimpleInteropExtension.field (FunctionType(B Function())).
      SupertypeSimpleDart());
}

@JS()
@staticInterop
class ComplexAndOptionalInteropMethods {}

extension ComplexAndOptionalInteropMethodsExtension
    on ComplexAndOptionalInteropMethods {
  external B Function(B _) nestedTypes(List<B> arg1, Map<Set<B>, B> arg2);
  external B optional(B b, [B? b2]);
  external B optionalSubtype(B b, [B b2 = const B()]);
}

@JSExport()
class ComplexAndOptionalDart {
  C Function(A _) nestedTypes(List<B> arg1, Map<Set<B>, B> arg2) => throw '';
  B optional(B b, [B? b2]) => throw '';
  C optionalSubtype(A a, [A? a2]) => throw '';
}

void testComplexSubtyping() {
  createStaticInteropMock<ComplexAndOptionalInteropMethods,
      ComplexAndOptionalDart>(ComplexAndOptionalDart());
}

@JSExport()
class IncorrectComplexAndOptionalDart {
  // List type is wrong.
  B Function(B _) nestedTypes(List<List<B>> arg1, Map<Set<B>, B> arg2) =>
      throw '';
  // Second argument is not optional, this is invalid.
  B optional(B b, B? b2) => throw '';
  // Third argument is supposed to be a supertype, not a subtype.
  B optionalSubtype(B b, [C c = const C()]) => throw '';
}

void testIncorrectComplexSubtyping() {
  createStaticInteropMock<
//^
// [web] Dart class 'IncorrectComplexAndOptionalDart' does not have any members that implement any of the following extension member(s) with export name 'nestedTypes': ComplexAndOptionalInteropMethodsExtension.nestedTypes (FunctionType(B Function(B) Function(List<B>, Map<Set<B>, B>))).
// [web] Dart class 'IncorrectComplexAndOptionalDart' does not have any members that implement any of the following extension member(s) with export name 'optional': ComplexAndOptionalInteropMethodsExtension.optional (FunctionType(B Function(B, [B?]))).
// [web] Dart class 'IncorrectComplexAndOptionalDart' does not have any members that implement any of the following extension member(s) with export name 'optionalSubtype': ComplexAndOptionalInteropMethodsExtension.optionalSubtype (FunctionType(B Function(B, [B]))).
      ComplexAndOptionalInteropMethods,
      IncorrectComplexAndOptionalDart>(IncorrectComplexAndOptionalDart());
}

void testSubtyping() {
  testExactTypes();
  testSimpleSubtyping();
  testIncorrectSimpleSubtyping();
  testComplexSubtyping();
  testIncorrectComplexSubtyping();
}

void main() {
  testMissingOverrides();
  testSubtyping();
}
