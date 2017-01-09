// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'entities.dart';

/// Hierarchy to describe types in Dart.
///
/// This hierarchy is a super hierarchy of the use-case specific hierarchies
/// used in different parts of the compiler. This hierarchy abstracts details
/// not generally needed or required for the Dart type hierarchy. For instance,
/// the hierarchy in 'resolution_types.dart' has properties supporting lazy
/// computation (like computeAlias) and distinctions between 'Foo' and
/// 'Foo<dynamic>', features that are not needed for code generation and not
/// supported from kernel.
///
/// Current only 'resolution_types.dart' implement this hierarchy but when the
/// compiler moves to use [Entity] instead of [Element] this hierarchy can be
/// implementated directly but other entity systems, for instance based directly
/// on kernel ir without the need for [Element].

abstract class DartType {
  /// Returns the unaliased type of this type.
  ///
  /// The unaliased type of a typedef'd type is the unaliased type to which its
  /// name is bound. The unaliased version of any other type is the type itself.
  ///
  /// For example, the unaliased type of `typedef A Func<A,B>(B b)` is the
  /// function type `(B) -> A` and the unaliased type of `Func<int,String>`
  /// is the function type `(String) -> int`.
  DartType get unaliased;

  /// Is `true` if this type has no non-dynamic type arguments.
  bool get treatAsRaw;

  /// Is `true` if this type should be treated as the dynamic type.
  bool get treatAsDynamic;

  /// Is `true` if this type is the dynamic type.
  bool get isDynamic;

  /// Is `true` if this type is the void type.
  bool get isVoid;

  /// Is `true` if this is the type of `Object` from dart:core.
  bool get isObject;

  /// Is `true` if this type is an interface type.
  bool get isInterfaceType;

  /// Is `true` if this type is a typedef.
  bool get isTypedef;

  /// Is `true` if this type is a function type.
  bool get isFunctionType;

  /// Is `true` if this type is a type variable.
  bool get isTypeVariable;

  /// Is `true` if this type is a malformed type.
  bool get isMalformed;
}

abstract class InterfaceType extends DartType {
  ClassEntity get element;
  List<DartType> get typeArguments;
}

abstract class TypeVariableType extends DartType {
  TypeVariableEntity get element;
}

abstract class VoidType extends DartType {}

abstract class DynamicType extends DartType {}

abstract class FunctionType extends DartType {
  DartType get returnType;
  List<DartType> get parameterTypes;
  List<DartType> get optionalParameterTypes;

  /// The names of the named parameters ordered lexicographically.
  List<String> get namedParameters;

  /// The types of the named parameters in the order corresponding to the
  /// [namedParameters].
  List<DartType> get namedParameterTypes;
}
