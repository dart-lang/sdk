// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `createStaticInteropMock` checks that overrides are subtypes.

import 'package:js/js.dart';
import 'package:js/js_util.dart';

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
  external B get getSetNum;
  external set getSetInt(B val);
  external B method(B b);
}

// Implement using the exact same types.
class SimpleDart {
  B field = throw '';
  final B finalField = throw '';
  B get getSetNum => throw '';
  set getSetInt(B val) => throw '';
  B method(B b) => throw '';
}

// Implement using subtypes.
class SubtypeSimpleDart {
  B field = throw '';
  final C finalField = throw '';
  C get getSetNum => throw '';
  set getSetInt(A val) => throw '';
  C method(A a) => throw '';
}

// Implement using supertypes (which shouldn't work).
class SupertypeSimpleDart {
  A field = throw '';
  final A finalField = throw '';
  A get getSetNum => throw '';
  set getSetInt(C val) => throw '';
  A method(C c) => throw '';
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

class ComplexAndOptionalDart {
  C Function(A _) nestedTypes(List<B> arg1, Map<Set<B>, B> arg2) => throw '';
  B optional(B b, [B? b2]) => throw '';
  C optionalSubtype(A a, [A? a2]) => throw '';
}

class IncorrectComplexAndOptionalDart {
  // List type is wrong.
  B Function(B _) nestedTypes(List<List<B>> arg1, Map<Set<B>, B> arg2) =>
      throw '';
  // Second argument is not optional, this is invalid.
  B optional(B b, B? b2) => throw '';
  // Third argument is supposed to be a supertype, not a subtype.
  B optionalSubtype(B b, [C c = const C()]) => throw '';
}

void main() {
  createStaticInteropMock<SimpleInterop, SimpleDart>(SimpleDart());
  createStaticInteropMock<SimpleInterop, SubtypeSimpleDart>(
      SubtypeSimpleDart());
  createStaticInteropMock<SimpleInterop, SupertypeSimpleDart>(
//^
// [web] Dart class member 'SupertypeSimpleDart.field' with type 'A Function()' is not a subtype of `@staticInterop` external extension member 'SimpleInterop.field' with type 'B Function()'.
// [web] Dart class member 'SupertypeSimpleDart.finalField' with type 'A Function()' is not a subtype of `@staticInterop` external extension member 'SimpleInterop.finalField' with type 'B Function()'.
// [web] Dart class member 'SupertypeSimpleDart.getSetInt=' with type 'void Function(C)' is not a subtype of `@staticInterop` external extension member 'SimpleInterop.getSetInt=' with type 'void Function(B)'.
// [web] Dart class member 'SupertypeSimpleDart.getSetNum' with type 'A Function()' is not a subtype of `@staticInterop` external extension member 'SimpleInterop.getSetNum' with type 'B Function()'.
// [web] Dart class member 'SupertypeSimpleDart.method' with type 'A Function(C)' is not a subtype of `@staticInterop` external extension member 'SimpleInterop.method' with type 'B Function(B)'.
      SupertypeSimpleDart());
  createStaticInteropMock<ComplexAndOptionalInteropMethods,
      ComplexAndOptionalDart>(ComplexAndOptionalDart());
  createStaticInteropMock<
//^
// [web] Dart class member 'IncorrectComplexAndOptionalDart.nestedTypes' with type 'B Function(B) Function(List<List<B>>, Map<Set<B>, B>)' is not a subtype of `@staticInterop` external extension member 'ComplexAndOptionalInteropMethods.nestedTypes' with type 'B Function(B) Function(List<B>, Map<Set<B>, B>)'.
// [web] Dart class member 'IncorrectComplexAndOptionalDart.optional' with type 'B Function(B, B?)' is not a subtype of `@staticInterop` external extension member 'ComplexAndOptionalInteropMethods.optional' with type 'B Function(B, [B?])'.
// [web] Dart class member 'IncorrectComplexAndOptionalDart.optionalSubtype' with type 'B Function(B, [C])' is not a subtype of `@staticInterop` external extension member 'ComplexAndOptionalInteropMethods.optionalSubtype' with type 'B Function(B, [B])'.
      ComplexAndOptionalInteropMethods,
      IncorrectComplexAndOptionalDart>(IncorrectComplexAndOptionalDart());
}
