// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis_operations.dart';
import 'nullability_suffix.dart';

class RecordType<Type extends Object> {
  final List<Type> positional;
  final List<({String name, Type type})> named;

  RecordType({
    required this.positional,
    required this.named,
  });
}

/// Describes all possibility for a type to be derived from a declaration.
///
/// This enum is intended to exhaustively handle all possibilities for a type to
/// be derived from a type declaration. Currently, there are two such kinds of
/// declarations: declarations inducing interfaces for dynamic dispatch (such as
/// classes, mixins, and enums), and extension types.
enum TypeDeclarationKind {
  /// Indication that the type is derived from a declaration inducing interface.
  ///
  /// An example of such declaration can be a class declaration, a mixin
  /// declaration, or an enum declaration.
  interfaceDeclaration,

  /// Indication that the type is derived from an extension type declaration.
  extensionTypeDeclaration,
}

/// Callback API used by the shared type analyzer to query and manipulate the
/// client's representation of variables and types.
abstract interface class TypeAnalyzerOperations<Variable extends Object,
        Type extends Object, TypeSchema extends Object>
    implements FlowAnalysisOperations<Variable, Type> {
  /// Returns the type `double`.
  Type get doubleType;

  /// Returns the type `dynamic`.
  Type get dynamicType;

  /// Returns the type used by the client in the case of errors.
  Type get errorType;

  /// Returns the type `int`.
  Type get intType;

  /// Returns the type `Never`.
  Type get neverType;

  /// Returns the type `Null`.
  Type get nullType;

  /// Returns the type `Object?`.
  Type get objectQuestionType;

  /// Returns the type `Object`.
  Type get objectType;

  /// Returns the unknown type schema (`_`) used in type inference.
  TypeSchema get unknownType;

  /// Returns `true` if [type1] and [type2] are structurally equal.
  bool areStructurallyEqual(Type type1, Type type2);

  /// If [type] is a record type, returns it.
  RecordType<Type>? asRecordType(Type type);

  /// Return the presentation of this type as it should appear when presented
  /// to users in contexts such as error messages.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String getDisplayString(Type type);

  /// Returns the nullability modifier of [type].
  NullabilitySuffix getNullabilitySuffix(Type type);

  /// If [type] was introduced by a class, mixin, enum, or extension type,
  /// returns a [TypeDeclarationKind] indicating what kind of thing it was
  /// introduced by. Otherwise, returns `null`.
  ///
  /// Examples of types derived from a class declarations are `A`, `A?`, `A*`,
  /// `B<T, S>`, where `A` and `B` are the names of class declarations or
  /// extension type declarations, `T` and `S` are types.
  TypeDeclarationKind? getTypeDeclarationKind(Type type);

  /// If at top level [typeSchema] describes a type that was introduced by a
  /// class, mixin, enum, or extension type, returns a [TypeDeclarationKind]
  /// indicating what kind of thing it was introduced by. Otherwise, returns
  /// `null`.
  ///
  /// Examples of type schemas at top level describing types derived from a
  /// declaration are `A`, `A?`, `A*`, `B<T, S>`, `B<_, B<_, _>>?`, where `A`
  /// and `B` are class declarations or extension type declarations, `T` and
  /// `S` are type schemas.
  TypeDeclarationKind? getTypeSchemaDeclarationKind(TypeSchema typeSchema);

  /// Computes the greatest lower bound of [type1] and [type2].
  Type glb(Type type1, Type type2);

  /// Returns the greatest closure of [schema] with respect to the unknown type
  /// (`_`).
  Type greatestClosure(TypeSchema schema);

  /// Queries whether [type] is an "always-exhaustive" type (as defined in the
  /// patterns spec).  Exhaustive types are types for which the switch statement
  /// is required to be exhaustive when patterns support is enabled.
  bool isAlwaysExhaustiveType(Type type);

  /// Returns `true` if [fromType] is assignable to [toType].
  bool isAssignableTo(Type fromType, Type toType);

  /// Returns `true` if [type] is the type `dynamic`.
  bool isDynamic(Type type);

  /// Returns `true` if the type [type] satisfies the type schema [typeSchema].
  bool isTypeSchemaSatisfied(
      {required TypeSchema typeSchema, required Type type});

  /// Returns `true` if [typeSchema] is the unknown type context (`_`).
  bool isUnknownType(TypeSchema typeSchema);

  /// Returns `true` if [type] is `F`, `F?`, or `F*` for some function type `F`.
  bool isFunctionType(Type type);

  /// If [type] takes the form `FutureOr<T>`, `FutureOr<T>?`, or `FutureOr<T>*`
  /// for some `T`, returns the type `T`. Otherwise returns `null`.
  Type? matchFutureOr(Type type);

  /// Returns `true` if [type] is `E<T1, ..., Tn>`, `E<T1, ..., Tn>?`, or
  /// `E<T1, ..., Tn>*` for some extension type declaration E, some
  /// non-negative n, and some types T1, ..., Tn.
  bool isExtensionType(Type type);

  /// Returns `true` if [type] is `A<T1, ..., Tn>`, `A<T1, ..., Tn>?`, or
  /// `A<T1, ..., Tn>*` for some class, mixin, or enum A, some non-negative n,
  /// and some types T1, ..., Tn. The method returns `false` if [type] is an
  /// extension type, a type alias, `Null`, `Never`, or `FutureOr<X>` for any
  /// type `X`.
  bool isInterfaceType(Type type);

  /// Returns `true` if `Null` is a subtype of all types matching [typeSchema].
  ///
  /// The predicate of [isNonNullable] could be computed directly with a subtype
  /// query, but the implementations can do that more efficiently.
  bool isNonNullable(TypeSchema typeSchema);

  /// Returns `true` if [type] is `Null`.
  bool isNull(Type Type);

  /// Returns `true` if [type] is `Object` from `dart:core`. The method returns
  /// `false` for `Object?` and `Object*`.
  bool isObject(Type type);

  /// Returns `true` if [type] is `R`, `R?`, or `R*` for some record type `R`.
  bool isRecordType(Type type);

  /// Returns whether [node] is final.
  bool isVariableFinal(Variable node);

  /// Returns `true` if [type] is the type `void`.
  bool isVoid(Type type);

  /// Returns the type schema `Iterable`, with type argument.
  TypeSchema iterableTypeSchema(TypeSchema elementTypeSchema);

  /// Returns the type `List`, with type argument [elementType].
  Type listType(Type elementType);

  /// Returns the type schema `List`, with type argument [elementTypeSchema].
  TypeSchema listTypeSchema(TypeSchema elementTypeSchema);

  /// Computes the least upper bound of [type1] and [type2].
  Type lub(Type type1, Type type2);

  /// Computes the nullable form of [type], in other words the least upper bound
  /// of [type] and `Null`.
  Type makeNullable(Type type);

  /// Computes the nullable form of [typeSchema].
  TypeSchema makeTypeSchemaNullable(TypeSchema typeSchema);

  /// Returns the type `Map`, with type arguments.
  Type mapType({
    required Type keyType,
    required Type valueType,
  });

  /// Returns the type schema `Map`, with type arguments [keyTypeSchema] and
  /// [elementTypeSchema].
  TypeSchema mapTypeSchema(
      {required TypeSchema keyTypeSchema, required TypeSchema valueTypeSchema});

  /// If [type] is a subtype of the type `Iterable<T>?` for some `T`, returns
  /// the type `T`.  Otherwise returns `null`.
  Type? matchIterableType(Type type);

  /// If [typeSchema] is the type schema `Iterable<T>?` (or a subtype thereof),
  /// for some `T`, returns the type `T`. Otherwise returns `null`.
  TypeSchema? matchIterableTypeSchema(TypeSchema typeSchema);

  /// If [type] is a subtype of the type `List<T>?` for some `T`, returns the
  /// type `T`.  Otherwise returns `null`.
  Type? matchListType(Type type);

  /// If [type] is a subtype of the type `Map<K, V>?` for some `K` and `V`,
  /// returns these `K` and `V`.  Otherwise returns `null`.
  ({Type keyType, Type valueType})? matchMapType(Type type);

  /// If [type] is a subtype of the type `Stream<T>?` for some `T`, returns
  /// the type `T`.  Otherwise returns `null`.
  Type? matchStreamType(Type type);

  /// Computes `NORM` of [type].
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/normalization.md`
  Type normalize(Type type);

  /// Builds the client specific record type.
  Type recordType(
      {required List<Type> positional, required List<(String, Type)> named});

  /// Builds the client specific record type schema.
  TypeSchema recordTypeSchema(
      {required List<TypeSchema> positional,
      required List<(String, TypeSchema)> named});

  /// Returns the type schema `Stream`, with type argument [elementTypeSchema].
  TypeSchema streamTypeSchema(TypeSchema elementTypeSchema);

  /// Returns `true` if [leftType] is a subtype of the greatest closure of
  /// [rightSchema].
  ///
  /// This method can be implemented directly, by computing the greatest
  /// closure of [rightSchema] and then comparing the resulting type and
  /// [leftType] via [isSubtypeOf]. However, that would mean at least two
  /// recursive descends over types. This method is supposed to have optimized
  /// implementations that only use one recursive descend.
  bool typeIsSubtypeOfTypeSchema(Type leftType, TypeSchema rightSchema);

  /// Computes the greatest lower bound of [typeSchema1] and [typeSchema2].
  TypeSchema typeSchemaGlb(TypeSchema typeSchema1, TypeSchema typeSchema2);

  /// Determines whether the given type schema corresponds to the `dynamic`
  /// type.
  bool typeSchemaIsDynamic(TypeSchema typeSchema);

  /// Returns `true` if least closure of [leftSchema] is a subtype of
  /// the greatest closure of [rightSchema].
  ///
  /// This method can be implemented directly, by computing the least closure of
  /// [leftSchema], the greatest closure of [rightSchema], and then comparing
  /// the resulting types via [isSubtypeOf]. However, that would mean at least
  /// three recursive descends over types. This method is supposed to have
  /// optimized implementations that only use one recursive descend.
  bool typeSchemaIsSubtypeOfTypeSchema(
      TypeSchema leftSchema, TypeSchema rightSchema);

  /// Returns `true` if the least closure of [leftSchema] is a subtype of
  /// [rightType].
  ///
  /// This method can be implemented directly, by computing the least closure
  /// of [leftSchema] and then comparing the resulting type and [rightType] via
  /// [isSubtypeOf]. However, that would mean at least two recursive descends
  /// over types. This method is supposed to have optimized implementations
  /// that only use one recursive descend.
  bool typeSchemaIsSubtypeOfType(TypeSchema leftSchema, Type rightType);

  /// Computes the least upper bound of [typeSchema1] and [typeSchema2].
  TypeSchema typeSchemaLub(TypeSchema typeSchema1, TypeSchema typeSchema2);

  /// Converts a type into a corresponding type schema.
  TypeSchema typeToSchema(Type type);

  /// Returns [type] suffixed with the [suffix].
  Type withNullabilitySuffix(Type type, NullabilitySuffix suffix);
}
