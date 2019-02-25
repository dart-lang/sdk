// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_environment;

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';
import 'type_algebra.dart';

import 'src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;

typedef void ErrorHandler(TreeNode node, String message);

abstract class TypeEnvironment extends SubtypeTester {
  final CoreTypes coreTypes;

  InterfaceType thisType;

  DartType returnType;
  DartType yieldType;
  AsyncMarker currentAsyncMarker = AsyncMarker.Sync;

  /// An error handler for use in debugging, or `null` if type errors should not
  /// be tolerated.  See [typeError].
  ErrorHandler errorHandler;

  TypeEnvironment.fromSubclass(this.coreTypes);

  factory TypeEnvironment(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    return new HierarchyBasedTypeEnvironment(coreTypes, hierarchy);
  }

  InterfaceType get objectType => coreTypes.objectClass.rawType;
  InterfaceType get nullType => coreTypes.nullClass.rawType;
  InterfaceType get boolType => coreTypes.boolClass.rawType;
  InterfaceType get intType => coreTypes.intClass.rawType;
  InterfaceType get numType => coreTypes.numClass.rawType;
  InterfaceType get doubleType => coreTypes.doubleClass.rawType;
  InterfaceType get stringType => coreTypes.stringClass.rawType;
  InterfaceType get symbolType => coreTypes.symbolClass.rawType;
  InterfaceType get typeType => coreTypes.typeClass.rawType;
  InterfaceType get rawFunctionType => coreTypes.functionClass.rawType;

  Class get intClass => coreTypes.intClass;
  Class get numClass => coreTypes.numClass;
  Class get futureOrClass => coreTypes.futureOrClass;

  InterfaceType literalListType(DartType elementType) {
    return new InterfaceType(coreTypes.listClass, <DartType>[elementType]);
  }

  InterfaceType literalSetType(DartType elementType) {
    return new InterfaceType(coreTypes.setClass, <DartType>[elementType]);
  }

  InterfaceType literalMapType(DartType key, DartType value) {
    return new InterfaceType(coreTypes.mapClass, <DartType>[key, value]);
  }

  InterfaceType iterableType(DartType type) {
    return new InterfaceType(coreTypes.iterableClass, <DartType>[type]);
  }

  InterfaceType streamType(DartType type) {
    return new InterfaceType(coreTypes.streamClass, <DartType>[type]);
  }

  InterfaceType futureType(DartType type) {
    return new InterfaceType(coreTypes.futureClass, <DartType>[type]);
  }

  /// Removes a level of `Future<>` types wrapping a type.
  ///
  /// This implements the function `flatten` from the spec, which unwraps a
  /// layer of Future or FutureOr from a type.
  DartType unfutureType(DartType type) {
    if (type is InterfaceType) {
      if (type.classNode == coreTypes.futureOrClass ||
          type.classNode == coreTypes.futureClass) {
        return type.typeArguments[0];
      }
      // It is a compile-time error to implement, extend, or mixin FutureOr so
      // we aren't concerned with it.  If a class implements multiple
      // instantiations of Future, getTypeAsInstanceOf is responsible for
      // picking the least one in the sense required by the spec.
      InterfaceType future = getTypeAsInstanceOf(type, coreTypes.futureClass);
      if (future != null) {
        return future.typeArguments[0];
      }
    }
    return type;
  }

  /// Called if the computation of a static type failed due to a type error.
  ///
  /// This should never happen in production.  The frontend should report type
  /// errors, and either recover from the error during translation or abort
  /// compilation if unable to recover.
  ///
  /// By default, this throws an exception, since programs in kernel are assumed
  /// to be correctly typed.
  ///
  /// An [errorHandler] may be provided in order to override the default
  /// behavior and tolerate the presence of type errors.  This can be useful for
  /// debugging IR producers which are required to produce a strongly typed IR.
  void typeError(TreeNode node, String message) {
    if (errorHandler != null) {
      errorHandler(node, message);
    } else {
      throw '$message in $node';
    }
  }

  /// True if [member] is a binary operator that returns an `int` if both
  /// operands are `int`, and otherwise returns `double`.
  ///
  /// This is a case of type-based overloading, which in Dart is only supported
  /// by giving special treatment to certain arithmetic operators.
  bool isOverloadedArithmeticOperator(Procedure member) {
    Class class_ = member.enclosingClass;
    if (class_ == coreTypes.intClass || class_ == coreTypes.numClass) {
      String name = member.name.name;
      return name == '+' ||
          name == '-' ||
          name == '*' ||
          name == 'remainder' ||
          name == '%';
    }
    return false;
  }

  /// Returns the static return type of an overloaded arithmetic operator
  /// (see [isOverloadedArithmeticOperator]) given the static type of the
  /// operands.
  ///
  /// If both types are `int`, the returned type is `int`.
  /// If either type is `double`, the returned type is `double`.
  /// If both types refer to the same type variable (typically with `num` as
  /// the upper bound), then that type variable is returned.
  /// Otherwise `num` is returned.
  DartType getTypeOfOverloadedArithmetic(DartType type1, DartType type2) {
    if (type1 == type2) return type1;
    if (type1 == doubleType || type2 == doubleType) return doubleType;
    return numType;
  }
}

/// The part of [TypeEnvironment] that deals with subtype tests.
///
/// This lives in a separate class so it can be tested independently of the SDK.
abstract class SubtypeTester {
  InterfaceType get objectType;
  InterfaceType get nullType;
  InterfaceType get rawFunctionType;
  Class get futureOrClass;
  InterfaceType futureType(DartType type);

  static List<Object> typeChecks;

  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass);

  /// Determines if the given type is at the top of the type hierarchy.  May be
  /// overridden in subclasses.
  bool isTop(DartType type) =>
      type is DynamicType || type is VoidType || type == objectType;

  /// Can be use to collect type checks. To use:
  /// 1. Rename `isSubtypeOf` to `_isSubtypeOf`.
  /// 2. Rename `_collect_isSubtypeOf` to `isSubtypeOf`.
  /// 3. Comment out the call to `_isSubtypeOf` below.
  // ignore:unused_element
  bool _collect_isSubtypeOf(DartType subtype, DartType supertype) {
    bool result = true;
    // result = _isSubtypeOf(subtype, supertype);
    typeChecks ??= <Object>[];
    typeChecks.add([subtype, supertype, result]);
    return result;
  }

  /// Returns true if [subtype] is a subtype of [supertype].
  bool isSubtypeOf(DartType subtype, DartType supertype) {
    subtype = subtype.unalias;
    supertype = supertype.unalias;
    if (identical(subtype, supertype)) return true;
    if (subtype is BottomType) return true;
    if (subtype == nullType) {
      // See rule 4 of the subtype rules from the Dart Language Specification.
      return supertype is! BottomType;
    }
    if (isTop(supertype)) return true;

    // Handle FutureOr<T> union type.
    if (subtype is InterfaceType &&
        identical(subtype.classNode, futureOrClass)) {
      var subtypeArg = subtype.typeArguments[0];
      if (supertype is InterfaceType &&
          identical(supertype.classNode, futureOrClass)) {
        var supertypeArg = supertype.typeArguments[0];
        // FutureOr<A> <: FutureOr<B> iff A <: B
        return isSubtypeOf(subtypeArg, supertypeArg);
      }

      // given t1 is Future<A> | A, then:
      // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
      var subtypeFuture = futureType(subtypeArg);
      return isSubtypeOf(subtypeFuture, supertype) &&
          isSubtypeOf(subtypeArg, supertype);
    }

    if (supertype is InterfaceType &&
        identical(supertype.classNode, futureOrClass)) {
      // given t2 is Future<A> | A, then:
      // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
      var supertypeArg = supertype.typeArguments[0];
      var supertypeFuture = futureType(supertypeArg);
      return isSubtypeOf(subtype, supertypeFuture) ||
          isSubtypeOf(subtype, supertypeArg);
    }

    if (subtype is InterfaceType && supertype is InterfaceType) {
      var upcastType = getTypeAsInstanceOf(subtype, supertype.classNode);
      if (upcastType == null) return false;
      for (int i = 0; i < upcastType.typeArguments.length; ++i) {
        // Termination: the 'supertype' parameter decreases in size.
        if (!isSubtypeOf(
            upcastType.typeArguments[i], supertype.typeArguments[i])) {
          return false;
        }
      }
      return true;
    }
    if (subtype is TypeParameterType) {
      if (supertype is TypeParameterType &&
          subtype.parameter == supertype.parameter) {
        if (supertype.promotedBound != null) {
          return isSubtypeOf(subtype.bound, supertype.bound);
        } else {
          // Promoted bound should always be a subtype of the declared bound.
          assert(subtype.promotedBound == null ||
              isSubtypeOf(subtype.bound, supertype.bound));
          return true;
        }
      }
      // Termination: if there are no cyclically bound type parameters, this
      // recursive call can only occur a finite number of times, before reaching
      // a shrinking recursive call (or terminating).
      return isSubtypeOf(subtype.bound, supertype);
    }
    if (subtype is FunctionType) {
      if (supertype == rawFunctionType) return true;
      if (supertype is FunctionType) {
        return _isFunctionSubtypeOf(subtype, supertype);
      }
    }
    return false;
  }

  bool _isFunctionSubtypeOf(FunctionType subtype, FunctionType supertype) {
    if (subtype.requiredParameterCount > supertype.requiredParameterCount) {
      return false;
    }
    if (subtype.positionalParameters.length <
        supertype.positionalParameters.length) {
      return false;
    }
    if (subtype.typeParameters.length != supertype.typeParameters.length) {
      return false;
    }
    if (subtype.typeParameters.isNotEmpty) {
      var substitution = <TypeParameter, DartType>{};
      for (int i = 0; i < subtype.typeParameters.length; ++i) {
        var subParameter = subtype.typeParameters[i];
        var superParameter = supertype.typeParameters[i];
        substitution[subParameter] = new TypeParameterType(superParameter);
      }
      for (int i = 0; i < subtype.typeParameters.length; ++i) {
        var subParameter = subtype.typeParameters[i];
        var superParameter = supertype.typeParameters[i];
        var subBound = substitute(subParameter.bound, substitution);
        // Termination: if there are no cyclically bound type parameters, this
        // recursive call can only occur a finite number of times before
        // reaching a shrinking recursive call (or terminating).
        // TODO(dmitryas): Replace it with one recursive descent instead of two.
        if (!isSubtypeOf(superParameter.bound, subBound) ||
            !isSubtypeOf(subBound, superParameter.bound)) {
          return false;
        }
      }
      subtype = substitute(subtype.withoutTypeParameters, substitution);
    }
    if (!isSubtypeOf(subtype.returnType, supertype.returnType)) {
      return false;
    }
    for (int i = 0; i < supertype.positionalParameters.length; ++i) {
      var supertypeParameter = supertype.positionalParameters[i];
      var subtypeParameter = subtype.positionalParameters[i];
      // Termination: Both types shrink in size.
      if (!isSubtypeOf(supertypeParameter, subtypeParameter)) {
        return false;
      }
    }
    int subtypeNameIndex = 0;
    for (NamedType supertypeParameter in supertype.namedParameters) {
      while (subtypeNameIndex < subtype.namedParameters.length &&
          subtype.namedParameters[subtypeNameIndex].name !=
              supertypeParameter.name) {
        ++subtypeNameIndex;
      }
      if (subtypeNameIndex == subtype.namedParameters.length) return false;
      NamedType subtypeParameter = subtype.namedParameters[subtypeNameIndex];
      // Termination: Both types shrink in size.
      if (!isSubtypeOf(supertypeParameter.type, subtypeParameter.type)) {
        return false;
      }
    }
    return true;
  }
}
