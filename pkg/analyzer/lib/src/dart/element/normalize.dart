// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/type_system.dart';

/// Helper for computing canonical presentation of types.
///
/// https://github.com/dart-lang/language
/// See `resources/type-system/normalization.md`
class NormalizeHelper {
  final TypeSystemImpl typeSystem;
  final TypeProviderImpl typeProvider;

  NormalizeHelper(this.typeSystem) : typeProvider = typeSystem.typeProvider;

  DartType normalize(DartType T) {
    var T_impl = T as TypeImpl;
    var T_nullability = T_impl.nullabilitySuffix;

    // NORM(T) = T if T is primitive
    if (identical(T, DynamicTypeImpl.instance) ||
        identical(T, NeverTypeImpl.instance) ||
        identical(T, VoidTypeImpl.instance) ||
        T is InterfaceType &&
            T_nullability == NullabilitySuffix.none &&
            T.typeArguments.isEmpty) {
      return T;
    }

    // NORM(FutureOr<T>)
    if (T is InterfaceType &&
        T.isDartAsyncFutureOr &&
        T_nullability == NullabilitySuffix.none) {
      // * let S be NORM(T)
      var S = normalize(T.typeArguments[0]);
      var S_impl = S as TypeImpl;
      var S_nullability = (S_impl).nullabilitySuffix;
      // * if S is a top type then S
      if (typeSystem.isTop(S)) {
        return S;
      }
      // * if S is Object then S
      // * if S is Object* then S
      if (S.isDartCoreObject) {
        if (S_nullability == NullabilitySuffix.none ||
            S_nullability == NullabilitySuffix.star) {
          return S;
        }
      }
      // * if S is Never then Future<Never>
      if (identical(S, NeverTypeImpl.instance)) {
        return typeProvider.futureElement.instantiate(
          typeArguments: [NeverTypeImpl.instance],
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
      // * if S is Null then Future<Null>?
      if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
        return typeProvider.futureElement.instantiate(
          typeArguments: [typeSystem.nullNone],
          nullabilitySuffix: NullabilitySuffix.question,
        );
      }
      // * else FutureOr<S>
      return typeProvider.futureOrElement.instantiate(
        typeArguments: [S],
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // NORM(T?)
    if (T_nullability == NullabilitySuffix.question) {
      // * let S be NORM(T)
      var T_none = T_impl.withNullability(NullabilitySuffix.none);
      var S = normalize(T_none);
      var S_impl = S as TypeImpl;
      var S_nullability = (S_impl).nullabilitySuffix;
      // * if S is a top type then S
      if (typeSystem.isTop(S)) {
        return S;
      }
      // * if S is Never then Null
      if (identical(S, NeverTypeImpl.instance)) {
        return typeSystem.nullNone;
      }
      // * if S is Never* then Null
      if (identical(S, NeverTypeImpl.instanceLegacy)) {
        return typeSystem.nullNone;
      }
      // * if S is Null then Null
      if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
        return typeSystem.nullNone;
      }
      // * if S is FutureOr<R> and R is nullable then S
      if (S is InterfaceType &&
          S.isDartAsyncFutureOr &&
          S_nullability == NullabilitySuffix.none) {
        var R = S.typeArguments[0];
        if (typeSystem.isNullable(R)) {
          return S;
        }
      }
      // * if S is FutureOr<R>* and R is nullable then FutureOr<R>
      if (S is InterfaceType &&
          S.isDartAsyncFutureOr &&
          S_nullability == NullabilitySuffix.star) {
        var R = S.typeArguments[0];
        if (typeSystem.isNullable(R)) {
          return typeProvider.futureOrElement.instantiate(
            typeArguments: [R],
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
      }
      // * if S is R? then R?
      // * if S is R* then R?
      // * else S?
      return S_impl.withNullability(NullabilitySuffix.question);
    }

    // NORM(T*)
    if (T_nullability == NullabilitySuffix.star) {
      // * let S be NORM(T)
      var T_none = T_impl.withNullability(NullabilitySuffix.none);
      var S = normalize(T_none);
      var S_impl = S as TypeImpl;
      var S_nullability = (S_impl).nullabilitySuffix;
      // * if S is a top type then S
      if (typeSystem.isTop(S)) {
        return S;
      }
      // * if S is Null then Null
      if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
        return typeSystem.nullNone;
      }
      // * if S is R? then R?
      if (S_nullability == NullabilitySuffix.question) {
        return S;
      }
      // * if S is R* then R*
      // * else S*
      return S_impl.withNullability(NullabilitySuffix.star);
    }

    assert(T_nullability == NullabilitySuffix.none);

    // NORM(X extends T)
    // NORM(X & T)
    if (T is TypeParameterType) {
      var element = T.element;
      var bound = element.bound;
      if (bound != null) {
        if (element is TypeParameterMember) {
          // NORM(X & T)
          // * let S be NORM(T)
          var S = normalize(bound);
          // * if S is Never then Never
          if (identical(S, NeverTypeImpl.instance)) {
            return NeverTypeImpl.instance;
          }
          // * if S is a top type then X
          if (typeSystem.isTop(S)) {
            return element.declaration.instantiate(
              nullabilitySuffix: NullabilitySuffix.none,
            );
          }
          // * if S is X then X
          if (S is TypeParameterTypeImpl &&
              S.nullabilitySuffix == NullabilitySuffix.none &&
              S.element == element.declaration) {
            return element.declaration.instantiate(
              nullabilitySuffix: NullabilitySuffix.none,
            );
          }
          // * if S is Object and NORM(B) is Object where B is the bound of X then X
          if (S.nullabilitySuffix == NullabilitySuffix.none &&
              S.isDartCoreObject) {
            var B = element.declaration.bound;
            if (B != null) {
              var B_norm = normalize(B);
              if (B_norm.nullabilitySuffix == NullabilitySuffix.none &&
                  B_norm.isDartCoreObject) {
                return element.declaration.instantiate(
                  nullabilitySuffix: NullabilitySuffix.none,
                );
              }
            }
          }
          // * else X & S
          var promoted = TypeParameterMember(
            element.declaration,
            Substitution.empty,
            S,
          );
          return promoted.instantiate(
            nullabilitySuffix: NullabilitySuffix.none,
          );
        } else {
          // NORM(X extends T)
          // * let S be NORM(T)
          var S = normalize(bound);
          // * if S is Never then Never
          if (identical(S, NeverTypeImpl.instance)) {
            return NeverTypeImpl.instance;
          }
          // * else X extends S
          var promoted = TypeParameterMember(element, Substitution.empty, S);
          return promoted.instantiate(
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
      } else {
        return T;
      }
    }

    // NORM(C<T0, ..., Tn>) = C<R0, ..., Rn> where Ri is NORM(Ti)
    if (T is InterfaceType) {
      return T.element.instantiate(
        typeArguments: T.typeArguments.map(normalize).toList(),
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // NORM(R Function<X extends B>(S)) = R1 Function(X extends B1>(S1)
    var functionType = T as FunctionType;
    var freshTypeParameters = getFreshTypeParameters(functionType.typeFormals);
    for (var typeParameter in freshTypeParameters.freshTypeParameters) {
      if (typeParameter.bound != null) {
        var typeParameterImpl = typeParameter as TypeParameterElementImpl;
        typeParameterImpl.bound = normalize(typeParameter.bound);
      }
    }
    functionType = freshTypeParameters.applyToFunctionType(functionType);
    return FunctionTypeImpl(
      typeFormals: functionType.typeFormals,
      parameters: functionType.parameters.map((e) {
        return ParameterElementImpl.synthetic(
          e.name,
          normalize(e.type),
          // ignore: deprecated_member_use_from_same_package
          e.parameterKind,
        )..isExplicitlyCovariant = e.isCovariant;
      }).toList(),
      returnType: normalize(functionType.returnType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}
