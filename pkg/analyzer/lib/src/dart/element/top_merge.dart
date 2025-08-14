// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class TopMergeHelper {
  final TypeSystemImpl typeSystem;

  TopMergeHelper(this.typeSystem);

  /// Merges two types into a single type.
  /// Compute the canonical representation of [T].
  ///
  /// https://github.com/dart-lang/language/
  /// See `accepted/future-releases/nnbd/feature-specification.md`
  /// See `#classes-defined-in-opted-in-libraries`
  TypeImpl topMerge(TypeImpl T, TypeImpl S) {
    var T_nullability = T.nullabilitySuffix;
    var S_nullability = S.nullabilitySuffix;

    // NNBD_TOP_MERGE(Object?, Object?) = Object?
    var T_isObjectQuestion =
        T_nullability == NullabilitySuffix.question && T.isDartCoreObject;
    var S_isObjectQuestion =
        S_nullability == NullabilitySuffix.question && S.isDartCoreObject;
    if (T_isObjectQuestion && S_isObjectQuestion) {
      return T;
    }

    // NNBD_TOP_MERGE(dynamic, dynamic) = dynamic
    var T_isDynamic = identical(T, DynamicTypeImpl.instance);
    var S_isDynamic = identical(S, DynamicTypeImpl.instance);
    if (T_isDynamic && S_isDynamic) {
      return DynamicTypeImpl.instance;
    }

    if (identical(T, InvalidTypeImpl.instance) ||
        identical(S, InvalidTypeImpl.instance)) {
      return InvalidTypeImpl.instance;
    }

    if (identical(T, NeverTypeImpl.instance) &&
        identical(S, NeverTypeImpl.instance)) {
      return NeverTypeImpl.instance;
    }

    // NNBD_TOP_MERGE(void, void) = void
    var T_isVoid = identical(T, VoidTypeImpl.instance);
    var S_isVoid = identical(S, VoidTypeImpl.instance);
    if (T_isVoid && S_isVoid) {
      return VoidTypeImpl.instance;
    }

    // NNBD_TOP_MERGE(Object?, void) = void
    // NNBD_TOP_MERGE(void, Object?) = void
    if (T_isObjectQuestion && S_isVoid || T_isVoid && S_isObjectQuestion) {
      return typeSystem.objectQuestion;
    }

    // NNBD_TOP_MERGE(dynamic, void) = void
    // NNBD_TOP_MERGE(void, dynamic) = void
    if (T_isDynamic && S_isVoid || T_isVoid && S_isDynamic) {
      return typeSystem.objectQuestion;
    }

    // NNBD_TOP_MERGE(Object?, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, Object?) = Object?
    if (T_isObjectQuestion && S_isDynamic) {
      return T;
    }
    if (T_isDynamic && S_isObjectQuestion) {
      return S;
    }

    // Merge nullabilities.
    var T_isQuestion = T_nullability == NullabilitySuffix.question;
    var S_isQuestion = S_nullability == NullabilitySuffix.question;
    if (T_isQuestion && S_isQuestion) {
      var T_none = T.withNullability(NullabilitySuffix.none);
      var S_none = S.withNullability(NullabilitySuffix.none);
      var R_none = topMerge(T_none, S_none);
      return R_none.withNullability(NullabilitySuffix.question);
    } else if (T_isQuestion || S_isQuestion) {
      throw StateError('$T_nullability vs $S_nullability');
    }

    assert(T_nullability == NullabilitySuffix.none);
    assert(S_nullability == NullabilitySuffix.none);

    // And for all other types, recursively apply the transformation over
    // the structure of the type.
    //
    // For example: NNBD_TOP_MERGE(C<T>, C<S>) = C<NNBD_TOP_MERGE(T, S)>
    //
    // The NNBD_TOP_MERGE of two types is not defined for types which are not
    // otherwise structurally equal.

    if (T is InterfaceTypeImpl && S is InterfaceTypeImpl) {
      return _interfaceTypes(T, S);
    }

    if (T is FunctionTypeImpl && S is FunctionTypeImpl) {
      return _functionTypes(T, S);
    }

    if (T is RecordTypeImpl && S is RecordTypeImpl) {
      return _recordTypes(T, S);
    }

    if (T is TypeParameterType && S is TypeParameterType) {
      if (T.element == S.element) {
        return T;
      } else {
        throw _TopMergeStateError(T, S, 'Not the same type parameters');
      }
    }

    throw _TopMergeStateError(T, S, 'Unexpected pair');
  }

  FunctionTypeImpl _functionTypes(FunctionTypeImpl T, FunctionTypeImpl S) {
    var T_typeParameters = T.typeParameters;
    var S_typeParameters = S.typeParameters;
    if (T_typeParameters.length != S_typeParameters.length) {
      throw _TopMergeStateError(T, S, 'Different number of type parameters');
    }

    List<TypeParameterElementImpl> R_typeParameters;
    Substitution? T_Substitution;
    Substitution? S_Substitution;

    TypeImpl mergeTypes(TypeImpl T, TypeImpl S) {
      if (T_Substitution != null && S_Substitution != null) {
        T = T_Substitution.substituteType(T);
        S = S_Substitution.substituteType(S);
      }
      return topMerge(T, S);
    }

    if (T_typeParameters.isNotEmpty) {
      var mergedTypeParameters = _typeParameters(
        T_typeParameters,
        S_typeParameters,
      );
      if (mergedTypeParameters == null) {
        throw _TopMergeStateError(T, S, 'Unable to merge type parameters');
      }
      R_typeParameters = mergedTypeParameters.typeParameters;
      T_Substitution = mergedTypeParameters.aSubstitution;
      S_Substitution = mergedTypeParameters.bSubstitution;
    } else {
      R_typeParameters = const <TypeParameterElementImpl>[];
    }

    var R_returnType = mergeTypes(T.returnType, S.returnType);

    var T_parameters = T.formalParameters;
    var S_parameters = S.formalParameters;
    if (T_parameters.length != S_parameters.length) {
      throw _TopMergeStateError(T, S, 'Different number of formal parameters');
    }

    var R_parameters = <FormalParameterElementImpl>[];
    for (var i = 0; i < T_parameters.length; i++) {
      var T_parameter = T_parameters[i];
      var S_parameter = S_parameters[i];

      var R_kind = _parameterKind(T_parameter, S_parameter);
      if (R_kind == null) {
        throw _TopMergeStateError(T, S, 'Different formal parameter kinds');
      }

      if (T_parameter.isNamed && T_parameter.name != S_parameter.name) {
        throw _TopMergeStateError(T, S, 'Different named parameter names');
      }

      TypeImpl R_type;

      // Given two corresponding parameters of type `T1` and `T2`, where at least
      // one of the parameters is covariant:
      var T_isCovariant = T_parameter.isCovariant;
      var S_isCovariant = S_parameter.isCovariant;
      var R_isCovariant = T_isCovariant || S_isCovariant;
      if (R_isCovariant) {
        var T1 = T_parameter.type;
        var T2 = S_parameter.type;
        var T1_isSubtype = typeSystem.isSubtypeOf(T1, T2);
        var T2_isSubtype = typeSystem.isSubtypeOf(T2, T1);
        if (T1_isSubtype && T2_isSubtype) {
          // if `T1 <: T2` and `T2 <: T1`, then the result is
          // `NNBD_TOP_MERGE(T1, T2)`, and it is covariant.
          R_type = mergeTypes(T_parameter.type, S_parameter.type);
        } else if (T1_isSubtype) {
          // otherwise, if `T1 <: T2`, then the result is
          // `T2` and it is covariant.
          R_type = T2;
        } else {
          // otherwise, the result is `T1` and it is covariant.
          R_type = T1;
        }
      } else {
        R_type = mergeTypes(T_parameter.type, S_parameter.type);
      }

      R_parameters.add(T_parameter.copyWith(type: R_type, kind: R_kind));
    }

    return FunctionTypeImpl.v2(
      typeParameters: R_typeParameters.toFixedList(),
      formalParameters: R_parameters.toFixedList(),
      returnType: R_returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl _interfaceTypes(InterfaceTypeImpl T, InterfaceTypeImpl S) {
    if (T.element != S.element) {
      throw _TopMergeStateError(T, S, 'Different class elements');
    }

    var T_arguments = T.typeArguments;
    var S_arguments = S.typeArguments;
    if (T_arguments.isEmpty) {
      return T;
    } else {
      var arguments = List.generate(
        T_arguments.length,
        (i) => topMerge(T_arguments[i], S_arguments[i]),
        growable: false,
      );
      return T.element.instantiateImpl(
        typeArguments: arguments,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }
  }

  ParameterKind? _parameterKind(
    FormalParameterElement T,
    FormalParameterElement S,
  ) {
    if (T.isRequiredPositional && S.isRequiredPositional) {
      return ParameterKind.REQUIRED;
    }

    if (T.isOptionalPositional && S.isOptionalPositional) {
      return ParameterKind.REQUIRED;
    }

    if (T.isRequiredNamed && S.isRequiredNamed) {
      return ParameterKind.NAMED_REQUIRED;
    }

    if (T.isOptionalNamed && S.isOptionalNamed) {
      return ParameterKind.NAMED;
    }

    // Legacy named vs. Required named.
    if (T.isRequiredNamed && S.isNamed || T.isNamed || S.isRequiredNamed) {
      return ParameterKind.NAMED_REQUIRED;
    }

    return null;
  }

  RecordTypeImpl _recordTypes(RecordTypeImpl T1, RecordTypeImpl T2) {
    var positional1 = T1.positionalFields;
    var positional2 = T2.positionalFields;
    if (positional1.length != positional1.length) {
      throw _TopMergeStateError(T1, T2, 'Different number of position fields');
    }

    var positionalFields = <RecordTypePositionalFieldImpl>[];
    for (var i = 0; i < positional1.length; i++) {
      var field1 = positional1[i];
      var field2 = positional2[i];
      var type = topMerge(field1.type, field2.type);
      positionalFields.add(RecordTypePositionalFieldImpl(type: type));
    }

    var named1 = T1.namedFields;
    var named2 = T2.namedFields;
    if (named1.length != named2.length) {
      throw _TopMergeStateError(T1, T2, 'Different number of named fields');
    }

    var namedFields = <RecordTypeNamedFieldImpl>[];
    for (var i = 0; i < named1.length; i++) {
      var field1 = named1[i];
      var field2 = named2[i];
      if (field1.name != field2.name) {
        throw _TopMergeStateError(T1, T2, 'Different named field names');
      }
      var type = topMerge(field1.type, field2.type);
      namedFields.add(RecordTypeNamedFieldImpl(name: field1.name, type: type));
    }

    return RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  _MergeTypeParametersResult? _typeParameters(
    List<TypeParameterElementImpl> aParameters,
    List<TypeParameterElementImpl> bParameters,
  ) {
    if (aParameters.length != bParameters.length) {
      return null;
    }

    var newParameters = <TypeParameterElementImpl>[];
    var newTypes = <TypeParameterType>[];
    for (var i = 0; i < aParameters.length; i++) {
      var newParameter = aParameters[i].freshCopy();
      newParameters.add(newParameter);

      var newType = newParameter.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
      newTypes.add(newType);
    }

    var aSubstitution = Substitution.fromPairs2(aParameters, newTypes);
    var bSubstitution = Substitution.fromPairs2(bParameters, newTypes);
    for (var i = 0; i < aParameters.length; i++) {
      var a = aParameters[i];
      var b = bParameters[i];

      var aBound = a.bound;
      var bBound = b.bound;
      if (aBound == null && bBound == null) {
        // OK, no bound.
      } else if (aBound != null && bBound != null) {
        aBound = aSubstitution.substituteType(aBound);
        bBound = bSubstitution.substituteType(bBound);
        var newBound = topMerge(aBound, bBound);
        newParameters[i].bound = newBound;
      } else {
        return null;
      }
    }

    return _MergeTypeParametersResult(
      newParameters,
      aSubstitution,
      bSubstitution,
    );
  }
}

class _MergeTypeParametersResult {
  final List<TypeParameterElementImpl> typeParameters;
  final Substitution aSubstitution;
  final Substitution bSubstitution;

  _MergeTypeParametersResult(
    this.typeParameters,
    this.aSubstitution,
    this.bSubstitution,
  );
}

/// This error should never happen, because we should never attempt
/// `NNBD_TOP_MERGE` for types that are not subtypes of each other, and
/// already NORM(ed).
class _TopMergeStateError {
  final DartType T;
  final DartType S;
  final String message;

  _TopMergeStateError(this.T, this.S, this.message);
}
