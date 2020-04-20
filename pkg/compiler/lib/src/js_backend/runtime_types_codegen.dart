// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.runtime_types_codegen;

import '../elements/entities.dart';
import '../elements/types.dart';

/// Data needed for generating a signature function for the function type of
/// a class.
class ClassFunctionType {
  /// The `call` function that defines the function type.
  final FunctionEntity callFunction;

  /// The type of the `call` function.
  final FunctionType callType;

  /// The signature function for the function type.
  ///
  /// This is used for Dart 2.
  final FunctionEntity signatureFunction;

  ClassFunctionType(this.callFunction, this.callType, this.signatureFunction);
}

/// A pair of a class that we need a check against and the type argument
/// substitution for this check.
class TypeCheck {
  final ClassEntity cls;
  final bool needsIs;
  final Substitution substitution;
  @override
  final int hashCode = _nextHash = (_nextHash + 100003).toUnsigned(30);
  static int _nextHash = 0;

  TypeCheck(this.cls, this.substitution, {this.needsIs: true});

  @override
  String toString() =>
      'TypeCheck(cls=$cls,needsIs=$needsIs,substitution=$substitution)';
}

/// [TypeCheck]s need for a single class.
class ClassChecks {
  final Map<ClassEntity, TypeCheck> _map;

  final ClassFunctionType functionType;

  ClassChecks(this.functionType) : _map = <ClassEntity, TypeCheck>{};

  const ClassChecks.empty()
      : _map = const <ClassEntity, TypeCheck>{},
        functionType = null;

  void add(TypeCheck check) {
    _map[check.cls] = check;
  }

  TypeCheck operator [](ClassEntity cls) => _map[cls];

  Iterable<TypeCheck> get checks => _map.values;

  @override
  String toString() {
    return 'ClassChecks($checks)';
  }
}

/// For each class, stores the possible class subtype tests that could succeed.
abstract class TypeChecks {
  /// Get the set of checks required for class [element].
  ClassChecks operator [](ClassEntity element);

  /// Get the iterable for all classes that need type checks.
  Iterable<ClassEntity> get classes;
}

/// Representation of the substitution of type arguments when going from the
/// type of a class to one of its supertypes.
///
/// For `class B<T> extends A<List<T>, int>`, the substitution is the
/// representation of `(T) => [<List, T>, int]`. For more details of the
/// representation consult the documentation of [getSupertypeSubstitution].
//TODO(floitsch): Remove support for non-function substitutions.
class Substitution {
  final bool isTrivial;
  final bool isFunction;
  final List<DartType> arguments;
  final List<DartType> parameters;
  final int length;

  const Substitution.trivial()
      : isTrivial = true,
        isFunction = false,
        length = null,
        arguments = const <DartType>[],
        parameters = const <DartType>[];

  Substitution.list(this.arguments)
      : isTrivial = false,
        isFunction = false,
        length = null,
        parameters = const <DartType>[];

  Substitution.function(this.arguments, this.parameters)
      : isTrivial = false,
        isFunction = true,
        length = null;

  Substitution.jsInterop(this.length)
      : isTrivial = false,
        isFunction = false,
        arguments = const <DartType>[],
        parameters = const <DartType>[];

  bool get isJsInterop => length != null;

  @override
  String toString() => 'Substitution(isTrivial=$isTrivial,'
      'isFunction=$isFunction,isJsInterop=$isJsInterop,arguments=$arguments,'
      'parameters=$parameters,length=$length)';
}

/// Interface for computing substitutions need for runtime type checks.
abstract class RuntimeTypesSubstitutions {
  bool isTrivialSubstitution(ClassEntity cls, ClassEntity check);

  Substitution getSubstitution(ClassEntity cls, ClassEntity other);

  Set<ClassEntity> getClassesUsedInSubstitutions(TypeChecks checks);

  static bool hasTypeArguments(DartTypes dartTypes, DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !dartTypes.treatAsRawType(interfaceType);
    }
    return false;
  }
}
