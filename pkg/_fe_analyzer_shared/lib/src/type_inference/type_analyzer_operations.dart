// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis_operations.dart';

/// Type arguments for a map pattern, which exist or not exist only together.
class MapPatternTypeArguments<Type extends Object> {
  final Type keyType;
  final Type valueType;

  MapPatternTypeArguments({
    required this.keyType,
    required this.valueType,
  });
}

class NamedType<Type extends Object> {
  final String name;
  final Type type;

  NamedType(this.name, this.type);
}

class RecordType<Type extends Object> {
  final List<Type> positional;
  final List<NamedType<Type>> named;

  RecordType({
    required this.positional,
    required this.named,
  });
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

  /// Returns the type `Object?`.
  Type get objectQuestionType;

  /// Returns the unknown type schema (`?`) used in type inference.
  TypeSchema get unknownType;

  /// Returns `true` if [type1] and [type2] are structurally equal.
  bool areStructurallyEqual(Type type1, Type type2);

  /// If [type] is a record type, returns it.
  RecordType<Type>? asRecordType(Type type);

  /// Computes the greatest lower bound of [type1] and [type2].
  Type glb(Type type1, Type type2);

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

  /// Returns `true` if [type] is the unknown type context (`?`).
  bool isUnknownType(Type type);

  /// Returns whether [node] is final.
  bool isVariableFinal(Variable node);

  /// Returns the type schema `Iterable`, with type argument
  /// [elementTypeSchema].
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
  MapPatternTypeArguments<Type>? matchMapType(Type type);

  /// If [type] is a subtype of the type `Stream<T>?` for some `T`, returns
  /// the type `T`.  Otherwise returns `null`.
  Type? matchStreamType(Type type);

  /// Computes `NORM` of [type].
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/normalization.md`
  Type normalize(Type type);

  /// Builds the client specific record type.
  Type recordType(
      {required List<Type> positional, required List<NamedType<Type>> named});

  /// Builds the client specific record type schema.
  TypeSchema recordTypeSchema(
      {required List<TypeSchema> positional,
      required List<NamedType<TypeSchema>> named});

  /// Returns the type schema `Stream`, with type argument [elementTypeSchema].
  TypeSchema streamTypeSchema(TypeSchema elementTypeSchema);

  /// Computes the greatest lower bound of [typeSchema1] and [typeSchema2].
  TypeSchema typeSchemaGlb(TypeSchema typeSchema1, TypeSchema typeSchema2);

  /// Determines whether the given type schema corresponds to the `dynamic`
  /// type.
  bool typeSchemaIsDynamic(TypeSchema typeSchema);

  /// Converts a type into a corresponding type schema.
  TypeSchema typeToSchema(Type type);
}
