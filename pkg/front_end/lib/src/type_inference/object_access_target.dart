// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;

import '../base/problems.dart' show unexpected;
import '../builder/member_builder.dart';
import '../kernel/hierarchy/class_member.dart';
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

  /// A valid access to a statically known super member.
  superMember,

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

  /// An access to a positional record field.
  recordIndexed,

  /// An access to a named record field.
  recordNamed,

  /// A potentially nullable access to a positional record field.
  nullableRecordIndexed,

  /// A potentially nullable access to a named record field.
  nullableRecordNamed,

  /// A valid access to a statically known extension type instance member on a
  /// non-nullable receiver.
  extensionTypeMember,

  /// A potentially nullable access to a statically known extension type
  /// instance member. This is an erroneous case and a compile-time error is
  /// reported.
  nullableExtensionTypeMember,

  /// A valid access to the extension type representation field on a
  /// non-nullable receiver.
  extensionTypeRepresentation,

  /// A potentially nullable access to the extension type instance
  /// representation field. This is an erroneous case and a compile-time error
  /// is reported.
  nullableExtensionTypeRepresentation,
}

/// Type of the target in a function-like invocation.
///
/// [InvocationTargetType] and its subclasses encode the type information about
/// `f` in expressions like `f<int, String>(0.1, isFoo: false)`.
sealed class InvocationTargetType {
  const InvocationTargetType();

  /// If operator == is invoked, returns the target type or its approximation.
  FunctionType get equalsFunctionType;

  /// If `sublist` is invoked, returns the target type or its approximation.
  FunctionType get sublistFunctionType;

  /// If operator - is invoked, returns the target type or its approximation.
  FunctionType get minusFunctionType;

  /// If operator [] is invoked, returns the target type or its approximation.
  FunctionType get indexGetFunctionType;

  /// If operator >= is invoked, returns the target type or its approximation.
  FunctionType get greaterThanOrEqualsFunctionType;

  /// If operator <= is invoked, returns the target type or its approximation.
  FunctionType get lessThanOrEqualsFunctionType;

  /// If one of the operators <, >, <=, >= is invoked, returns the target type
  /// or its approximation.
  FunctionType get relationalFunctionType;

  /// If `containsKey` is invoked, returns the target type or its approximation.
  FunctionType get containsKeyFunctionType;

  /// If operator []= is invoked, returns the target type or its approximation.
  FunctionType get indexSetFunctionType;

  /// If an operator taking one parameter is invoked, returns the target type or
  /// its approximation.
  FunctionType get binaryOperationFunctionType;

  /// The return type of the target type or its approximation.
  DartType get returnType;

  /// [FunctionAccessKind] associated with the target.
  FunctionAccessKind get functionAccessKind;

  /// Returns the target type or computes its approximation that can take
  /// [arguments].
  FunctionType computeFunctionTypeForInference(Arguments arguments);
}

/// Target type that can be expressed as a fully defined [FunctionType].
class InvocationTargetFunctionType extends InvocationTargetType {
  final FunctionType functionType;

  InvocationTargetFunctionType(this.functionType);

  @override
  FunctionType get equalsFunctionType => functionType;

  @override
  FunctionType get sublistFunctionType => functionType;

  @override
  FunctionType get minusFunctionType => functionType;

  @override
  FunctionType get indexGetFunctionType => functionType;

  @override
  FunctionType get greaterThanOrEqualsFunctionType => functionType;

  @override
  FunctionType get lessThanOrEqualsFunctionType => functionType;

  @override
  FunctionType get relationalFunctionType => functionType;

  @override
  FunctionType get containsKeyFunctionType => functionType;

  @override
  FunctionType get indexSetFunctionType => functionType;

  @override
  FunctionType get binaryOperationFunctionType => functionType;

  @override
  DartType get returnType => functionType.returnType;

  @override
  FunctionAccessKind get functionAccessKind => FunctionAccessKind.FunctionType;

  @override
  FunctionType computeFunctionTypeForInference(Arguments arguments) {
    return functionType;
  }
}

/// Base class for all target types that can't be expressed as a fully defined
/// [FunctionType].
sealed class InvocationTargetNonFunctionType extends InvocationTargetType {
  const InvocationTargetNonFunctionType();

  @override
  FunctionType get equalsFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get sublistFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get minusFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get indexGetFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get greaterThanOrEqualsFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get lessThanOrEqualsFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get relationalFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get containsKeyFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionType get indexSetFunctionType {
    return new FunctionType(
        [const DynamicType()], returnType, Nullability.nonNullable);
  }

  @override
  FunctionType get binaryOperationFunctionType {
    return _oneParameterFunctionApproximation;
  }

  @override
  FunctionAccessKind get functionAccessKind {
    // TODO(cstefantsova): Should we have [FunctionAccessKind] elements for the
    // invalid type and the Never type?
    return FunctionAccessKind.Function;
  }

  FunctionType get _oneParameterFunctionApproximation {
    return new FunctionType(
        [const DynamicType()], returnType, Nullability.nonNullable);
  }

  @override
  FunctionType computeFunctionTypeForInference(Arguments arguments) {
    return new FunctionType(
        new List<DartType>.filled(
            arguments.positional.length, const DynamicType()),
        this.returnType,
        Nullability.nonNullable,
        namedParameters: <NamedType>[
          for (NamedExpression namedExpression in arguments.named)
            new NamedType(namedExpression.name, const DynamicType())
        ],
        typeParameters: [
          for (DartType _ in arguments.types)
            new StructuralParameter(
                null, const DynamicType(), const DynamicType())
        ]);
  }
}

/// Target type that accepts all shapes of the arguments.
///
/// For example: `foo(1)`, `bar(2, "3")`, where `foo` has static type `dynamic`
/// and `bar` has static type `Function`.
class InvocationTargetDynamicType extends InvocationTargetNonFunctionType {
  const InvocationTargetDynamicType();

  @override
  DartType get returnType => const DynamicType();
}

/// Target type of an invalid function expression.
///
/// This invocation target type is used whenever the invocation target isn't
/// callable or has static type [InvalidType]. For example, `3()`.
class InvocationTargetInvalidType extends InvocationTargetNonFunctionType {
  const InvocationTargetInvalidType();

  @override
  DartType get returnType => const InvalidType();
}

/// Target type of the `Never` type.
///
/// For example: `(throw 0)(1, 2, 3)`, `X()`, where `X` is a type variable
/// defined as `X extends Never`.
class InvocationTargetNeverType extends InvocationTargetNonFunctionType {
  const InvocationTargetNeverType();

  @override
  DartType get returnType => const NeverType.nonNullable();
}

/// Result for performing an access on an object, like `o.foo`, `o.foo()` and
/// `o.foo = ...`.
abstract class ObjectAccessTarget {
  final ObjectAccessTargetKind kind;

  const ObjectAccessTarget.internal(this.kind);

  /// Creates an access to the instance [member].
  factory ObjectAccessTarget.interfaceMember(
      DartType receiverType, Member member,
      {required bool hasNonObjectMemberAccess}) {
    return hasNonObjectMemberAccess
        ? new InstanceAccessTarget.nonNullable(receiverType, member)
        : new InstanceAccessTarget.nullable(receiverType, member);
  }

  /// Creates an access to the super [member].
  factory ObjectAccessTarget.superMember(DartType receiverType, Member member) =
      InstanceAccessTarget.superMember;

  /// Creates an access to the Object [member].
  factory ObjectAccessTarget.objectMember(
      DartType receiverType, Member member) = InstanceAccessTarget.object;

  /// Creates an access to the extension [member].
  factory ObjectAccessTarget.extensionMember(
      DartType receiverType,
      Member member,
      Member? tearoffTarget,
      ClassMemberKind kind,
      List<DartType> inferredTypeArguments,
      {bool isPotentiallyNullable}) = ExtensionAccessTarget;

  /// Creates an access to the extension type [member].
  factory ObjectAccessTarget.extensionTypeMember(
      DartType receiverType,
      Member member,
      Member? tearoffTarget,
      ClassMemberKind kind,
      List<DartType> extensionTypeArguments,
      {bool hasNonObjectMemberAccess}) = ExtensionTypeAccessTarget;

  /// Creates an access to the [representationField] of the [extensionType].
  factory ObjectAccessTarget.extensionTypeRepresentation(DartType receiverType,
          ExtensionType extensionType, Procedure representationField,
          {required bool hasNonObjectMemberAccess}) =
      ExtensionTypeRepresentationAccessTarget;

  /// Creates an access to a 'call' method on a function, i.e. a function
  /// invocation.
  factory ObjectAccessTarget.callFunction(DartType receiverType) =
      FunctionAccessTarget.nonNullable;

  /// Creates an access to a 'call' method on a potentially nullable function,
  /// i.e. a function invocation.
  factory ObjectAccessTarget.nullableCallFunction(DartType receiverType) =
      FunctionAccessTarget.nullable;

  /// Creates an access on a dynamic receiver type with no known target.
  const factory ObjectAccessTarget.dynamic() = DynamicAccessTarget.dynamic;

  /// Creates an access on a receiver of type Never with no known target.
  factory ObjectAccessTarget.never(
      {Member? member, FunctionType? functionType}) = NeverAccessTarget;

  /// Creates an access with no target due to an invalid receiver type.
  ///
  /// This is not in itself an error but a consequence of another error.
  const factory ObjectAccessTarget.invalid() = DynamicAccessTarget.invalid;

  /// Creates an access with no target.
  ///
  /// This is an error case.
  const factory ObjectAccessTarget.missing() = DynamicAccessTarget.missing;

  DartType? get receiverType;

  Member? get member;

  Member? get classMember {
    Member? member = this.member;
    if (member == null) return null;
    if (member.enclosingClass == null) {
      // TODO(johnniwinther): Unify stub kinds. Should we always make this a
      // member signature, merge member signature and abstract forwarding stub,
      // or add a new stub kind for abstract extension type members?
      assert(
          member.enclosingExtensionTypeDeclaration != null,
          // Coverage-ignore(suite): Not run.
          "Unexpected member without an enclosing class $member.");
      member = (member as Procedure).stubTarget!;
    }
    assert(
        member.enclosingClass != null, // Coverage-ignore(suite): Not run.
        "No enclosing class found on $member.");
    return member;
  }

  // Coverage-ignore(suite): Not run.
  /// The access index, if this is an access to a positional record field.
  /// Otherwise null.
  int? get recordFieldIndex => null;

  // Coverage-ignore(suite): Not run.
  /// The access name, if this is an access to a named record field.
  /// Otherwise null.
  String? get recordFieldName => null;

  /// Returns `true` if this is an access to an instance member.
  bool get isInstanceMember => kind == ObjectAccessTargetKind.instanceMember;

  /// Returns `true` if this is an access to a super member.
  bool get isSuperMember => kind == ObjectAccessTargetKind.superMember;

  /// Returns `true` if this is an access to an Object member.
  bool get isObjectMember => kind == ObjectAccessTargetKind.objectMember;

  /// Returns `true` if this is an access to an extension member.
  bool get isExtensionMember => kind == ObjectAccessTargetKind.extensionMember;

  /// Returns `true` if this is an access to an extension type member.
  bool get isExtensionTypeMember =>
      kind == ObjectAccessTargetKind.extensionTypeMember;

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

  /// Returns `true` if this is an access to a record index on a potentially
  /// nullable receiver.
  bool get isNullableRecordIndexedAccess =>
      kind == ObjectAccessTargetKind.nullableRecordIndexed;

  /// Returns `true` if this is an access to a named record field on a
  /// potentially nullable receiver.
  bool get isNullableRecordNamedAccess =>
      kind == ObjectAccessTargetKind.nullableRecordNamed;

  /// Returns `true` if this is an access to an extension member on a
  /// potentially nullable receiver.
  bool get isNullableExtensionMember =>
      kind == ObjectAccessTargetKind.nullableExtensionMember;

  /// Returns `true` if this is an access to an extension type member on a
  /// potentially nullable receiver.
  bool get isNullableExtensionTypeMember =>
      kind == ObjectAccessTargetKind.nullableExtensionTypeMember;

  /// Returns `true` if this is an access to the representation field of an
  /// extension type on a potentially nullable receiver.
  bool get isNullableExtensionTypeRepresentation =>
      kind == ObjectAccessTargetKind.nullableExtensionTypeRepresentation;

  /// Returns `true` if this is an *invalid* access to an instance member on a
  /// potentially nullable receiver.
  bool get isNullable =>
      isNullableInstanceMember ||
      isNullableCallFunction ||
      isNullableExtensionMember ||
      isNullableRecordIndexedAccess ||
      isNullableRecordNamedAccess ||
      isNullableExtensionTypeMember ||
      isNullableExtensionTypeRepresentation;

  // Coverage-ignore(suite): Not run.
  /// Returns the candidates for an ambiguous extension access.
  List<ExtensionAccessCandidate> get candidates =>
      throw new UnsupportedError('ObjectAccessTarget.candidates');

  // Coverage-ignore(suite): Not run.
  /// Returns the original procedure kind, if this is an extension method or
  /// extension type method target.
  ///
  /// This is need because getters, setters, and methods are converted into
  /// top level methods, but access and invocation should still be treated as
  /// if they are the original procedure kind.
  ClassMemberKind get declarationMethodKind =>
      throw new UnsupportedError('ObjectAccessTarget.declarationMethodKind');

  // Coverage-ignore(suite): Not run.
  /// Returns type arguments for the type parameters of an extension or
  /// extension type method that comes from the extension or extension type
  /// declaration. These are determined from the receiver of the access.
  List<DartType> get receiverTypeArguments =>
      throw new UnsupportedError('ObjectAccessTarget.receiverTypeArguments');

  // Coverage-ignore(suite): Not run.
  /// Returns the member to use for a tearoff.
  ///
  /// This is currently used for extension methods.
  // TODO(johnniwinther): Normalize use by having `readTarget` and
  //  `invokeTarget`?
  Member? get tearoffTarget =>
      throw new UnsupportedError('ObjectAccessTarget.tearoffTarget');

  InvocationTargetType _getFunctionType(
      InferenceVisitorBase base, DartType calleeType) {
    calleeType = calleeType.nonTypeVariableBound;
    if (calleeType is FunctionType) {
      return new InvocationTargetFunctionType(calleeType);
    } else if (calleeType == base.coreTypes.functionNonNullableRawType ||
        calleeType is DynamicType) {
      return const InvocationTargetDynamicType();
    } else if (calleeType is NeverType) {
      // TODO(cstefantsova): Should we insert the nullability assert somewhere
      // earlier?
      assert(calleeType.nullability == Nullability.nonNullable);
      return const InvocationTargetNeverType();
    } else {
      return const InvocationTargetInvalidType();
    }
  }

  /// Returns the type of this target when accessed as an invocation on
  /// [receiverType].
  ///
  /// If the target is known not to be invokable
  /// [InferenceVisitorBase.unknownFunction] is returned.
  ///
  /// For instance
  ///
  ///    abstract class Class<T> {
  ///      T method();
  ///      T Function() get getter1;
  ///      T get getter2;
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.method; // The getter type is `int Function()`.
  ///    c.getter1; // The getter type is `int Function()`.
  ///    c.getter2; // The getter type is [unknownFunction].
  ///
  InvocationTargetType getFunctionType(InferenceVisitorBase base);

  /// Returns the type of this target when accessed as a getter on
  /// [receiverType].
  ///
  /// For instance
  ///
  ///    abstract class Class<T> {
  ///      T method();
  ///      T get getter;
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.method; // The getter type is `int Function()`.
  ///    c.getter; // The getter type is `int`.
  ///
  DartType getGetterType(InferenceVisitorBase base);

  /// Returns the type of this target when accessed as a setter on
  /// [receiverType].
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      void set setter(T value) {}
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.setter = 42; // The setter type is `int`.
  ///
  DartType getSetterType(InferenceVisitorBase base);

  /// Returns `true` if this target is binary operator, whose return type is
  /// specialized to take the operand type into account.
  ///
  /// This is for instance the case for `int.+` which returns `int` when the
  /// operand is of type `int` and `num` otherwise.
  bool isSpecialCasedBinaryOperator(InferenceVisitorBase base) => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if this target is ternary operator, whose return type is
  /// specialized to take the operand type into account.
  ///
  /// This is for instance the case for `int.clamp` which returns `int` when the
  /// operands are of type `int` and `num` otherwise.
  bool isSpecialCasedTernaryOperator(InferenceVisitorBase base) => false;

  /// Returns the type of the 'key' parameter in an [] or []= implementation.
  ///
  /// For instance
  ///
  ///    class Class<K, V> {
  ///      V operator [](K key) => throw '';
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    extension Extension<K, V> on Class<K, V> {
  ///      V operator [](K key) => throw '';
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    new Class<int, String>()[0];             // The key type is `int`.
  ///    new Class<int, String>()[0] = 'foo';     // The key type is `int`.
  ///    Extension<int, String>(null)[0];         // The key type is `int`.
  ///    Extension<int, String>(null)[0] = 'foo'; // The key type is `int`.
  ///
  DartType getIndexKeyType(InferenceVisitorBase base);

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
  DartType getIndexSetValueType(InferenceVisitorBase base);

  /// Returns the return type of the invocation of this target on
  /// [receiverType].
  ///
  /// If the target is known not to be invokable `dynamic` is returned.
  ///
  /// For instance
  ///
  ///    abstract class Class<T> {
  ///      T method();
  ///      T Function() get getter1;
  ///      T get getter2;
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.method(); // The return type is `int`.
  ///    c.getter1(); // The return type is `int`.
  ///    c.getter2(); // The return type is `dynamic`.
  ///
  // TODO(johnniwinther): Cleanup [getFunctionType], [getReturnType],
  // [getIndexKeyType] and [getIndexSetValueType]. We shouldn't need that many.
  DartType getReturnType(InferenceVisitorBase base);

  /// Returns the operand type of this target accessed as a binary operation
  /// on [receiverType].
  ///
  /// For instance
  ///
  ///    abstract class Class<T> {
  ///      T operator +(T t);
  ///      T operator - (List<T> t);
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c + 0; // The operand type is `int`.
  ///    c - [0]; // The operand type is `List<int>`.
  ///
  DartType getBinaryOperandType(InferenceVisitorBase base);

  @override
  String toString() => 'ObjectAccessTarget($kind,$member)';
}

class InstanceAccessTarget extends ObjectAccessTarget {
  @override
  final DartType receiverType;
  @override
  final Member member;

  DartType? _cachedGetterType;
  InferenceVisitorBase? _cachedGetterTypeBase;

  /// Creates an access to the instance [member].
  InstanceAccessTarget.nonNullable(this.receiverType, this.member)
      : super.internal(ObjectAccessTargetKind.instanceMember);

  /// Creates an access to the instance [member].
  InstanceAccessTarget.nullable(this.receiverType, this.member)
      : super.internal(ObjectAccessTargetKind.nullableInstanceMember);

  /// Creates an access to the super [member].
  InstanceAccessTarget.superMember(this.receiverType, this.member)
      : super.internal(ObjectAccessTargetKind.superMember);

  /// Creates an access to the Object [member].
  InstanceAccessTarget.object(this.receiverType, this.member)
      : super.internal(ObjectAccessTargetKind.objectMember);

  @override
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    return _getFunctionType(base, getGetterType(base));
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    if (_cachedGetterType != null && identical(_cachedGetterTypeBase, base)) {
      return _cachedGetterType!;
    }
    _cachedGetterType = base.getGetterTypeForMemberTarget(member, receiverType,
        isSuper: isSuperMember);
    _cachedGetterTypeBase = base;
    return _cachedGetterType!;
  }

  @override
  DartType getSetterType(InferenceVisitorBase base) {
    return base.getSetterTypeForMemberTarget(member, receiverType,
        isSuper: isSuperMember);
  }

  @override
  bool isSpecialCasedBinaryOperator(InferenceVisitorBase base) {
    return member is Procedure &&
        base.typeSchemaEnvironment
            .isSpecialCasedBinaryOperator(member as Procedure);
  }

  @override
  bool isSpecialCasedTernaryOperator(InferenceVisitorBase base) {
    return member is Procedure &&
        base.typeSchemaEnvironment
            .isSpecialCasedTernaryOperator(member as Procedure);
  }

  @override
  DartType getIndexKeyType(InferenceVisitorBase base) {
    InvocationTargetType invocationTargetType =
        _getFunctionType(base, getGetterType(base));
    FunctionType indexGetFunctionType =
        invocationTargetType.indexGetFunctionType;
    switch (invocationTargetType) {
      case InvocationTargetFunctionType():
        if (indexGetFunctionType.positionalParameters.isNotEmpty) {
          return indexGetFunctionType.positionalParameters.first;
        } else {
          return const DynamicType();
        }
      case InvocationTargetDynamicType():
      case InvocationTargetInvalidType():
      case InvocationTargetNeverType():
        return invocationTargetType
            .indexGetFunctionType.positionalParameters.first;
    }
  }

  @override
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    InvocationTargetType invocationTargetType =
        _getFunctionType(base, getGetterType(base));
    FunctionType indexSetFunctionType =
        invocationTargetType.indexSetFunctionType;
    switch (invocationTargetType) {
      case InvocationTargetFunctionType():
        if (indexSetFunctionType.positionalParameters.length >= 2) {
          return indexSetFunctionType.positionalParameters[1];
        } else {
          return const DynamicType();
        }
      case InvocationTargetDynamicType():
      case InvocationTargetInvalidType():
      case InvocationTargetNeverType():
        return invocationTargetType
            .indexGetFunctionType.positionalParameters[1];
    }
  }

  @override
  DartType getReturnType(InferenceVisitorBase base) {
    return _getFunctionType(base, getGetterType(base)).returnType;
  }

  @override
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    InvocationTargetType invocationTargetType =
        _getFunctionType(base, getGetterType(base));
    FunctionType binaryOperationFunctionType =
        invocationTargetType.binaryOperationFunctionType;
    switch (invocationTargetType) {
      case InvocationTargetFunctionType():
        if (binaryOperationFunctionType.positionalParameters.isNotEmpty) {
          return binaryOperationFunctionType.positionalParameters.first;
        } else {
          return const DynamicType();
        }
      case InvocationTargetDynamicType():
      case InvocationTargetInvalidType():
      case InvocationTargetNeverType():
        return invocationTargetType
            .indexGetFunctionType.positionalParameters.first;
    }
  }
}

class FunctionAccessTarget extends ObjectAccessTarget {
  @override
  final DartType receiverType;

  /// Creates an access to a 'call' method on a function, i.e. a function
  /// invocation.
  FunctionAccessTarget.nonNullable(this.receiverType)
      : super.internal(ObjectAccessTargetKind.callFunction);

  /// Creates an access to a 'call' method on a potentially nullable function,
  /// i.e. a function invocation.
  FunctionAccessTarget.nullable(this.receiverType)
      : super.internal(ObjectAccessTargetKind.nullableCallFunction);

  @override
  Member? get member => null;

  @override
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    return _getFunctionType(base, receiverType);
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    return receiverType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getSetterType(InferenceVisitorBase base) {
    assert(false, "Unexpected call to ${runtimeType}.getSetterType");
    return const DynamicType();
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getIndexKeyType(InferenceVisitorBase base) {
    return const DynamicType();
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    return const DynamicType();
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getReturnType(InferenceVisitorBase base) {
    return getFunctionType(base).returnType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    return const DynamicType();
  }
}

class DynamicAccessTarget extends ObjectAccessTarget {
  /// Creates an access on a dynamic receiver type with no known target.
  const DynamicAccessTarget.dynamic()
      : super // Coverage-ignore(suite): Not run.
        .internal(ObjectAccessTargetKind.dynamic);

  /// Creates an access with no target due to an invalid receiver type.
  ///
  /// This is not in itself an error but a consequence of another error.
  const DynamicAccessTarget.invalid()
      : super // Coverage-ignore(suite): Not run.
        .internal(ObjectAccessTargetKind.invalid);

  /// Creates an access with no target.
  ///
  /// This is an error case.
  const DynamicAccessTarget.missing()
      : super // Coverage-ignore(suite): Not run.
        .internal(ObjectAccessTargetKind.missing);

  @override
  // Coverage-ignore(suite): Not run.
  DartType? get receiverType => null;

  @override
  Member? get member => null;

  @override
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    return isInvalid
        ? const InvocationTargetInvalidType()
        : const InvocationTargetDynamicType();
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    return isInvalid ? const InvalidType() : const DynamicType();
  }

  @override
  DartType getSetterType(InferenceVisitorBase base) {
    return isInvalid ? const InvalidType() : const DynamicType();
  }

  @override
  DartType getIndexKeyType(InferenceVisitorBase base) {
    return isInvalid ? const InvalidType() : const DynamicType();
  }

  @override
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    return isInvalid ? const InvalidType() : const DynamicType();
  }

  @override
  DartType getReturnType(InferenceVisitorBase base) {
    return isInvalid ? const InvalidType() : const DynamicType();
  }

  @override
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    return isInvalid ? const InvalidType() : const DynamicType();
  }
}

class NeverAccessTarget extends ObjectAccessTarget {
  @override
  final Member? member;

  final FunctionType? functionType;

  /// Creates an access on a receiver of type Never. If the target is known,
  /// being from `Object`, it is provided as [member] together with its
  /// function type.
  NeverAccessTarget({this.member, this.functionType})
      : super.internal(ObjectAccessTargetKind.never);

  @override
  // Coverage-ignore(suite): Not run.
  DartType? get receiverType => null;

  @override
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    return functionType != null
        ? new InvocationTargetFunctionType(functionType!)
        : const InvocationTargetNeverType();
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    return const NeverType.nonNullable();
  }

  @override
  DartType getSetterType(InferenceVisitorBase base) {
    return const DynamicType();
  }

  @override
  DartType getIndexKeyType(InferenceVisitorBase base) {
    return const DynamicType();
  }

  @override
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    return const DynamicType();
  }

  @override
  DartType getReturnType(InferenceVisitorBase base) {
    return const NeverType.nonNullable();
  }

  @override
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    return const DynamicType();
  }
}

class ExtensionAccessTarget extends ObjectAccessTarget {
  @override
  final DartType receiverType;
  @override
  final Member member;
  @override
  final Member? tearoffTarget;
  @override
  final ClassMemberKind declarationMethodKind;
  @override
  final List<DartType> receiverTypeArguments;

  ExtensionAccessTarget(this.receiverType, this.member, this.tearoffTarget,
      this.declarationMethodKind, this.receiverTypeArguments,
      {bool isPotentiallyNullable = false})
      : super.internal(isPotentiallyNullable
            ? ObjectAccessTargetKind.nullableExtensionMember
            : ObjectAccessTargetKind.extensionMember);

  @override
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        return new InvocationTargetFunctionType(functionType);
      case ClassMemberKind.Getter:
        // TODO(johnniwinther): Handle implicit .call on extension getter.
        return _getFunctionType(base, member.function!.returnType);
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getFunctionType', -1, null);
    }
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        List<StructuralParameter> extensionTypeParameters = functionType
            .typeParameters
            .take(receiverTypeArguments.length)
            .toList();
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
                extensionTypeParameters, receiverTypeArguments);
        DartType resultType = instantiator.substitute(new FunctionType(
            functionType.positionalParameters.skip(1).toList(),
            functionType.returnType,
            Nullability.nonNullable,
            namedParameters: functionType.namedParameters,
            typeParameters: functionType.typeParameters
                .skip(receiverTypeArguments.length)
                .toList(),
            requiredParameterCount: functionType.requiredParameterCount - 1));
        return resultType;
      case ClassMemberKind.Getter:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        List<StructuralParameter> extensionTypeParameters = functionType
            .typeParameters
            .take(receiverTypeArguments.length)
            .toList();
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
                extensionTypeParameters, receiverTypeArguments);
        DartType resultType = instantiator.substitute(functionType.returnType);
        return resultType;
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getGetterType', -1, null);
    }
  }

  @override
  DartType getSetterType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Setter:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        List<StructuralParameter> extensionTypeParameters = functionType
            .typeParameters
            .take(receiverTypeArguments.length)
            .toList();
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
                extensionTypeParameters, receiverTypeArguments);
        DartType setterType =
            instantiator.substitute(functionType.positionalParameters[1]);
        return setterType;
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Method:
      case ClassMemberKind.Getter:
        throw unexpected('$this', 'getSetterType', -1, null);
    }
  }

  @override
  DartType getIndexKeyType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        if (functionType.positionalParameters.length >= 2) {
          DartType keyType = functionType.positionalParameters[1];
          if (functionType.typeParameters.isNotEmpty) {
            FunctionTypeInstantiator instantiator =
                new FunctionTypeInstantiator.fromIterables(
                    functionType.typeParameters, receiverTypeArguments);
            keyType = instantiator.substitute(keyType);
          }
          return keyType;
        }
        return const InvalidType();
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getIndexKeyType', -1, null);
    }
  }

  @override
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        if (functionType.positionalParameters.length >= 3) {
          DartType indexType = functionType.positionalParameters[2];
          if (functionType.typeParameters.isNotEmpty) {
            FunctionTypeInstantiator instantiator =
                new FunctionTypeInstantiator.fromIterables(
                    functionType.typeParameters, receiverTypeArguments);
            indexType = instantiator.substitute(indexType);
          }
          return indexType;
        }
        return const InvalidType();
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getIndexSetValueType', -1, null);
    }
  }

  @override
  DartType getReturnType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        DartType returnType = functionType.returnType;
        if (functionType.typeParameters.isNotEmpty) {
          FunctionTypeInstantiator instantiator =
              new FunctionTypeInstantiator.fromIterables(
                  functionType.typeParameters, receiverTypeArguments);
          returnType = instantiator.substitute(returnType);
        }
        return returnType;
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Setter:
        return const VoidType();
    }
  }

  @override
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        if (functionType.positionalParameters.length > 1) {
          DartType keyType = functionType.positionalParameters[1];
          if (functionType.typeParameters.isNotEmpty) {
            // Coverage-ignore-block(suite): Not run.
            FunctionTypeInstantiator instantiator =
                new FunctionTypeInstantiator.fromIterables(
                    functionType.typeParameters, receiverTypeArguments);
            keyType = instantiator.substitute(keyType);
          }
          return keyType;
        }
        return const InvalidType();
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
      case ClassMemberKind.Setter:
        return const InvalidType();
    }
  }

  @override
  String toString() =>
      'ExtensionAccessTarget($kind,$member,$declarationMethodKind,'
      '$receiverTypeArguments)';
}

class AmbiguousExtensionAccessTarget extends ObjectAccessTarget {
  @override
  final DartType receiverType;

  @override
  final List<ExtensionAccessCandidate> candidates;

  AmbiguousExtensionAccessTarget(this.receiverType, this.candidates)
      : super.internal(ObjectAccessTargetKind.ambiguous);

  @override
  Member? get member => null;

  @override
  // Coverage-ignore(suite): Not run.
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    return const InvocationTargetInvalidType();
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    return const InvalidType();
  }

  @override
  DartType getSetterType(InferenceVisitorBase base) {
    return const InvalidType();
  }

  @override
  DartType getIndexKeyType(InferenceVisitorBase base) {
    return const InvalidType();
  }

  @override
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    return const InvalidType();
  }

  @override
  DartType getReturnType(InferenceVisitorBase base) {
    return const InvalidType();
  }

  @override
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    return const InvalidType();
  }

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
      {required this.isPlatform});

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
    }
    // Coverage-ignore(suite): Not run.
    else if (other.isPlatform) {
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

abstract class RecordAccessTarget extends ObjectAccessTarget {
  @override
  final RecordType receiverType;

  final DartType fieldType;

  RecordAccessTarget(
      this.receiverType, this.fieldType, ObjectAccessTargetKind kind)
      : super.internal(kind);

  @override
  // Coverage-ignore(suite): Not run.
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    return const DynamicType();
  }

  @override
  // Coverage-ignore(suite): Not run.
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    return _getFunctionType(base, getGetterType(base));
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    return fieldType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getIndexKeyType(InferenceVisitorBase base) {
    throw unexpected(runtimeType.toString(), 'getIndexKeyType', -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    throw unexpected(runtimeType.toString(), 'getIndexSetValueType', -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getReturnType(InferenceVisitorBase base) {
    return getFunctionType(base).returnType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getSetterType(InferenceVisitorBase base) {
    throw unexpected(runtimeType.toString(), 'getSetterType', -1, null);
  }

  @override
  Member? get member => null;
}

class RecordIndexTarget extends RecordAccessTarget {
  @override
  final int recordFieldIndex;

  RecordIndexTarget.nonNullable(
      RecordType receiverType, DartType fieldType, this.recordFieldIndex)
      : super(receiverType, fieldType, ObjectAccessTargetKind.recordIndexed);

  RecordIndexTarget.nullable(
      RecordType receiverType, DartType fieldType, this.recordFieldIndex)
      : super(receiverType, fieldType,
            ObjectAccessTargetKind.nullableRecordIndexed);
}

class RecordNameTarget extends RecordAccessTarget {
  @override
  final String recordFieldName;

  RecordNameTarget.nonNullable(
      RecordType receiverType, DartType fieldType, this.recordFieldName)
      : super(receiverType, fieldType, ObjectAccessTargetKind.recordNamed);

  RecordNameTarget.nullable(
      RecordType receiverType, DartType fieldType, this.recordFieldName)
      : super(receiverType, fieldType,
            ObjectAccessTargetKind.nullableRecordNamed);
}

class ExtensionTypeAccessTarget extends ObjectAccessTarget {
  @override
  final DartType receiverType;
  @override
  final Member member;
  // TODO(johnniwinther): Normalize this. [ExtensionAccessTarget] has a tear-off
  // target for all readable members, whereas [ExtensionTypeAccessTarget] only
  // has a tear-off target when it differs from the [member].
  @override
  final Member? tearoffTarget;
  @override
  final ClassMemberKind declarationMethodKind;
  @override
  final List<DartType> receiverTypeArguments;

  ExtensionTypeAccessTarget(this.receiverType, this.member, this.tearoffTarget,
      this.declarationMethodKind, this.receiverTypeArguments,
      {bool hasNonObjectMemberAccess = true})
      : super.internal(hasNonObjectMemberAccess
            ? ObjectAccessTargetKind.extensionTypeMember
            : ObjectAccessTargetKind.nullableExtensionTypeMember);

  @override
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        return new InvocationTargetFunctionType(functionType);
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
        // TODO(johnniwinther): Handle implicit .call on extension getter.
        return _getFunctionType(base, member.function!.returnType);
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getFunctionType', -1, null);
    }
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        List<StructuralParameter> extensionTypeParameters = functionType
            .typeParameters
            .take(receiverTypeArguments.length)
            .toList();
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
                extensionTypeParameters, receiverTypeArguments);
        DartType resultType = instantiator.substitute(new FunctionType(
            functionType.positionalParameters.skip(1).toList(),
            functionType.returnType,
            Nullability.nonNullable,
            namedParameters: functionType.namedParameters,
            typeParameters: functionType.typeParameters
                .skip(receiverTypeArguments.length)
                .toList(),
            requiredParameterCount: functionType.requiredParameterCount - 1));
        return resultType;
      case ClassMemberKind.Getter:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        List<StructuralParameter> extensionTypeParameters = functionType
            .typeParameters
            .take(receiverTypeArguments.length)
            .toList();
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
                extensionTypeParameters, receiverTypeArguments);
        DartType resultType = instantiator.substitute(functionType.returnType);
        return resultType;
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getGetterType', -1, null);
    }
  }

  @override
  DartType getSetterType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Setter:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        List<StructuralParameter> extensionTypeParameters = functionType
            .typeParameters
            .take(receiverTypeArguments.length)
            .toList();
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
                extensionTypeParameters, receiverTypeArguments);
        DartType setterType =
            instantiator.substitute(functionType.positionalParameters[1]);
        return setterType;
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Method:
      case ClassMemberKind.Getter:
        throw unexpected('$this', 'getSetterType', -1, null);
    }
  }

  @override
  DartType getIndexKeyType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        if (functionType.positionalParameters.length >= 2) {
          DartType keyType = functionType.positionalParameters[1];
          if (functionType.typeParameters.isNotEmpty) {
            FunctionTypeInstantiator instantiator =
                new FunctionTypeInstantiator.fromIterables(
                    functionType.typeParameters, receiverTypeArguments);
            keyType = instantiator.substitute(keyType);
          }
          return keyType;
        }
        return const InvalidType();
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getIndexKeyType', -1, null);
    }
  }

  @override
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        if (functionType.positionalParameters.length >= 3) {
          DartType indexType = functionType.positionalParameters[2];
          if (functionType.typeParameters.isNotEmpty) {
            FunctionTypeInstantiator instantiator =
                new FunctionTypeInstantiator.fromIterables(
                    functionType.typeParameters, receiverTypeArguments);
            indexType = instantiator.substitute(indexType);
          }
          return indexType;
        }
        return const InvalidType();
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
      case ClassMemberKind.Setter:
        throw unexpected('$this', 'getIndexSetValueType', -1, null);
    }
  }

  @override
  DartType getReturnType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        DartType returnType = functionType.returnType;
        if (functionType.typeParameters.isNotEmpty) {
          FunctionTypeInstantiator instantiator =
              new FunctionTypeInstantiator.fromIterables(
                  functionType.typeParameters, receiverTypeArguments);
          returnType = instantiator.substitute(returnType);
        }
        return returnType;
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Setter:
        return const VoidType();
    }
  }

  @override
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    switch (declarationMethodKind) {
      case ClassMemberKind.Method:
        FunctionType functionType =
            member.function!.computeFunctionType(Nullability.nonNullable);
        if (functionType.positionalParameters.length > 1) {
          DartType keyType = functionType.positionalParameters[1];
          if (functionType.typeParameters.isNotEmpty) {
            FunctionTypeInstantiator instantiator =
                new FunctionTypeInstantiator.fromIterables(
                    functionType.typeParameters, receiverTypeArguments);
            keyType = instantiator.substitute(keyType);
          }
          return keyType;
        }
        return const InvalidType();
      // Coverage-ignore(suite): Not run.
      case ClassMemberKind.Getter:
      case ClassMemberKind.Setter:
        return const InvalidType();
    }
  }

  @override
  String toString() =>
      'ExtensionTypeAccessTarget($kind,$member,$declarationMethodKind,'
      '$receiverTypeArguments)';
}

class ExtensionTypeRepresentationAccessTarget extends ObjectAccessTarget {
  @override
  final DartType receiverType;
  final ExtensionType extensionType;
  final Procedure representationField;

  ExtensionTypeRepresentationAccessTarget(
      this.receiverType, this.extensionType, this.representationField,
      {required bool hasNonObjectMemberAccess})
      : super.internal(hasNonObjectMemberAccess
            ? ObjectAccessTargetKind.extensionTypeRepresentation
            : ObjectAccessTargetKind.nullableExtensionTypeRepresentation);

  @override
  // Coverage-ignore(suite): Not run.
  DartType getBinaryOperandType(InferenceVisitorBase base) {
    throw unexpected('$this', 'getBinaryOperandType', -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InvocationTargetType getFunctionType(InferenceVisitorBase base) {
    return _getFunctionType(base, getGetterType(base));
  }

  @override
  DartType getGetterType(InferenceVisitorBase base) {
    return base.getGetterTypeForMemberTarget(representationField, receiverType,
        isSuper: false);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getIndexKeyType(InferenceVisitorBase base) {
    throw unexpected('$this', 'getIndexKeyType', -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getIndexSetValueType(InferenceVisitorBase base) {
    throw unexpected('$this', 'getIndexSetValueType', -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getReturnType(InferenceVisitorBase base) {
    throw unexpected('$this', 'getReturnType', -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getSetterType(InferenceVisitorBase base) {
    throw unexpected('$this', 'getSetterType', -1, null);
  }

  @override
  Member? get member => null;

  @override
  String toString() => 'ExtensionTypeRepresentationAccessTarget'
      '($kind,$receiverType,$extensionType)';
}
