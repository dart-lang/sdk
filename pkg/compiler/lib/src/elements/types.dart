// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'entities.dart';
import '../util/util.dart' show equalElements;

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
  const DartType();

  /// Returns the unaliased type of this type.
  ///
  /// The unaliased type of a typedef'd type is the unaliased type to which its
  /// name is bound. The unaliased version of any other type is the type itself.
  ///
  /// For example, the unaliased type of `typedef A Func<A,B>(B b)` is the
  /// function type `(B) -> A` and the unaliased type of `Func<int,String>`
  /// is the function type `(String) -> int`.
  DartType get unaliased => this;

  /// Is `true` if this type has no non-dynamic type arguments.
  bool get treatAsRaw => true;

  /// Is `true` if this type should be treated as the dynamic type.
  bool get treatAsDynamic => false;

  /// Is `true` if this type is the dynamic type.
  bool get isDynamic => false;

  /// Is `true` if this type is the void type.
  bool get isVoid => false;

  /// Is `true` if this type is an interface type.
  bool get isInterfaceType => false;

  /// Is `true` if this type is a typedef.
  bool get isTypedef => false;

  /// Is `true` if this type is a function type.
  bool get isFunctionType => false;

  /// Is `true` if this type is a type variable.
  bool get isTypeVariable => false;

  /// Is `true` if this type is a malformed type.
  bool get isMalformed => false;
}

class InterfaceType extends DartType {
  final ClassEntity element;
  final List<DartType> typeArguments;

  InterfaceType(this.element, this.typeArguments);

  int get hashCode {
    int hash = element.hashCode;
    for (DartType argument in typeArguments) {
      int argumentHash = argument != null ? argument.hashCode : 0;
      hash = 17 * hash + 3 * argumentHash;
    }
    return hash;
  }

  bool operator ==(other) {
    if (other is! InterfaceType) return false;
    return identical(element, other.element) &&
        equalElements(typeArguments, other.typeArguments);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(element.name);
    if (typeArguments.isNotEmpty) {
      sb.write('<');
      bool needsComma = false;
      for (DartType typeArgument in typeArguments) {
        if (needsComma) {
          sb.write(',');
        }
        sb.write(typeArgument);
        needsComma = true;
      }
      sb.write('>');
    }
    return sb.toString();
  }
}

class TypeVariableType extends DartType {
  final TypeVariableEntity element;

  TypeVariableType(this.element);

  bool get isTypeVariable => true;

  int get hashCode => 17 * element.hashCode;

  bool operator ==(other) {
    if (other is! TypeVariableType) return false;
    return identical(other.element, element);
  }

  String toString() => '${element.typeDeclaration.name}.${element.name}';
}

class VoidType extends DartType {
  const VoidType();

  bool get isVoid => true;

  int get hashCode => 6007;

  String toString() => 'void';
}

class DynamicType extends DartType {
  const DynamicType();

  @override
  bool get isDynamic => true;

  @override
  bool get treatAsDynamic => true;

  int get hashCode => 91;

  String toString() => 'dynamic';
}

class FunctionType extends DartType {
  final DartType returnType;
  final List<DartType> parameterTypes;
  final List<DartType> optionalParameterTypes;

  /// The names of the named parameters ordered lexicographically.
  final List<String> namedParameters;

  /// The types of the named parameters in the order corresponding to the
  /// [namedParameters].
  final List<DartType> namedParameterTypes;

  FunctionType(
      this.returnType,
      this.parameterTypes,
      this.optionalParameterTypes,
      this.namedParameters,
      this.namedParameterTypes);

  bool get isFunctionType => true;

  int get hashCode {
    int hash = 3 * returnType.hashCode;
    for (DartType parameter in parameterTypes) {
      hash = 17 * hash + 5 * parameter.hashCode;
    }
    for (DartType parameter in optionalParameterTypes) {
      hash = 19 * hash + 7 * parameter.hashCode;
    }
    for (String name in namedParameters) {
      hash = 23 * hash + 11 * name.hashCode;
    }
    for (DartType parameter in namedParameterTypes) {
      hash = 29 * hash + 13 * parameter.hashCode;
    }
    return hash;
  }

  bool operator ==(other) {
    if (other is! FunctionType) return false;
    return returnType == other.returnType &&
        equalElements(parameterTypes, other.parameterTypes) &&
        equalElements(optionalParameterTypes, other.optionalParameterTypes) &&
        equalElements(namedParameters, other.namedParameters) &&
        equalElements(namedParameterTypes, other.namedParameterTypes);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(returnType);
    sb.write(' Function(');
    bool needsComma = false;
    for (DartType parameterType in parameterTypes) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write(parameterType);
      needsComma = true;
    }
    if (optionalParameterTypes.isNotEmpty) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write('[');
      bool needsOptionalComma = false;
      for (DartType typeArgument in optionalParameterTypes) {
        if (needsOptionalComma) {
          sb.write(',');
        }
        sb.write(typeArgument);
        needsOptionalComma = true;
      }
      sb.write(']');
      needsComma = true;
    }
    if (namedParameters.isNotEmpty) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write('{');
      bool needsNamedComma = false;
      for (int index = 0; index < namedParameters.length; index++) {
        if (needsNamedComma) {
          sb.write(',');
        }
        sb.write(namedParameterTypes[index]);
        sb.write(' ');
        sb.write(namedParameters[index]);
        needsNamedComma = true;
      }
      sb.write('}');
    }
    return sb.toString();
  }
}
