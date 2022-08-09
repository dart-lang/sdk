// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;

import '../builder/member_builder.dart';
import '../problems.dart' show unhandled;
import 'inference_visitor_base.dart';
import 'type_schema_environment.dart';

enum ObjectAccessTargetKind {
  /// A valid access to a statically known instance member on a non-nullable
  /// receiver.
  instanceMember,

  /// A potentially nullable access to a statically known instance member. This
  /// is an erroneous case and a compile-time error is reported.
  nullableInstanceMember,

  /// A valid access to a statically known instance Object member on a
  /// potentially nullable receiver.
  objectMember,

  /// A (non-nullable) access to the `.call` method of a function. This is used
  /// for access on `Function` and on function types.
  callFunction,

  /// A potentially nullable access to the `.call` method of a function. This is
  /// an erroneous case and a compile-time error is reported.
  nullableCallFunction,

  /// A valid access to an extension member.
  extensionMember,

  /// A potentially nullable access to an extension member on an extension of
  /// a non-nullable type. This is an erroneous case and a compile-time error is
  /// reported.
  nullableExtensionMember,

  /// An access on a receiver of type `dynamic`.
  dynamic,

  /// An access on a receiver of type `Never`.
  never,

  /// An access on a receiver of an invalid type. This case is the result of
  /// a previously report error and no error is report this case.
  invalid,

  /// An access to a statically unknown instance member. This is an erroneous
  /// case and a compile-time error is reported.
  missing,

  /// An access to multiple extension members, none of which are most specific.
  /// This is an erroneous case and a compile-time error is reported.
  ambiguous,
}

/// Result for performing an access on an object, like `o.foo`, `o.foo()` and
/// `o.foo = ...`.
class ObjectAccessTarget {
  final ObjectAccessTargetKind kind;
  final DartType? receiverType;
  final Member? member;

  const ObjectAccessTarget.internal(this.kind, this.receiverType, this.member);

  /// Creates an access to the instance [member].
  factory ObjectAccessTarget.interfaceMember(
      DartType receiverType, Member member,
      {required bool isPotentiallyNullable}) {
    // ignore: unnecessary_null_comparison
    assert(member != null);
    // ignore: unnecessary_null_comparison
    assert(isPotentiallyNullable != null);
    return new ObjectAccessTarget.internal(
        isPotentiallyNullable
            ? ObjectAccessTargetKind.nullableInstanceMember
            : ObjectAccessTargetKind.instanceMember,
        receiverType,
        member);
  }

  /// Creates an access to the Object [member].
  factory ObjectAccessTarget.objectMember(
      DartType receiverType, Member member) {
    // ignore: unnecessary_null_comparison
    assert(member != null);
    return new ObjectAccessTarget.internal(
        ObjectAccessTargetKind.objectMember, receiverType, member);
  }

  /// Creates an access to the extension [member].
  factory ObjectAccessTarget.extensionMember(
      DartType receiverType,
      Member member,
      Member? tearoffTarget,
      ProcedureKind kind,
      List<DartType> inferredTypeArguments,
      {bool isPotentiallyNullable}) = ExtensionAccessTarget;

  /// Creates an access to a 'call' method on a function, i.e. a function
  /// invocation.
  const ObjectAccessTarget.callFunction(DartType receiverType)
      : this.internal(ObjectAccessTargetKind.callFunction, receiverType, null);

  /// Creates an access to a 'call' method on a potentially nullable function,
  /// i.e. a function invocation.
  const ObjectAccessTarget.nullableCallFunction(DartType receiverType)
      : this.internal(
            ObjectAccessTargetKind.nullableCallFunction, receiverType, null);

  /// Creates an access on a dynamic receiver type with no known target.
  const ObjectAccessTarget.dynamic()
      : this.internal(ObjectAccessTargetKind.dynamic, null, null);

  /// Creates an access on a receiver of type Never with no known target.
  const ObjectAccessTarget.never()
      : this.internal(ObjectAccessTargetKind.never, null, null);

  /// Creates an access with no target due to an invalid receiver type.
  ///
  /// This is not in itself an error but a consequence of another error.
  const ObjectAccessTarget.invalid()
      : this.internal(ObjectAccessTargetKind.invalid, null, null);

  /// Creates an access with no target.
  ///
  /// This is an error case.
  const ObjectAccessTarget.missing()
      : this.internal(ObjectAccessTargetKind.missing, null, null);

  /// Returns `true` if this is an access to an instance member.
  bool get isInstanceMember => kind == ObjectAccessTargetKind.instanceMember;

  /// Returns `true` if this is an access to an Object member.
  bool get isObjectMember => kind == ObjectAccessTargetKind.objectMember;

  /// Returns `true` if this is an access to an extension member.
  bool get isExtensionMember => kind == ObjectAccessTargetKind.extensionMember;

  /// Returns `true` if this is an access to the 'call' method on a function.
  bool get isCallFunction => kind == ObjectAccessTargetKind.callFunction;

  /// Returns `true` if this is an access to the 'call' method on a potentially
  /// nullable function.
  bool get isNullableCallFunction =>
      kind == ObjectAccessTargetKind.nullableCallFunction;

  /// Returns `true` if this is an access on a `dynamic` receiver type.
  bool get isDynamic => kind == ObjectAccessTargetKind.dynamic;

  /// Returns `true` if this is an access on a `Never` receiver type.
  bool get isNever => kind == ObjectAccessTargetKind.never;

  /// Returns `true` if this is an access on an invalid receiver type.
  bool get isInvalid => kind == ObjectAccessTargetKind.invalid;

  /// Returns `true` if this is an access with no target.
  bool get isMissing => kind == ObjectAccessTargetKind.missing;

  /// Returns `true` if this is an access with no unambiguous target. This
  /// occurs when an implicit extension access is ambiguous.
  bool get isAmbiguous => kind == ObjectAccessTargetKind.ambiguous;

  /// Returns `true` if this is an access to an instance member on a potentially
  /// nullable receiver.
  bool get isNullableInstanceMember =>
      kind == ObjectAccessTargetKind.nullableInstanceMember;

  /// Returns `true` if this is an access to an instance member on a potentially
  /// nullable receiver.
  bool get isNullableExtensionMember =>
      kind == ObjectAccessTargetKind.nullableExtensionMember;

  /// Returns `true` if this is an access to an instance member on a potentially
  /// nullable receiver.
  bool get isNullable =>
      isNullableInstanceMember ||
      isNullableCallFunction ||
      isNullableExtensionMember;

  /// Returns the candidates for an ambiguous extension access.
  List<ExtensionAccessCandidate> get candidates =>
      throw new UnsupportedError('ObjectAccessTarget.candidates');

  /// Returns the original procedure kind, if this is an extension method
  /// target.
  ///
  /// This is need because getters, setters, and methods are converted into
  /// top level methods, but access and invocation should still be treated as
  /// if they are the original procedure kind.
  ProcedureKind get extensionMethodKind =>
      throw new UnsupportedError('ObjectAccessTarget.extensionMethodKind');

  /// Returns inferred type arguments for the type parameters of an extension
  /// method that comes from the extension declaration.
  List<DartType> get inferredExtensionTypeArguments =>
      throw new UnsupportedError(
          'ObjectAccessTarget.inferredExtensionTypeArguments');

  /// Returns the member to use for a tearoff.
  ///
  /// This is currently used for extension methods.
  // TODO(johnniwinther): Normalize use by having `readTarget` and
  //  `invokeTarget`?
  Member? get tearoffTarget =>
      throw new UnsupportedError('ObjectAccessTarget.tearoffTarget');

  FunctionType _getFunctionType(
      InferenceVisitorBase base, DartType calleeType) {
    calleeType = base.resolveTypeParameter(calleeType);
    if (calleeType is FunctionType) {
      if (!base.isNonNullableByDefault) {
        calleeType = legacyErasure(calleeType);
      }
      return calleeType as FunctionType;
    }
    return base.unknownFunction;
  }

  /// Returns the type of [target] when accessed as an invocation on
  /// [receiverType].
  ///
  /// If the target is known not to be invokable [unknownFunction] is returned.
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      T method() {}
  ///      T Function() getter1 => null;
  ///      T getter2 => null;
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.method; // The getter type is `int Function()`.
  ///    c.getter1; // The getter type is `int Function()`.
  ///    c.getter2; // The getter type is [unknownFunction].
  ///
  FunctionType getFunctionType(InferenceVisitorBase base) {
    switch (kind) {
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        return _getFunctionType(base, receiverType!);
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        return base.unknownFunction;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        return _getFunctionType(
            base, base.getGetterTypeForMemberTarget(member!, receiverType!));
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (extensionMethodKind) {
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            FunctionType functionType = member!.function!
                .computeFunctionType(base.libraryBuilder.nonNullable);
            if (!base.isNonNullableByDefault) {
              functionType = legacyErasure(functionType) as FunctionType;
            }
            return functionType;
          case ProcedureKind.Getter:
            // TODO(johnniwinther): Handle implicit .call on extension getter.
            return _getFunctionType(base, member!.function!.returnType);
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
            break;
        }
    }
    throw unhandled('$this', 'getFunctionType', -1, null);
  }

  /// Returns the type of [target] when accessed as a getter on [receiverType].
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      T method() {}
  ///      T getter => null;
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.method; // The getter type is `int Function()`.
  ///    c.getter; // The getter type is `int`.
  ///
  DartType getGetterType(InferenceVisitorBase base) {
    switch (kind) {
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        return receiverType!;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        return const DynamicType();
      case ObjectAccessTargetKind.never:
        return const NeverType.nonNullable();
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        return base.getGetterTypeForMemberTarget(member!, receiverType!);
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (extensionMethodKind) {
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            FunctionType functionType = member!.function!
                .computeFunctionType(base.libraryBuilder.nonNullable);
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, inferredExtensionTypeArguments);
            DartType resultType = substitution.substituteType(new FunctionType(
                functionType.positionalParameters.skip(1).toList(),
                functionType.returnType,
                base.libraryBuilder.nonNullable,
                namedParameters: functionType.namedParameters,
                typeParameters: functionType.typeParameters
                    .skip(inferredExtensionTypeArguments.length)
                    .toList(),
                requiredParameterCount:
                    functionType.requiredParameterCount - 1));
            if (!base.isNonNullableByDefault) {
              resultType = legacyErasure(resultType);
            }
            return resultType;
          case ProcedureKind.Getter:
            FunctionType functionType = member!.function!
                .computeFunctionType(base.libraryBuilder.nonNullable);
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, inferredExtensionTypeArguments);
            DartType resultType =
                substitution.substituteType(functionType.returnType);
            if (!base.isNonNullableByDefault) {
              resultType = legacyErasure(resultType);
            }
            return resultType;
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
            break;
        }
    }
    throw unhandled('$this', 'getGetterType', -1, null);
  }

  DartType getSetterType(InferenceVisitorBase base) {
    switch (kind) {
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        return const DynamicType();
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        Member interfaceMember = member!;
        Class memberClass = interfaceMember.enclosingClass!;
        DartType setterType;
        if (interfaceMember is Procedure) {
          assert(interfaceMember.kind == ProcedureKind.Setter);
          List<VariableDeclaration> setterParameters =
              interfaceMember.function.positionalParameters;
          setterType = setterParameters.length > 0
              ? setterParameters[0].type
              : const DynamicType();
        } else if (interfaceMember is Field) {
          setterType = interfaceMember.type;
        } else {
          throw unhandled(interfaceMember.runtimeType.toString(),
              'getSetterType', -1, null);
        }
        if (memberClass.typeParameters.isNotEmpty) {
          DartType resolvedReceiverType =
              base.resolveTypeParameter(receiverType!);
          if (resolvedReceiverType is InterfaceType) {
            setterType = Substitution.fromPairs(
                    memberClass.typeParameters,
                    base.classHierarchy.getTypeArgumentsAsInstanceOf(
                        resolvedReceiverType, memberClass)!)
                .substituteType(setterType);
          }
        }
        if (!base.isNonNullableByDefault) {
          setterType = legacyErasure(setterType);
        }
        return setterType;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (extensionMethodKind) {
          case ProcedureKind.Setter:
            FunctionType functionType = member!.function!
                .computeFunctionType(base.libraryBuilder.nonNullable);
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, inferredExtensionTypeArguments);
            DartType setterType = substitution
                .substituteType(functionType.positionalParameters[1]);
            if (!base.isNonNullableByDefault) {
              setterType = legacyErasure(setterType);
            }
            return setterType;
          case ProcedureKind.Method:
          case ProcedureKind.Getter:
          case ProcedureKind.Factory:
          case ProcedureKind.Operator:
            break;
        }
        // TODO(johnniwinther): Compute the right setter type.
        return const DynamicType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        break;
    }
    throw unhandled(runtimeType.toString(), 'getSetterType', -1, null);
  }

  bool isSpecialCasedBinaryOperatorForReceiverType(InferenceVisitorBase base) {
    return (isInstanceMember || isObjectMember || isNullableInstanceMember) &&
        member is Procedure &&
        base.typeSchemaEnvironment.isSpecialCasesBinaryForReceiverType(
            member as Procedure, receiverType!,
            isNonNullableByDefault: base.isNonNullableByDefault);
  }

  bool isSpecialCasedTernaryOperator(InferenceVisitorBase base) {
    return (isInstanceMember || isObjectMember || isNullableInstanceMember) &&
        member is Procedure &&
        base.typeSchemaEnvironment.isSpecialCasedTernaryOperator(
            member as Procedure,
            isNonNullableByDefault: base.isNonNullableByDefault);
  }

  /// Returns the type of the 'key' parameter in an [] or []= implementation.
  ///
  /// For instance
  ///
  ///    class Class<K, V> {
  ///      V operator [](K key) => null;
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    extension Extension<K, V> on Class<K, V> {
  ///      V operator [](K key) => null;
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    new Class<int, String>()[0];             // The key type is `int`.
  ///    new Class<int, String>()[0] = 'foo';     // The key type is `int`.
  ///    Extension<int, String>(null)[0];         // The key type is `int`.
  ///    Extension<int, String>(null)[0] = 'foo'; // The key type is `int`.
  ///
  DartType getIndexKeyType(InferenceVisitorBase base) {
    switch (kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            base, base.getGetterTypeForMemberTarget(member!, receiverType!));
        if (functionType.positionalParameters.length >= 1) {
          return functionType.positionalParameters[0];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = member!.function!
                .computeFunctionType(base.libraryBuilder.nonNullable);
            if (functionType.positionalParameters.length >= 2) {
              DartType keyType = functionType.positionalParameters[1];
              if (functionType.typeParameters.isNotEmpty) {
                Substitution substitution = Substitution.fromPairs(
                    functionType.typeParameters,
                    inferredExtensionTypeArguments);
                keyType = substitution.substituteType(keyType);
              }
              if (!base.isNonNullableByDefault) {
                keyType = legacyErasure(keyType);
              }
              return keyType;
            }
            break;
          default:
            throw unhandled('$this', 'getFunctionType', -1, null);
        }
        break;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  /// Returns the type of the 'value' parameter in an []= implementation.
  ///
  /// For instance
  ///
  ///    class Class<K, V> {
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    extension Extension<K, V> on Class<K, V> {
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    new Class<int, String>()[0] = 'foo';     // The value type is `String`.
  ///    Extension<int, String>(null)[0] = 'foo'; // The value type is `String`.
  ///
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    switch (kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            base, base.getGetterTypeForMemberTarget(member!, receiverType!));
        if (functionType.positionalParameters.length >= 2) {
          return functionType.positionalParameters[1];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = member!.function!
                .computeFunctionType(base.libraryBuilder.nonNullable);
            if (functionType.positionalParameters.length >= 3) {
              DartType indexType = functionType.positionalParameters[2];
              if (functionType.typeParameters.isNotEmpty) {
                Substitution substitution = Substitution.fromPairs(
                    functionType.typeParameters,
                    inferredExtensionTypeArguments);
                indexType = substitution.substituteType(indexType);
              }
              if (!base.isNonNullableByDefault) {
                indexType = legacyErasure(indexType);
              }
              return indexType;
            }
            break;
          default:
            throw unhandled('$this', 'getFunctionType', -1, null);
        }
        break;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  /// Returns the return type of the invocation of [target] on [receiverType].
  // TODO(johnniwinther): Cleanup [getFunctionType], [getReturnType],
  // [getIndexKeyType] and [getIndexSetValueType]. We shouldn't need that many.
  DartType getReturnType(InferenceVisitorBase base) {
    switch (kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            base, base.getGetterTypeForMemberTarget(member!, receiverType!));
        return functionType.returnType;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = member!.function!
                .computeFunctionType(base.libraryBuilder.nonNullable);
            DartType returnType = functionType.returnType;
            if (functionType.typeParameters.isNotEmpty) {
              Substitution substitution = Substitution.fromPairs(
                  functionType.typeParameters, inferredExtensionTypeArguments);
              returnType = substitution.substituteType(returnType);
            }
            if (!base.isNonNullableByDefault) {
              returnType = legacyErasure(returnType);
            }
            return returnType;
          default:
            throw unhandled('$this', 'getFunctionType', -1, null);
        }
      case ObjectAccessTargetKind.never:
        return const NeverType.nonNullable();
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  DartType getPositionalParameterTypeForTarget(
      InferenceVisitorBase base, int index) {
    switch (kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            base, base.getGetterTypeForMemberTarget(member!, receiverType!));
        if (functionType.positionalParameters.length > index) {
          return functionType.positionalParameters[index];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        FunctionType functionType = member!.function!
            .computeFunctionType(base.libraryBuilder.nonNullable);
        if (functionType.positionalParameters.length > index + 1) {
          DartType keyType = functionType.positionalParameters[index + 1];
          if (functionType.typeParameters.isNotEmpty) {
            Substitution substitution = Substitution.fromPairs(
                functionType.typeParameters, inferredExtensionTypeArguments);
            keyType = substitution.substituteType(keyType);
          }
          if (!base.isNonNullableByDefault) {
            keyType = legacyErasure(keyType);
          }
          return keyType;
        }
        break;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  @override
  String toString() => 'ObjectAccessTarget($kind,$member)';
}

class ExtensionAccessTarget extends ObjectAccessTarget {
  @override
  final Member? tearoffTarget;
  @override
  final ProcedureKind extensionMethodKind;
  @override
  final List<DartType> inferredExtensionTypeArguments;

  ExtensionAccessTarget(
      DartType receiverType,
      Member member,
      this.tearoffTarget,
      this.extensionMethodKind,
      this.inferredExtensionTypeArguments,
      {bool isPotentiallyNullable: false})
      : super.internal(
            isPotentiallyNullable
                ? ObjectAccessTargetKind.nullableExtensionMember
                : ObjectAccessTargetKind.extensionMember,
            receiverType,
            member);

  @override
  String toString() =>
      'ExtensionAccessTarget($kind,$member,$extensionMethodKind,'
      '$inferredExtensionTypeArguments)';
}

class AmbiguousExtensionAccessTarget extends ObjectAccessTarget {
  @override
  final List<ExtensionAccessCandidate> candidates;

  AmbiguousExtensionAccessTarget(DartType receiverType, this.candidates)
      : super.internal(ObjectAccessTargetKind.ambiguous, receiverType, null);

  @override
  String toString() => 'AmbiguousExtensionAccessTarget($kind,$candidates)';
}

class ExtensionAccessCandidate {
  final MemberBuilder memberBuilder;
  final bool isPlatform;
  final DartType onType;
  final DartType onTypeInstantiateToBounds;
  final ObjectAccessTarget target;

  ExtensionAccessCandidate(this.memberBuilder, this.onType,
      this.onTypeInstantiateToBounds, this.target,
      {required this.isPlatform})
      // ignore: unnecessary_null_comparison
      : assert(isPlatform != null);

  bool? isMoreSpecificThan(TypeSchemaEnvironment typeSchemaEnvironment,
      ExtensionAccessCandidate other) {
    if (this.isPlatform == other.isPlatform) {
      // Both are platform or not platform.
      bool thisIsSubtype = typeSchemaEnvironment.isSubtypeOf(
          this.onType, other.onType, SubtypeCheckMode.withNullabilities);
      bool thisIsSupertype = typeSchemaEnvironment.isSubtypeOf(
          other.onType, this.onType, SubtypeCheckMode.withNullabilities);
      if (thisIsSubtype && !thisIsSupertype) {
        // This is subtype of other and not vice-versa.
        return true;
      } else if (thisIsSupertype && !thisIsSubtype) {
        // [other] is subtype of this and not vice-versa.
        return false;
      } else if (thisIsSubtype || thisIsSupertype) {
        thisIsSubtype = typeSchemaEnvironment.isSubtypeOf(
            this.onTypeInstantiateToBounds,
            other.onTypeInstantiateToBounds,
            SubtypeCheckMode.withNullabilities);
        thisIsSupertype = typeSchemaEnvironment.isSubtypeOf(
            other.onTypeInstantiateToBounds,
            this.onTypeInstantiateToBounds,
            SubtypeCheckMode.withNullabilities);
        if (thisIsSubtype && !thisIsSupertype) {
          // This is subtype of other and not vice-versa.
          return true;
        } else if (thisIsSupertype && !thisIsSubtype) {
          // [other] is subtype of this and not vice-versa.
          return false;
        }
      }
    } else if (other.isPlatform) {
      // This is not platform, [other] is: this  is more specific.
      return true;
    } else {
      // This is platform, [other] is not: other is more specific.
      return false;
    }
    // Neither is more specific than the other.
    return null;
  }
}
