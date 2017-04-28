// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_environment;

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';
import 'type_algebra.dart';

typedef void ErrorHandler(TreeNode node, String message);

class TypeEnvironment extends SubtypeTester {
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  InterfaceType thisType;

  DartType returnType;
  DartType yieldType;
  AsyncMarker currentAsyncMarker = AsyncMarker.Sync;

  /// An error handler for use in debugging, or `null` if type errors should not
  /// be tolerated.  See [typeError].
  ErrorHandler errorHandler;

  TypeEnvironment(this.coreTypes, this.hierarchy);

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

  InterfaceType literalListType(DartType elementType) {
    return new InterfaceType(coreTypes.listClass, <DartType>[elementType]);
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

  /// Removes any number of `Future<>` types wrapping a type.
  DartType unfutureType(DartType type) {
    return type is InterfaceType && type.classNode == coreTypes.futureClass
        ? unfutureType(type.typeArguments[0])
        : type;
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

  /// Returns true if [class_] has no proper subtypes that are usable as type
  /// argument.
  bool isSealedClass(Class class_) {
    // The sealed core classes have subtypes in the patched SDK, but those
    // classes cannot occur as type argument.
    if (class_ == coreTypes.intClass ||
        class_ == coreTypes.doubleClass ||
        class_ == coreTypes.stringClass ||
        class_ == coreTypes.boolClass ||
        class_ == coreTypes.nullClass) {
      return true;
    }
    return !hierarchy.hasProperSubtypes(class_);
  }
}

/// The part of [TypeEnvironment] that deals with subtype tests.
///
/// This lives in a separate class so it can be tested independently of the SDK.
abstract class SubtypeTester {
  InterfaceType get objectType;
  InterfaceType get rawFunctionType;
  ClassHierarchy get hierarchy;

  /// Returns true if [subtype] is a subtype of [supertype].
  bool isSubtypeOf(DartType subtype, DartType supertype) {
    if (identical(subtype, supertype)) return true;
    if (subtype is BottomType) return true;
    if (supertype is DynamicType ||
        supertype is VoidType ||
        supertype == objectType) {
      return true;
    }
    if (subtype is InterfaceType && supertype is InterfaceType) {
      var upcastType =
          hierarchy.getTypeAsInstanceOf(subtype, supertype.classNode);
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
        return true;
      }
      // Termination: if there are no cyclically bound type parameters, this
      // recursive call can only occur a finite number of times, before reaching
      // a shrinking recursive call (or terminating).
      return isSubtypeOf(subtype.parameter.bound, supertype);
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
        if (!isSubtypeOf(superParameter.bound, subBound)) {
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
