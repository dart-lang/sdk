// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis_operations.dart';
import '../types/shared_type.dart';
import 'nullability_suffix.dart';

/// Callback API used by the shared type analyzer to query and manipulate the
/// client's representation of variables and types.
///
/// Concrete classes that implement this class should also mix in
/// [TypeAnalyzerOperationsMixin], which provides the implementations of the
/// operations for types and type schemas using the related operations on type
/// structures, implemented by the concrete class itself. For example,
/// [TypeAnalyzerOperationsMixin] adds [TypeAnalyzerOperationsMixin.futureType]
/// and [TypeAnalyzerOperationsMixin.futureTypeSchema] that are defined in terms
/// of [TypeAnalyzerOperations.futureTypeInternal], so a concrete class
/// implementing [TypeAnalyzerOperations] needs to implement only
/// `futureTypeInternal` to receive the implementations of both `futureType` and
/// `futureTypeSchema` by mixing in [TypeAnalyzerOperationsMixin].
abstract interface class TypeAnalyzerOperations<
        TypeStructure extends SharedTypeStructure<TypeStructure>,
        Variable extends Object,
        // Work around https://github.com/dart-lang/dart_style/issues/1568
        // ignore: lines_longer_than_80_chars
        TypeParameterStructure extends SharedTypeParameterStructure<TypeStructure>,
        TypeDeclarationType extends Object,
        TypeDeclaration extends Object>
    implements FlowAnalysisOperations<Variable, SharedTypeView<TypeStructure>> {
  /// Returns the type `double`.
  SharedTypeView<TypeStructure> get doubleType;

  /// Returns the type `dynamic`.
  SharedTypeView<TypeStructure> get dynamicType;

  /// Returns the type used by the client in the case of errors.
  SharedTypeView<TypeStructure> get errorType;

  /// Returns the type `int`.
  SharedTypeView<TypeStructure> get intType;

  /// Returns the type `Never`.
  SharedTypeView<TypeStructure> get neverType;

  /// Returns the type `Null`.
  SharedTypeView<TypeStructure> get nullType;

  /// Returns the type `Object?`.
  SharedTypeView<TypeStructure> get objectQuestionType;

  /// Returns the type `Object`.
  SharedTypeView<TypeStructure> get objectType;

  /// Returns the unknown type schema (`_`) used in type inference.
  SharedTypeSchemaView<TypeStructure> get unknownType;

  /// Returns the type `Future` with omitted nullability and type argument
  /// [argumentType].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [futureTypeInternal] to
  /// receive a concrete implementation of [futureType] instead of implementing
  /// [futureType] directly.
  SharedTypeView<TypeStructure> futureType(
      SharedTypeView<TypeStructure> argumentType);

  /// [futureTypeInternal] should be implemented by concrete classes
  /// implementing [TypeAnalyzerOperations]. The implementations of [futureType]
  /// and [futureTypeSchema] are provided by mixing in
  /// [TypeAnalyzerOperationsMixin], which defines [futureType] and
  /// [futureTypeSchema] in terms of [futureTypeInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [futureTypeInternal], and receive
  /// the implementation of both [futureType] and [futureTypeSchema] from the
  /// mixin.
  ///
  /// The auxiliary purpose of [futureTypeInternal] is to facilitate the
  /// development of the shared code at early stages. Sometimes the sharing of
  /// the code starts by unifying the implementations of some concrete members
  /// in the Analyzer and the CFE by bringing them in a form that looks
  /// syntactically very similar in both tools, and then continues by
  /// abstracting the two concrete members and using the shared abstracted one
  /// instead of the two concrete methods existing previously. During the early
  /// stages of unifying the two concrete members it can be beneficial to use
  /// [futureTypeInternal] instead of the tool-specific ways of constructing a
  /// future type, for the sake of uniformity, and to simplify the abstraction
  /// step too.
  TypeStructure futureTypeInternal(TypeStructure typeStructure);

  /// Returns the type schema `Future` with omitted nullability and type
  /// argument [argumentTypeSchema].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [futureTypeInternal] to
  /// receive a concrete implementation of [futureTypeSchema] instead of
  /// implementing [futureTypeSchema] directly.
  SharedTypeSchemaView<TypeStructure> futureTypeSchema(
      SharedTypeSchemaView<TypeStructure> argumentTypeSchema);

  /// If [type] was introduced by a class, mixin, enum, or extension type,
  /// returns a [TypeDeclarationKind] indicating what kind of thing it was
  /// introduced by. Otherwise, returns `null`.
  ///
  /// Examples of types derived from a class declarations are `A`, `A?`, `A*`,
  /// `B<T, S>`, where `A` and `B` are the names of class declarations or
  /// extension type declarations, `T` and `S` are types.
  TypeDeclarationKind? getTypeDeclarationKind(
      SharedTypeView<TypeStructure> type);

  TypeDeclarationKind? getTypeDeclarationKindInternal(TypeStructure type);

  /// Returns variance for of the type parameter at index [parameterIndex] in
  /// [typeDeclaration].
  Variance getTypeParameterVariance(
      TypeDeclaration typeDeclaration, int parameterIndex);

  /// If at top level [typeSchema] describes a type that was introduced by a
  /// class, mixin, enum, or extension type, returns a [TypeDeclarationKind]
  /// indicating what kind of thing it was introduced by. Otherwise, returns
  /// `null`.
  ///
  /// Examples of type schemas at top level describing types derived from a
  /// declaration are `A`, `A?`, `A*`, `B<T, S>`, `B<_, B<_, _>>?`, where `A`
  /// and `B` are class declarations or extension type declarations, `T` and
  /// `S` are type schemas.
  TypeDeclarationKind? getTypeSchemaDeclarationKind(
      SharedTypeSchemaView<TypeStructure> typeSchema);

  /// Computes the greatest lower bound of [type1] and [type2].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [glbInternal] to receive a
  /// concrete implementation of [glb] instead of implementing [glb] directly.
  SharedTypeView<TypeStructure> glb(
      SharedTypeView<TypeStructure> type1, SharedTypeView<TypeStructure> type2);

  /// [glbInternal] should be implemented by concrete classes implementing
  /// [TypeAnalyzerOperations]. The implementations of [glb] and [typeSchemaGlb]
  /// are provided by mixing in [TypeAnalyzerOperationsMixin], which defines
  /// [glb] and [typeSchemaGlb] in terms of [glbInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [glbInternal], and receive the
  /// implementation of both [glb] and [typeSchemaGlb] from the mixin.
  ///
  /// The auxiliary purpose of [glbInternal] is to facilitate the development of
  /// the shared code at early stages. Sometimes the sharing of the code starts
  /// by unifying the implementations of some concrete members in the Analyzer
  /// and the CFE by bringing them in a form that looks syntactically very
  /// similar in both tools, and then continues by abstracting the two concrete
  /// members and using the shared abstracted one instead of the two concrete
  /// methods existing previously. During the early stages of unifying the two
  /// concrete members it can be beneficial to use [glbInternal] instead of the
  /// tool-specific ways of constructing a future type, for the sake of
  /// uniformity, and to simplify the abstraction step too.
  TypeStructure glbInternal(TypeStructure type1, TypeStructure type2);

  /// Returns the greatest closure of [schema] with respect to the unknown type
  /// (`_`).
  SharedTypeView<TypeStructure> greatestClosure(
      SharedTypeSchemaView<TypeStructure> schema);

  /// Queries whether [type] is an "always-exhaustive" type (as defined in the
  /// patterns spec).  Exhaustive types are types for which the switch statement
  /// is required to be exhaustive when patterns support is enabled.
  bool isAlwaysExhaustiveType(SharedTypeView<TypeStructure> type);

  /// Returns `true` if [fromType] is assignable to [toType].
  bool isAssignableTo(SharedTypeView<TypeStructure> fromType,
      SharedTypeView<TypeStructure> toType);

  /// Returns `true` if [type] is `Function` from `dart:core`. The method
  /// returns `false` for `Function?` and `Function*`.
  bool isDartCoreFunctionInternal(TypeStructure type);

  /// Returns `true` if [type] is `Record` from `dart:core`. The method
  /// returns `false` for `Record?` and `Record*`.
  bool isDartCoreRecordInternal(TypeStructure type);

  /// Returns `true` if [type] is `E<T1, ..., Tn>`, `E<T1, ..., Tn>?`, or
  /// `E<T1, ..., Tn>*` for some extension type declaration E, some
  /// non-negative n, and some types T1, ..., Tn.
  bool isExtensionTypeInternal(TypeStructure type);

  /// Returns `true` if [type] is `A<T1, ..., Tn>`, `A<T1, ..., Tn>?`, or
  /// `A<T1, ..., Tn>*` for some class, mixin, or enum A, some non-negative n,
  /// and some types T1, ..., Tn. The method returns `false` if [type] is an
  /// extension type, a type alias, `Null`, `Never`, or `FutureOr<X>` for any
  /// type `X`.
  bool isInterfaceTypeInternal(TypeStructure type);

  @override
  bool isNever(SharedTypeView<TypeStructure> type);

  /// Returns `true` if `Null` is a subtype of all types matching [type].
  ///
  /// The predicate of [isNullableInternal] could be computed directly with a
  /// subtype query, but the implementations can do that more efficiently.
  bool isNullableInternal(TypeStructure type);

  /// Returns `true` if `Null` is not a subtype of all types matching [type].
  ///
  /// The predicate of [isNonNullableInternal] could be computed directly with
  /// a subtype query, but the implementations can do that more efficiently.
  bool isNonNullableInternal(TypeStructure type);

  /// Returns `true` if [type] is `Object` from `dart:core`. The method returns
  /// `false` for `Object?` and `Object*`.
  bool isObject(SharedTypeView<TypeStructure> type);

  /// The concrete classes implementing [TypeAnalyzerOperations] should
  /// implement [isSubtypeOfInternal] in order to receive the implementations of
  /// [typeIsSubtypeOfTypeSchema], [typeSchemaIsSubtypeOfType], and
  /// [typeSchemaIsSubtypeOfTypeSchema] by mixing in
  /// [TypeAnalyzerOperationsMixin].
  bool isSubtypeOfInternal(TypeStructure left, TypeStructure right);

  @override
  bool isTypeParameterType(SharedTypeView<TypeStructure> type);

  /// Returns `true` if the type [type] satisfies the type schema [typeSchema].
  bool isTypeSchemaSatisfied(
      {required SharedTypeSchemaView<TypeStructure> typeSchema,
      required SharedTypeView<TypeStructure> type});

  /// Returns whether [node] is final.
  bool isVariableFinal(Variable node);

  /// Returns the type schema `Iterable`, with type argument.
  SharedTypeSchemaView<TypeStructure> iterableTypeSchema(
      SharedTypeSchemaView<TypeStructure> elementTypeSchema);

  /// Returns the type `List`, with type argument [elementType].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [listTypeInternal] to receive
  /// a concrete implementation of [listType] instead of implementing [listType]
  /// directly.
  SharedTypeView<TypeStructure> listType(
      SharedTypeView<TypeStructure> elementType);

  /// [listTypeInternal] should be implemented by concrete classes implementing
  /// [TypeAnalyzerOperations]. The implementations of [listType] and
  /// [listTypeSchema] are provided by mixing in [TypeAnalyzerOperationsMixin],
  /// which defines [listType] and [listTypeSchema] in terms of
  /// [listTypeInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [listTypeInternal], and receive
  /// the implementation of both [listType] and [listTypeSchema] from the mixin.
  ///
  /// The auxiliary purpose of [listTypeInternal] is to facilitate the
  /// development of the shared code at early stages. Sometimes the sharing of
  /// the code starts by unifying the implementations of some concrete members
  /// in the Analyzer and the CFE by bringing them in a form that looks
  /// syntactically very similar in both tools, and then continues by
  /// abstracting the two concrete members and using the shared abstracted one
  /// instead of the two concrete methods existing previously. During the early
  /// stages of unifying the two concrete members it can be beneficial to use
  /// [listTypeInternal] instead of the tool-specific ways of constructing a
  /// future type, for the sake of uniformity, and to simplify the abstraction
  /// step too.
  TypeStructure listTypeInternal(TypeStructure elementType);

  /// Returns the type schema `List`, with type argument [elementTypeSchema].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [listTypeInternal] to receive
  /// a concrete implementation of [listTypeSchema] instead of implementing
  /// [listTypeSchema] directly.
  SharedTypeSchemaView<TypeStructure> listTypeSchema(
      SharedTypeSchemaView<TypeStructure> elementTypeSchema);

  /// Computes the least upper bound of [type1] and [type2].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [lubInternal] to receive a
  /// concrete implementation of [lub] instead of implementing [lub] directly.
  SharedTypeView<TypeStructure> lub(
      SharedTypeView<TypeStructure> type1, SharedTypeView<TypeStructure> type2);

  /// [lubInternal] should be implemented by concrete classes implementing
  /// [TypeAnalyzerOperations]. The implementations of [lub] and [typeSchemaLub]
  /// are provided by mixing in [TypeAnalyzerOperationsMixin], which defines
  /// [lub] and [typeSchemaLub] in terms of [lubInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [lubInternal], and receive the
  /// implementation of both [lub] and [typeSchemaLub] from the mixin.
  ///
  /// The auxiliary purpose of [lubInternal] is to facilitate the development of
  /// the shared code at early stages. Sometimes the sharing of the code starts
  /// by unifying the implementations of some concrete members in the Analyzer
  /// and the CFE by bringing them in a form that looks syntactically very
  /// similar in both tools, and then continues by abstracting the two concrete
  /// members and using the shared abstracted one instead of the two concrete
  /// methods existing previously. During the early stages of unifying the two
  /// concrete members it can be beneficial to use [lubInternal] instead of the
  /// tool-specific ways of constructing a future type, for the sake of
  /// uniformity, and to simplify the abstraction step too.
  TypeStructure lubInternal(TypeStructure type1, TypeStructure type2);

  /// [makeNullableInternal] should be implemented by concrete classes
  /// implementing [TypeAnalyzerOperations]. The implementations of
  /// [makeNullable] and [makeTypeSchemaNullable] are provided by mixing in
  /// [TypeAnalyzerOperationsMixin], which defines [makeNullable] and
  /// [makeTypeSchemaNullable] in terms of [makeNullableInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [makeNullableInternal], and
  /// receive the implementation of both [makeNullable] and
  /// [makeTypeSchemaNullable] from the mixin.
  ///
  /// The auxiliary purpose of [makeNullableInternal] is to facilitate the
  /// development of the shared code at early stages. Sometimes the sharing of
  /// the code starts by unifying the implementations of some concrete members
  /// in the Analyzer and the CFE by bringing them in a form that looks
  /// syntactically very similar in both tools, and then continues by
  /// abstracting the two concrete members and using the shared abstracted one
  /// instead of the two concrete methods existing previously. During the early
  /// stages of unifying the two concrete members it can be beneficial to use
  /// [makeNullableInternal] instead of the tool-specific ways of constructing a
  /// future type, for the sake of uniformity, and to simplify the abstraction
  /// step too.
  TypeStructure makeNullableInternal(TypeStructure type);

  /// Computes the nullable form of [typeSchema].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [makeNullableInternal] to
  /// receive a concrete implementation of [makeTypeSchemaNullable] instead of
  /// implementing [makeTypeSchemaNullable] directly.
  SharedTypeSchemaView<TypeStructure> makeTypeSchemaNullable(
      SharedTypeSchemaView<TypeStructure> typeSchema);

  /// Returns the type `Map`, with type arguments.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [mapTypeInternal] to receive a
  /// concrete implementation of [mapType] instead of implementing [mapType]
  /// directly.
  SharedTypeView<TypeStructure> mapType({
    required SharedTypeView<TypeStructure> keyType,
    required SharedTypeView<TypeStructure> valueType,
  });

  /// [mapTypeInternal] should be implemented by concrete classes implementing
  /// [TypeAnalyzerOperations]. The implementations of [mapType] and
  /// [makeTypeSchemaNullable] are provided by mixing in
  /// [TypeAnalyzerOperationsMixin], which defines [mapType] and
  /// [makeTypeSchemaNullable] in terms of [mapTypeInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [mapTypeInternal], and receive the
  /// implementation of both [mapType] and [makeTypeSchemaNullable] from the
  /// mixin.
  ///
  /// The auxiliary purpose of [mapTypeInternal] is to facilitate the
  /// development of the shared code at early stages. Sometimes the sharing of
  /// the code starts by unifying the implementations of some concrete members
  /// in the Analyzer and the CFE by bringing them in a form that looks
  /// syntactically very similar in both tools, and then continues by
  /// abstracting the two concrete members and using the shared abstracted one
  /// instead of the two concrete methods existing previously. During the early
  /// stages of unifying the two concrete members it can be beneficial to use
  /// [mapTypeInternal] instead of the tool-specific ways of constructing a
  /// future type, for the sake of uniformity, and to simplify the abstraction
  /// step too.
  TypeStructure mapTypeInternal({
    required TypeStructure keyType,
    required TypeStructure valueType,
  });

  /// Returns the type schema `Map`, with type arguments [keyTypeSchema] and
  /// [valueTypeSchema].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [mapTypeInternal] to receive a
  /// concrete implementation of [makeTypeSchemaNullable] instead of
  /// implementing [makeTypeSchemaNullable] directly.
  SharedTypeSchemaView<TypeStructure> mapTypeSchema({
    required SharedTypeSchemaView<TypeStructure> keyTypeSchema,
    required SharedTypeSchemaView<TypeStructure> valueTypeSchema,
  });

  /// If [type] takes the form `FutureOr<T>`, `FutureOr<T>?`, or `FutureOr<T>*`
  /// for some `T`, returns the type `T`. Otherwise returns `null`.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [matchFutureOrInternal] to
  /// receive a concrete implementation of [matchFutureOr] instead of
  /// implementing [matchFutureOr] directly.
  SharedTypeView<TypeStructure>? matchFutureOr(
      SharedTypeView<TypeStructure> type);

  /// [matchFutureOrInternal] should be implemented by concrete classes
  /// implementing [TypeAnalyzerOperations]. The implementations of
  /// [matchFutureOr] and [matchTypeSchemaFutureOr] are provided by mixing in
  /// [TypeAnalyzerOperationsMixin], which defines [matchFutureOr] and
  /// [matchTypeSchemaFutureOr] in terms of [matchFutureOrInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [matchFutureOrInternal], and
  /// receive the implementation of both [matchFutureOr] and
  /// [matchTypeSchemaFutureOr] from the mixin.
  ///
  /// The auxiliary purpose of [matchFutureOrInternal] is to facilitate the
  /// development of the shared code at early stages. Sometimes the sharing of
  /// the code starts by unifying the implementations of some concrete members
  /// in the Analyzer and the CFE by bringing them in a form that looks
  /// syntactically very similar in both tools, and then continues by
  /// abstracting the two concrete members and using the shared abstracted one
  /// instead of the two concrete methods existing previously. During the early
  /// stages of unifying the two concrete members it can be beneficial to use
  /// [matchFutureOrInternal] instead of the tool-specific ways of constructing
  /// a future type, for the sake of uniformity, and to simplify the abstraction
  /// step too.
  TypeStructure? matchFutureOrInternal(TypeStructure type);

  /// If [type] is a parameter type with empty nullability suffix, returns its
  /// bound, whether it is its type parameter bound or its promoted bound.
  /// Otherwise, returns null.
  ///
  /// In the example below matching the appearance of `X` in the parameters of
  /// `foo` returns `num`, matching the appearance of `Y` in the parameters of
  /// the function type `int Function<Y extends Object>(Y)` returns `Object`,
  /// and matching the inferred type of the variable `z`, which is `X & int`,
  /// `X` promoted to `int`, returns `int`. Matching a non-type parameter type,
  /// such as `int`, would return null.
  ///
  ///   int foo<X extends num>(int Function<Y extends Object>(Y) f, X x) {
  ///     if (x is int) {
  ///       var z = x;
  ///       return z;
  ///     } else {
  ///       return f(x);
  ///     }
  ///   }
  TypeStructure? matchTypeParameterBoundInternal(TypeStructure type);

  /// If [type] is a parameter type that is of a kind used in type inference,
  /// returns the corresponding parameter.
  ///
  /// In the example below the appearance of `X` in the return type of `foo` is
  /// a parameter type of a kind used in type inference. When passed into
  /// [matchInferableParameterInternal] it will yield the parameter `X` defined
  /// by `foo`.
  ///
  ///   X foo<X>(bool c, X x1, X x2) => c ? x1 : x2;
  TypeParameterStructure? matchInferableParameterInternal(TypeStructure type);

  /// If [type] is a subtype of the type `Iterable<T>?` for some `T`, returns
  /// the type `T`.  Otherwise returns `null`.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [matchIterableTypeInternal] to
  /// receive a concrete implementation of [matchIterableType] instead of
  /// implementing [matchIterableType] directly.
  SharedTypeView<TypeStructure>? matchIterableType(
      SharedTypeView<TypeStructure> type);

  /// [matchIterableTypeInternal] should be implemented by concrete classes
  /// implementing [TypeAnalyzerOperations]. The implementations of
  /// [matchIterableType] and [matchIterableTypeSchema] are provided by mixing
  /// in [TypeAnalyzerOperationsMixin], which defines [matchIterableType] and
  /// [matchIterableTypeSchema] in terms of [matchIterableTypeInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [matchIterableTypeInternal], and
  /// receive the implementation of both [matchIterableType] and
  /// [matchIterableTypeSchema] from the mixin.
  ///
  /// The auxiliary purpose of [matchIterableTypeInternal] is to facilitate the
  /// development of the shared code at early stages. Sometimes the sharing of
  /// the code starts by unifying the implementations of some concrete members
  /// in the Analyzer and the CFE by bringing them in a form that looks
  /// syntactically very similar in both tools, and then continues by
  /// abstracting the two concrete members and using the shared abstracted one
  /// instead of the two concrete methods existing previously. During the early
  /// stages of unifying the two concrete members it can be beneficial to use
  /// [matchIterableTypeInternal] instead of the tool-specific ways of
  /// constructing a future type, for the sake of uniformity, and to simplify
  /// the abstraction step too.
  TypeStructure? matchIterableTypeInternal(TypeStructure type);

  /// If [typeSchema] is the type schema `Iterable<T>?` (or a subtype thereof),
  /// for some `T`, returns the type `T`. Otherwise returns `null`.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [matchIterableTypeInternal] to
  /// receive a concrete implementation of [matchIterableTypeSchema] instead of
  /// implementing [matchIterableTypeSchema] directly.
  SharedTypeSchemaView<TypeStructure>? matchIterableTypeSchema(
      SharedTypeSchemaView<TypeStructure> typeSchema);

  /// If [type] is a subtype of the type `List<T>?` for some `T`, returns the
  /// type `T`.  Otherwise returns `null`.
  SharedTypeView<TypeStructure>? matchListType(
      SharedTypeView<TypeStructure> type);

  /// If [type] is a subtype of the type `Map<K, V>?` for some `K` and `V`,
  /// returns these `K` and `V`.  Otherwise returns `null`.
  ({
    SharedTypeView<TypeStructure> keyType,
    SharedTypeView<TypeStructure> valueType
  })? matchMapType(SharedTypeView<TypeStructure> type);

  /// If [type] is a subtype of the type `Stream<T>?` for some `T`, returns
  /// the type `T`.  Otherwise returns `null`.
  SharedTypeView<TypeStructure>? matchStreamType(
      SharedTypeView<TypeStructure> type);

  /// If [type] was introduced by a class, mixin, enum, or extension type,
  /// returns an object of [TypeDeclarationMatchResult] describing the
  /// constituents of the matched type.
  ///
  /// If [type] isn't introduced by a class, mixin, enum, or extension type,
  /// returns null.
  TypeDeclarationMatchResult<TypeDeclarationType, TypeDeclaration,
      TypeStructure>? matchTypeDeclarationTypeInternal(TypeStructure type);

  /// If [typeSchema] takes the form `FutureOr<T>`, `FutureOr<T>?`, or
  /// `FutureOr<T>*` for some `T`, returns the type schema `T`. Otherwise
  /// returns `null`.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [matchFutureOrInternal] to
  /// receive a concrete implementation of [matchTypeSchemaFutureOr] instead of
  /// implementing [matchTypeSchemaFutureOr] directly.
  SharedTypeSchemaView<TypeStructure>? matchTypeSchemaFutureOr(
      SharedTypeSchemaView<TypeStructure> typeSchema);

  /// Computes `NORM` of [type].
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/normalization.md`
  SharedTypeView<TypeStructure> normalize(SharedTypeView<TypeStructure> type);

  @override
  SharedTypeView<TypeStructure> promoteToNonNull(
      SharedTypeView<TypeStructure> type);

  /// Builds the client specific record type.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [recordTypeInternal] to
  /// receive a concrete implementation of [recordType] instead of implementing
  /// [recordType] directly.
  SharedTypeView<TypeStructure> recordType(
      {required List<SharedTypeView<TypeStructure>> positional,
      required List<(String, SharedTypeView<TypeStructure>)> named});

  /// [recordTypeInternal] should be implemented by concrete classes
  /// implementing [TypeAnalyzerOperations]. The implementations of [recordType]
  /// and [recordTypeSchema] are provided by mixing in
  /// [TypeAnalyzerOperationsMixin], which defines [recordType] and
  /// [recordTypeSchema] in terms of [recordTypeInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case [recordTypeInternal], and receive
  /// the implementation of both [recordType] and [recordTypeSchema] from the
  /// mixin.
  ///
  /// The auxiliary purpose of [recordTypeInternal] is to facilitate the
  /// development of the shared code at early stages. Sometimes the sharing of
  /// the code starts by unifying the implementations of some concrete members
  /// in the Analyzer and the CFE by bringing them in a form that looks
  /// syntactically very similar in both tools, and then continues by
  /// abstracting the two concrete members and using the shared abstracted one
  /// instead of the two concrete methods existing previously. During the early
  /// stages of unifying the two concrete members it can be beneficial to use
  /// [recordTypeInternal] instead of the tool-specific ways of constructing a
  /// future type, for the sake of uniformity, and to simplify the abstraction
  /// step too.
  TypeStructure recordTypeInternal(
      {required List<TypeStructure> positional,
      required List<(String, TypeStructure)> named});

  /// Builds the client specific record type schema.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [recordTypeInternal] to
  /// receive a concrete implementation of [recordTypeSchema] instead of
  /// implementing [recordTypeSchema] directly.
  SharedTypeSchemaView<TypeStructure> recordTypeSchema(
      {required List<SharedTypeSchemaView<TypeStructure>> positional,
      required List<(String, SharedTypeSchemaView<TypeStructure>)> named});

  /// Returns the type schema `Stream`, with type argument [elementTypeSchema].
  SharedTypeSchemaView<TypeStructure> streamTypeSchema(
      SharedTypeSchemaView<TypeStructure> elementTypeSchema);

  @override
  SharedTypeView<TypeStructure>? tryPromoteToType(
      SharedTypeView<TypeStructure> to, SharedTypeView<TypeStructure> from);

  /// Returns `true` if [leftType] is a subtype of the greatest closure of
  /// [rightSchema].
  ///
  /// This method can be implemented directly, by computing the greatest
  /// closure of [rightSchema] and then comparing the resulting type and
  /// [leftType] via [isSubtypeOf]. However, that would mean at least two
  /// recursive descends over types. This method is supposed to have optimized
  /// implementations that only use one recursive descend.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should
  /// implement [isSubtypeOfInternal] and mix in [TypeAnalyzerOperationsMixin]
  /// to receive an implementation of [typeIsSubtypeOfTypeSchema] instead of
  /// implementing it directly.
  bool typeIsSubtypeOfTypeSchema(SharedTypeView<TypeStructure> leftType,
      SharedTypeSchemaView<TypeStructure> rightSchema);

  /// Computes the greatest lower bound of [typeSchema1] and [typeSchema2].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [glbInternal] to receive a
  /// concrete implementation of [typeSchemaGlb] instead of implementing
  /// [typeSchemaGlb] directly.
  SharedTypeSchemaView<TypeStructure> typeSchemaGlb(
      SharedTypeSchemaView<TypeStructure> typeSchema1,
      SharedTypeSchemaView<TypeStructure> typeSchema2);

  /// Returns `true` if the least closure of [leftSchema] is a subtype of
  /// [rightType].
  ///
  /// This method can be implemented directly, by computing the least closure
  /// of [leftSchema] and then comparing the resulting type and [rightType] via
  /// [isSubtypeOf]. However, that would mean at least two recursive descends
  /// over types. This method is supposed to have optimized implementations
  /// that only use one recursive descend.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should
  /// implement [isSubtypeOfInternal] and mix in [TypeAnalyzerOperationsMixin]
  /// to receive an implementation of [typeSchemaIsSubtypeOfType] instead of
  /// implementing it directly.
  bool typeSchemaIsSubtypeOfType(SharedTypeSchemaView<TypeStructure> leftSchema,
      SharedTypeView<TypeStructure> rightType);

  /// Returns `true` if least closure of [leftSchema] is a subtype of
  /// the greatest closure of [rightSchema].
  ///
  /// This method can be implemented directly, by computing the least closure of
  /// [leftSchema], the greatest closure of [rightSchema], and then comparing
  /// the resulting types via [isSubtypeOf]. However, that would mean at least
  /// three recursive descends over types. This method is supposed to have
  /// optimized implementations that only use one recursive descend.
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should
  /// implement [isSubtypeOfInternal] and mix in [TypeAnalyzerOperationsMixin]
  /// to receive an implementation of [typeSchemaIsSubtypeOfTypeSchema] instead
  /// of implementing it directly.
  bool typeSchemaIsSubtypeOfTypeSchema(
      SharedTypeSchemaView<TypeStructure> leftSchema,
      SharedTypeSchemaView<TypeStructure> rightSchema);

  /// Computes the least upper bound of [typeSchema1] and [typeSchema2].
  ///
  /// The concrete classes implementing [TypeAnalyzerOperations] should mix in
  /// [TypeAnalyzerOperationsMixin] and implement [lubInternal] to receive a
  /// concrete implementation of [typeSchemaLub] instead of implementing
  /// [typeSchemaLub] directly.
  SharedTypeSchemaView<TypeStructure> typeSchemaLub(
      SharedTypeSchemaView<TypeStructure> typeSchema1,
      SharedTypeSchemaView<TypeStructure> typeSchema2);

  /// Computes the greatest closure of a type.
  ///
  /// Computing the greatest closure of a type is described here:
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#type-variable-elimination-least-and-greatest-closure-of-a-type
  TypeStructure greatestClosureOfTypeInternal(
      TypeStructure type,
      List<SharedTypeParameterStructure<TypeStructure>>
          typeParametersToEliminate);

  /// Computes the least closure of a type.
  ///
  /// Computing the greatest closure of a type is described here:
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#type-variable-elimination-least-and-greatest-closure-of-a-type
  TypeStructure leastClosureOfTypeInternal(
      TypeStructure type,
      List<SharedTypeParameterStructure<TypeStructure>>
          typeParametersToEliminate);

  /// Converts a type into a corresponding type schema.
  SharedTypeSchemaView<TypeStructure> typeToSchema(
      SharedTypeView<TypeStructure> type);

  /// Returns [type] suffixed with the [suffix].
  TypeStructure withNullabilitySuffixInternal(
      TypeStructure type, NullabilitySuffix suffix);
}

mixin TypeAnalyzerOperationsMixin<
        TypeStructure extends SharedTypeStructure<TypeStructure>,
        Variable extends Object,
        // Work around https://github.com/dart-lang/dart_style/issues/1568
        // ignore: lines_longer_than_80_chars
        TypeParameterStructure extends SharedTypeParameterStructure<TypeStructure>,
        TypeDeclarationType extends Object,
        TypeDeclaration extends Object>
    implements
        TypeAnalyzerOperations<TypeStructure, Variable, TypeParameterStructure,
            TypeDeclarationType, TypeDeclaration> {
  @override
  SharedTypeView<TypeStructure> futureType(
      SharedTypeView<TypeStructure> argumentType) {
    return new SharedTypeView(
        futureTypeInternal(argumentType.unwrapTypeView()));
  }

  @override
  SharedTypeSchemaView<TypeStructure> futureTypeSchema(
      SharedTypeSchemaView<TypeStructure> argumentTypeSchema) {
    return new SharedTypeSchemaView(
        futureTypeInternal(argumentTypeSchema.unwrapTypeSchemaView()));
  }

  @override
  TypeDeclarationKind? getTypeDeclarationKind(
      SharedTypeView<TypeStructure> type) {
    return getTypeDeclarationKindInternal(type.unwrapTypeView());
  }

  @override
  TypeDeclarationKind? getTypeSchemaDeclarationKind(
      SharedTypeSchemaView<TypeStructure> typeSchema) {
    return getTypeDeclarationKindInternal(typeSchema.unwrapTypeSchemaView());
  }

  @override
  SharedTypeView<TypeStructure> glb(SharedTypeView<TypeStructure> type1,
      SharedTypeView<TypeStructure> type2) {
    return new SharedTypeView(
        glbInternal(type1.unwrapTypeView(), type2.unwrapTypeView()));
  }

  @override
  bool isSubtypeOf(SharedTypeView<TypeStructure> leftType,
      SharedTypeView<TypeStructure> rightType) {
    return isSubtypeOfInternal(
        leftType.unwrapTypeView(), rightType.unwrapTypeView());
  }

  @override
  SharedTypeView<TypeStructure> listType(
      SharedTypeView<TypeStructure> elementType) {
    return new SharedTypeView(listTypeInternal(elementType.unwrapTypeView()));
  }

  @override
  SharedTypeSchemaView<TypeStructure> listTypeSchema(
      SharedTypeSchemaView<TypeStructure> elementTypeSchema) {
    return new SharedTypeSchemaView(
        listTypeInternal(elementTypeSchema.unwrapTypeSchemaView()));
  }

  @override
  SharedTypeView<TypeStructure> lub(SharedTypeView<TypeStructure> type1,
      SharedTypeView<TypeStructure> type2) {
    return new SharedTypeView(
        lubInternal(type1.unwrapTypeView(), type2.unwrapTypeView()));
  }

  @override
  SharedTypeView<TypeStructure> makeNullable(
      SharedTypeView<TypeStructure> type) {
    return new SharedTypeView(makeNullableInternal(type.unwrapTypeView()));
  }

  @override
  SharedTypeSchemaView<TypeStructure> makeTypeSchemaNullable(
      SharedTypeSchemaView<TypeStructure> typeSchema) {
    return new SharedTypeSchemaView(
        makeNullableInternal(typeSchema.unwrapTypeSchemaView()));
  }

  @override
  SharedTypeView<TypeStructure> mapType({
    required SharedTypeView<TypeStructure> keyType,
    required SharedTypeView<TypeStructure> valueType,
  }) {
    return new SharedTypeView(mapTypeInternal(
        keyType: keyType.unwrapTypeView(),
        valueType: valueType.unwrapTypeView()));
  }

  @override
  SharedTypeSchemaView<TypeStructure> mapTypeSchema(
      {required SharedTypeSchemaView<TypeStructure> keyTypeSchema,
      required SharedTypeSchemaView<TypeStructure> valueTypeSchema}) {
    return new SharedTypeSchemaView(mapTypeInternal(
        keyType: keyTypeSchema.unwrapTypeSchemaView(),
        valueType: valueTypeSchema.unwrapTypeSchemaView()));
  }

  @override
  SharedTypeView<TypeStructure>? matchFutureOr(
      SharedTypeView<TypeStructure> type) {
    return matchFutureOrInternal(type.unwrapTypeView())?.wrapSharedTypeView();
  }

  @override
  SharedTypeView<TypeStructure>? matchIterableType(
      SharedTypeView<TypeStructure> type) {
    return matchIterableTypeInternal(type.unwrapTypeView())
        ?.wrapSharedTypeView();
  }

  @override
  SharedTypeSchemaView<TypeStructure>? matchIterableTypeSchema(
      SharedTypeSchemaView<TypeStructure> typeSchema) {
    return matchIterableTypeInternal(typeSchema.unwrapTypeSchemaView())
        ?.wrapSharedTypeSchemaView();
  }

  @override
  SharedTypeSchemaView<TypeStructure>? matchTypeSchemaFutureOr(
      SharedTypeSchemaView<TypeStructure> typeSchema) {
    return matchFutureOrInternal(typeSchema.unwrapTypeSchemaView())
        ?.wrapSharedTypeSchemaView();
  }

  @override
  SharedTypeView<TypeStructure> recordType(
      {required List<SharedTypeView<TypeStructure>> positional,
      required List<(String, SharedTypeView<TypeStructure>)> named}) {
    return new SharedTypeView(recordTypeInternal(
        positional: positional.cast<TypeStructure>(),
        named: named.cast<(String, TypeStructure)>()));
  }

  @override
  SharedTypeSchemaView<TypeStructure> recordTypeSchema(
      {required List<SharedTypeSchemaView<TypeStructure>> positional,
      required List<(String, SharedTypeSchemaView<TypeStructure>)> named}) {
    return new SharedTypeSchemaView(recordTypeInternal(
        positional: positional.cast<TypeStructure>(),
        named: named.cast<(String, TypeStructure)>()));
  }

  @override
  bool typeIsSubtypeOfTypeSchema(SharedTypeView<TypeStructure> leftType,
      SharedTypeSchemaView<TypeStructure> rightSchema) {
    return isSubtypeOfInternal(
        leftType.unwrapTypeView(), rightSchema.unwrapTypeSchemaView());
  }

  @override
  SharedTypeSchemaView<TypeStructure> typeSchemaGlb(
      SharedTypeSchemaView<TypeStructure> typeSchema1,
      SharedTypeSchemaView<TypeStructure> typeSchema2) {
    return new SharedTypeSchemaView(glbInternal(
        typeSchema1.unwrapTypeSchemaView(),
        typeSchema2.unwrapTypeSchemaView()));
  }

  @override
  bool typeSchemaIsSubtypeOfType(SharedTypeSchemaView<TypeStructure> leftSchema,
      SharedTypeView<TypeStructure> rightType) {
    return isSubtypeOfInternal(
        leftSchema.unwrapTypeSchemaView(), rightType.unwrapTypeView());
  }

  @override
  bool typeSchemaIsSubtypeOfTypeSchema(
      SharedTypeSchemaView<TypeStructure> leftSchema,
      SharedTypeSchemaView<TypeStructure> rightSchema) {
    return isSubtypeOfInternal(
        leftSchema.unwrapTypeSchemaView(), rightSchema.unwrapTypeSchemaView());
  }

  @override
  SharedTypeSchemaView<TypeStructure> typeSchemaLub(
      SharedTypeSchemaView<TypeStructure> typeSchema1,
      SharedTypeSchemaView<TypeStructure> typeSchema2) {
    return new SharedTypeSchemaView(lubInternal(
        typeSchema1.unwrapTypeSchemaView(),
        typeSchema2.unwrapTypeSchemaView()));
  }

  @override
  SharedTypeSchemaView<TypeStructure> typeToSchema(
      SharedTypeView<TypeStructure> type) {
    return new SharedTypeSchemaView(type.unwrapTypeView());
  }
}

/// Abstract interface of a type constraint generator.
abstract class TypeConstraintGenerator<
    TypeStructure extends SharedTypeStructure<TypeStructure>,
    FunctionParameterStructure extends SharedNamedFunctionParameterStructure<
        TypeStructure>,
    Variable extends Object,
    TypeParameterStructure extends SharedTypeParameterStructure<TypeStructure>,
    TypeDeclarationType extends Object,
    TypeDeclaration extends Object,
    AstNode extends Object> {
  /// The current sate of the constraint generator.
  ///
  /// The states of the generator obtained via [currentState] can be treated as
  /// checkpoints in the constraint generation process, and the generator can
  /// be rolled back to a state via [restoreState].
  TypeConstraintGeneratorState get currentState;

  /// True if FutureOr types are required to have the empty [NullabilitySuffix]
  /// when they are matched.
  ///
  /// For more information about the discrepancy between the Analyzer and the
  /// CFE in treatment of FutureOr types, see
  /// https://github.com/dart-lang/sdk/issues/55344 and
  /// https://github.com/dart-lang/sdk/issues/51156#issuecomment-2158825417.
  bool get enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr;

  /// True if the language feature inference-using-bounds is enabled.
  final bool inferenceUsingBoundsIsEnabled;

  /// Abstract type operations to be used in the matching methods.
  TypeAnalyzerOperations<TypeStructure, Variable, TypeParameterStructure,
      TypeDeclarationType, TypeDeclaration> get typeAnalyzerOperations;

  TypeConstraintGenerator({required this.inferenceUsingBoundsIsEnabled});

  /// Add constraint: [lower] <: [typeParameter] <: TOP.
  void addLowerConstraintForParameter(
      TypeParameterStructure typeParameter, TypeStructure lower,
      {required AstNode? astNodeForTesting});

  /// Add constraint: BOTTOM <: [typeParameter] <: [upper].
  void addUpperConstraintForParameter(
      TypeParameterStructure typeParameter, TypeStructure upper,
      {required AstNode? astNodeForTesting});

  /// Returns the type arguments of the supertype of [type] that is an
  /// instantiation of [typeDeclaration]. If none of the supertypes of [type]
  /// are instantiations of [typeDeclaration], returns null.
  List<TypeStructure>? getTypeArgumentsAsInstanceOf(
      TypeDeclarationType type, TypeDeclaration typeDeclaration);

  /// Matches [p] against [q].
  ///
  /// If [p] and [q] are both function types, and [p] is a subtype of [q] under
  /// some constraints, the constraints making the relation possible are
  /// recorded, and `true` is returned. Otherwise, the constraint state is
  /// unchanged (or rolled back using [restoreState]), and `false` is returned.
  ///
  /// An invariant of the type inference is that only [p] or [q] may be a
  /// schema (in other words, may contain the unknown type `_`); the other must
  /// be simply a type. If [leftSchema] is `true`, [p] may contain `_`; if it
  /// is `false`, [q] may contain `_`.
  bool performSubtypeConstraintGenerationForFunctionTypes(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    if (p is SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
            FunctionParameterStructure> &&
        q is SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
            FunctionParameterStructure>) {
      if (p.typeFormals.isEmpty && q.typeFormals.isEmpty) {
        return _handleNonGenericFunctionTypes(p, q,
            leftSchema: leftSchema, astNodeForTesting: astNodeForTesting);
      } else {
        return _handleGenericFunctionTypes(p, q,
            leftSchema: leftSchema, astNodeForTesting: astNodeForTesting);
      }
    }

    return false;
  }

  /// Matches non-generic function type [p] against non-generic function type
  /// [q].
  ///
  /// See the documentation on
  /// [performSubtypeConstraintGenerationForFunctionTypes] for details.
  bool _handleNonGenericFunctionTypes(
      SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
              FunctionParameterStructure>
          p,
      SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
              FunctionParameterStructure>
          q,
      {required bool leftSchema,
      required AstNode? astNodeForTesting}) {
    assert(p.typeFormals.isEmpty && q.typeFormals.isEmpty);
    // A function type (M0,..., Mn, [M{n+1}, ..., Mm]) -> R0 is a subtype
    // match for a function type (N0,..., Nk, [N{k+1}, ..., Nr]) -> R1 with
    // respect to L under constraints C0 + ... + Cr + C
    //
    // If R0 is a subtype match for a type R1 with respect to L under
    // constraints C.  If n <= k and r <= m.  And for i in 0...r, Ni is a
    // subtype match for Mi with respect to L under constraints Ci.
    if (p.sortedNamedParameters.isEmpty &&
        q.sortedNamedParameters.isEmpty &&
        p.requiredPositionalParameterCount <=
            q.requiredPositionalParameterCount &&
        p.positionalParameterTypes.length >=
            q.positionalParameterTypes.length) {
      final TypeConstraintGeneratorState state = currentState;

      if (!performSubtypeConstraintGenerationInternal(
          p.returnType, q.returnType,
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        return false;
      }
      for (int i = 0; i < q.positionalParameterTypes.length; ++i) {
        if (!performSubtypeConstraintGenerationInternal(
            q.positionalParameterTypes[i], p.positionalParameterTypes[i],
            leftSchema: !leftSchema, astNodeForTesting: astNodeForTesting)) {
          restoreState(state);
          return false;
        }
      }
      return true;
    } else if (p.positionalParameterTypes.length ==
            p.requiredPositionalParameterCount &&
        q.positionalParameterTypes.length ==
            q.requiredPositionalParameterCount &&
        p.requiredPositionalParameterCount ==
            q.requiredPositionalParameterCount &&
        p.sortedNamedParameters.isNotEmpty &&
        q.sortedNamedParameters.length <= p.sortedNamedParameters.length) {
      // Function types with named parameters are treated analogously to the
      // positional parameter case above.

      final TypeConstraintGeneratorState state = currentState;

      if (!performSubtypeConstraintGenerationInternal(
          p.returnType, q.returnType,
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        return false;
      }
      for (int i = 0; i < p.positionalParameterTypes.length; ++i) {
        if (!performSubtypeConstraintGenerationInternal(
            q.positionalParameterTypes[i], p.positionalParameterTypes[i],
            leftSchema: !leftSchema, astNodeForTesting: astNodeForTesting)) {
          restoreState(state);
          return false;
        }
      }
      // Consume parameter names from p and q in order. Since the named
      // parameters in p and q are already sorted by name, we can do this by
      // iterating through both lists in tandem.
      int i = 0;
      int j = 0;
      while (true) {
        // Determine whether the next parameter should be consumed from p,
        // q, or both (because the next set of names matches). If the next
        // parameter should be consumed from p, comparisonResult will be set
        // to a value < 0. If the next parameter should be consumed from q,
        // comparisonResult will be set to a value > 0. If the next
        // parameter should be consumed from both, comparisonResult will be
        // set to 0.
        int comparisonResult;
        if (i >= p.sortedNamedParameters.length) {
          if (j >= q.sortedNamedParameters.length) {
            // No parameters left.
            return true;
          } else {
            // No more parameters in p, so the next parameter must come from
            // q.
            comparisonResult = 1;
          }
        } else if (j >= q.sortedNamedParameters.length) {
          // No more parameters in q, so the next parameter must come from
          // p.
          comparisonResult = -1;
        } else {
          comparisonResult = p.sortedNamedParameters[i].name
              .compareTo(q.sortedNamedParameters[j].name);
        }
        if (comparisonResult > 0) {
          // Extra parameter in q that q that doesn't exist in p. No match.
          restoreState(state);
          return false;
        } else if (comparisonResult < 0) {
          // Extra parameter in p that doesn't exist in q. Ok if not
          // required.
          if (p.sortedNamedParameters[i].isRequired) {
            restoreState(state);
            return false;
          } else {
            i++;
          }
        } else {
          // The next parameter in p and q matches, so match their types.
          if (!performSubtypeConstraintGenerationInternal(
              q.sortedNamedParameters[j].type, p.sortedNamedParameters[i].type,
              leftSchema: !leftSchema, astNodeForTesting: astNodeForTesting)) {
            restoreState(state);
            return false;
          }
          i++;
          j++;
        }
      }
    }

    return false;
  }

  /// Matches generic function type [p] against generic function type [q].
  ///
  /// See the documentation on
  /// [performSubtypeConstraintGenerationForFunctionTypes] for details.
  bool _handleGenericFunctionTypes(
      SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
              FunctionParameterStructure>
          p,
      SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
              FunctionParameterStructure>
          q,
      {required bool leftSchema,
      required AstNode? astNodeForTesting}) {
    assert(p.typeFormals.isNotEmpty || q.typeFormals.isNotEmpty);
    // A generic function type <T0 extends B00, ..., Tn extends B0n>F0 is a
    // subtype match for a generic function type <S0 extends B10, ..., Sn
    // extends B1n>F1 with respect to L under constraint set C2
    //
    // If B0i is a subtype match for B1i with constraint set Ci0.  And B1i
    // is a subtype match for B0i with constraint set Ci1.  And Ci2 is Ci0
    // + Ci1.
    //
    // And Z0...Zn are fresh variables with bounds B20, ..., B2n, Where B2i
    // is B0i[Z0/T0, ..., Zn/Tn] if P is a type schema.  Or B2i is
    // B1i[Z0/S0, ..., Zn/Sn] if Q is a type schema.  In other words, we
    // choose the bounds for the fresh variables from whichever of the two
    // generic function types is a type schema and does not contain any
    // variables from L.
    //
    // And F0[Z0/T0, ..., Zn/Tn] is a subtype match for F1[Z0/S0, ...,
    // Zn/Sn] with respect to L under constraints C0.  And C1 is C02 + ...
    // + Cn2 + C0.  And C2 is C1 with each constraint replaced with its
    // closure with respect to [Z0, ..., Zn].
    if (p.typeFormals.length == q.typeFormals.length) {
      final TypeConstraintGeneratorState state = currentState;

      bool isMatch = true;
      for (int i = 0; isMatch && i < p.typeFormals.length; ++i) {
        isMatch = isMatch &&
            performSubtypeConstraintGenerationInternal(
                p.typeFormals[i].bound ??
                    typeAnalyzerOperations.objectQuestionType.unwrapTypeView(),
                q.typeFormals[i].bound ??
                    typeAnalyzerOperations.objectQuestionType.unwrapTypeView(),
                leftSchema: leftSchema,
                astNodeForTesting: astNodeForTesting) &&
            performSubtypeConstraintGenerationInternal(
                q.typeFormals[i].bound ??
                    typeAnalyzerOperations.objectQuestionType.unwrapTypeView(),
                p.typeFormals[i].bound ??
                    typeAnalyzerOperations.objectQuestionType.unwrapTypeView(),
                leftSchema: !leftSchema,
                astNodeForTesting: astNodeForTesting);
      }
      if (isMatch) {
        var (
          instantiatedP,
          instantiatedQ,
          typeParametersToEliminate: typeParametersToEliminate
        ) = instantiateFunctionTypesAndProvideFreshTypeParameters(p, q,
            leftSchema: leftSchema);

        if (performSubtypeConstraintGenerationInternal(
            instantiatedP, instantiatedQ,
            leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
          eliminateTypeParametersInGeneratedConstraints(
              typeParametersToEliminate, state,
              astNodeForTesting: astNodeForTesting);
          return true;
        }
      }
      restoreState(state);
    }

    return false;
  }

  /// Matches [p] against [q], where [p] and [q] are both record types.
  ///
  /// If [p] is a subtype of [q] under some constraints, the constraints making
  /// the relation possible are recorded, and `true` is returned. Otherwise,
  /// the constraint state is unchanged (or rolled back), and `false` is
  /// returned.
  bool performSubtypeConstraintGenerationForRecordTypes(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    if (p is! SharedRecordTypeStructure<TypeStructure> ||
        q is! SharedRecordTypeStructure<TypeStructure>) {
      return false;
    }

    // A record type `(M0,..., Mk, {M{k+1} d{k+1}, ..., Mm dm])` is a subtype
    // match for a record type `(N0,..., Nk, {N{k+1} d{k+1}, ..., Nm dm])`
    // with respect to `L` under constraints `C0 + ... + Cm`
    // If for `i` in `0...m`, `Mi` is a subtype match for `Ni` with respect
    // to `L` under constraints `Ci`.
    if (p.positionalTypes.length != q.positionalTypes.length ||
        p.sortedNamedTypes.length != q.sortedNamedTypes.length) {
      return false;
    }

    final TypeConstraintGeneratorState state = currentState;

    for (int i = 0; i < p.positionalTypes.length; ++i) {
      if (!performSubtypeConstraintGenerationInternal(
          p.positionalTypes[i], q.positionalTypes[i],
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        restoreState(state);
        return false;
      }
    }

    // Since record types don't allow optional positional or named
    // parameters, and the named parameters are sorted, it's sufficient to
    // check that the named parameters at the same index have the same name
    // and matching types.
    for (int i = 0; i < p.sortedNamedTypes.length; ++i) {
      if (p.sortedNamedTypes[i].name != q.sortedNamedTypes[i].name ||
          !performSubtypeConstraintGenerationInternal(
              p.sortedNamedTypes[i].type, q.sortedNamedTypes[i].type,
              leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        restoreState(state);
        return false;
      }
    }

    return true;
  }

  /// Creates fresh type parameters, instantiates the non-generic parts of [p]
  /// and [q] with the new parameters as type arguments, and returns the
  /// instantiated non-generic function types and the eliminator that
  /// eliminates the new type parameters.
  ///
  /// This operation is required as a part of the subtype constraint generation
  /// algorithm, in the step for the generic function types.  See
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#subtype-constraint-generation.
  (
    TypeStructure,
    TypeStructure, {
    List<TypeParameterStructure> typeParametersToEliminate
  }) instantiateFunctionTypesAndProvideFreshTypeParameters(
      SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
              FunctionParameterStructure>
          p,
      SharedFunctionTypeStructure<TypeStructure, TypeParameterStructure,
              FunctionParameterStructure>
          q,
      {required bool leftSchema});

  /// Iterates over all of the type constraints generated since
  /// [eliminationStartState] and eliminates the type variables in them using
  /// [typeParametersToEliminate].
  ///
  /// This step is required as a part of the subtype constraint generation
  /// algorithm, in the step for generic function types. See
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#subtype-constraint-generation.
  void eliminateTypeParametersInGeneratedConstraints(
      List<TypeParameterStructure> typeParametersToEliminate,
      TypeConstraintGeneratorState eliminationStartState,
      {required AstNode? astNodeForTesting});

  /// Matches [p] against [q].
  ///
  /// If [q] is of the form `FutureOr<q0>` for some `q0`, and [p] is a subtype
  /// of [q] under some constraints, the constraints making the relation
  /// possible are recorded, and `true` is returned. Otherwise, the constraint
  /// state is unchanged (or rolled back using [restoreState]), and `false` is
  /// returned.
  ///
  /// An invariant of the type inference is that only [p] or [q] may be a
  /// schema (in other words, may contain the unknown type `_`); the other must
  /// be simply a type. If [leftSchema] is `true`, [p] may contain `_`; if it is
  /// `false`, [q] may contain `_`.
  bool performSubtypeConstraintGenerationForRightFutureOr(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    // If `Q` is `FutureOr<Q0>` the match holds under constraint set `C`:
    if (typeAnalyzerOperations.matchFutureOrInternal(q) case TypeStructure q0?
        when enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr ||
            q.nullabilitySuffix == NullabilitySuffix.none) {
      final TypeConstraintGeneratorState state = currentState;

      // If `P` is `FutureOr<P0>` and `P0` is a subtype match for `Q0` under
      // constraint set `C`.
      if (typeAnalyzerOperations.matchFutureOrInternal(p) case TypeStructure p0?
          when enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr ||
              p.nullabilitySuffix == NullabilitySuffix.none) {
        if (performSubtypeConstraintGenerationInternal(p0, q0,
            leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
          return true;
        }
      }

      // Or if `P` is a subtype match for `Future<Q0>` under non-empty
      // constraint set `C`.
      bool isMatchWithFuture = performSubtypeConstraintGenerationInternal(
          p, typeAnalyzerOperations.futureTypeInternal(q0),
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting);
      bool matchWithFutureAddsConstraints = currentState != state;
      if (isMatchWithFuture && matchWithFutureAddsConstraints) {
        return true;
      }

      // Or if `P` is a subtype match for `Q0` under constraint set `C`.
      if (performSubtypeConstraintGenerationInternal(p, q0,
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        return true;
      }

      // Or if `P` is a subtype match for `Future<Q0>` under empty
      // constraint set `C`.
      if (isMatchWithFuture && !matchWithFutureAddsConstraints) {
        return true;
      }
    }

    return false;
  }

  /// Matches [p] against [q].
  ///
  /// If [p] is of the form `FutureOr<p0>` for some `p0`, and [p] is a subtype
  /// of [q] under some constraints, the constraints making the relation
  /// possible are recorded, and `true` is returned. Otherwise, the constraint
  /// state is unchanged (or rolled back using [restoreState]), and `false` is
  /// returned.
  ///
  /// An invariant of the type inference is that only [p] or [q] may be a
  /// schema (in other words, may contain the unknown type `_`); the other must
  /// be simply a type. If [leftSchema] is `true`, [p] may contain `_`; if it is
  /// `false`, [q] may contain `_`.
  bool performSubtypeConstraintGenerationForLeftFutureOr(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    // If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
    NullabilitySuffix pNullability = p.nullabilitySuffix;
    if (typeAnalyzerOperations.matchFutureOrInternal(p) case var p0?
        when pNullability == NullabilitySuffix.none) {
      final TypeConstraintGeneratorState state = currentState;

      // If `Future<P0>` is a subtype match for `Q` under constraint set `C1`.
      // And if `P0` is a subtype match for `Q` under constraint set `C2`.
      TypeStructure futureP0 = typeAnalyzerOperations.futureTypeInternal(p0);
      if (performSubtypeConstraintGenerationInternal(futureP0, q,
              leftSchema: leftSchema, astNodeForTesting: astNodeForTesting) &&
          performSubtypeConstraintGenerationInternal(p0, q,
              leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        return true;
      }

      restoreState(state);
    }

    return false;
  }

  /// Matches [p] against [q] as a subtype against supertype.
  ///
  /// If [p] and [q] are both type declaration types, then:
  ///
  /// - If [p] is a subtype of [q] under some constraints, the constraints
  ///   making the relation possible are recorded, and `true` is returned.
  /// - Otherwise, the constraint state is unchanged (or rolled back using
  ///   [restoreState]), and `false` is returned.
  ///
  /// Otherwise (either [p] or [q] is not a type declaration type), the
  /// constraint state is unchanged, and `null` is returned.
  ///
  /// An invariant of the type inference is that only [p] or [q] may be a
  /// schema (in other words, may contain the unknown type `_`); the other must
  /// be simply a type. If [leftSchema] is `true`, [p] may contain `_`; if it is
  /// `false`, [q] may contain `_`.
  bool? performSubtypeConstraintGenerationForTypeDeclarationTypes(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    switch ((
      typeAnalyzerOperations.matchTypeDeclarationTypeInternal(p),
      typeAnalyzerOperations.matchTypeDeclarationTypeInternal(q)
    )) {
      // If `P` is `C<M0, ..., Mk> and `Q` is `C<N0, ..., Nk>`, then the match
      // holds under constraints `C0 + ... + Ck`:
      //   If `Mi` is a subtype match for `Ni` with respect to L under
      //   constraints `Ci`.
      case (
            TypeDeclarationMatchResult(
              typeDeclarationKind: TypeDeclarationKind pTypeDeclarationKind,
              typeDeclaration: TypeDeclaration pDeclarationObject,
              typeArguments: List<TypeStructure> pTypeArguments
            ),
            TypeDeclarationMatchResult(
              typeDeclarationKind: TypeDeclarationKind qTypeDeclarationKind,
              typeDeclaration: TypeDeclaration qDeclarationObject,
              typeArguments: List<TypeStructure> qTypeArguments
            )
          )
          when pTypeDeclarationKind == qTypeDeclarationKind &&
              pDeclarationObject == qDeclarationObject:
        return _interfaceTypeArguments(
            pDeclarationObject, pTypeArguments, qTypeArguments, leftSchema,
            astNodeForTesting: astNodeForTesting);

      case (TypeDeclarationMatchResult(), TypeDeclarationMatchResult()):
        return _interfaceTypes(p, q, leftSchema,
            astNodeForTesting: astNodeForTesting);

      case (
          TypeDeclarationMatchResult? pMatched,
          TypeDeclarationMatchResult? qMatched
        ):
        assert(pMatched == null || qMatched == null);
        return null;
    }
  }

  /// Matches [p] against [q] as a subtype against supertype.
  ///
  /// - If [p] is `p0?` for some `p0` and [p] is a subtype of [q] under some
  ///   constraints, the constraints making the relation possible are recorded,
  ///   and `true` is returned.
  /// - Otherwise, the constraint state is unchanged (or rolled back using
  ///   [restoreState]), and `false` is returned.
  ///
  /// An invariant of the type inference is that only [p] or [q] may be a
  /// schema (in other words, may contain the unknown type `_`); the other must
  /// be simply a type. If [leftSchema] is `true`, [p] may contain `_`; if it is
  /// `false`, [q] may contain `_`.
  bool performSubtypeConstraintGenerationForLeftNullableType(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    // If `P` is `P0?` the match holds under constraint set `C1 + C2`:
    NullabilitySuffix pNullability = p.nullabilitySuffix;
    if (pNullability == NullabilitySuffix.question) {
      TypeStructure p0 = typeAnalyzerOperations.withNullabilitySuffixInternal(
          p, NullabilitySuffix.none);
      final TypeConstraintGeneratorState state = currentState;

      // If `P0` is a subtype match for `Q` under constraint set `C1`.
      // And if `Null` is a subtype match for `Q` under constraint set `C2`.
      if (performSubtypeConstraintGenerationInternal(p0, q,
              leftSchema: leftSchema, astNodeForTesting: astNodeForTesting) &&
          performSubtypeConstraintGenerationInternal(
              typeAnalyzerOperations.nullType.unwrapTypeView(), q,
              leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        return true;
      }

      restoreState(state);
    }

    return false;
  }

  /// Matches [p] against [q] as a subtype against supertype.
  ///
  /// - If [q] is `q0?` for some `q0` and [p] is a subtype of [q] under some
  ///   constraints, the constraints making the relation possible are recorded,
  ///   and `true` is returned.
  /// - Otherwise, the constraint state is unchanged (or rolled back using
  ///   [restoreState]), and `false` is returned.
  ///
  /// An invariant of the type inference is that only [p] or [q] may be a
  /// schema (in other words, may contain the unknown type `_`); the other must
  /// be simply a type. If [leftSchema] is `true`, [p] may contain `_`; if it is
  /// `false`, [q] may contain `_`.
  bool performSubtypeConstraintGenerationForRightNullableType(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    // If `Q` is `Q0?` the match holds under constraint set `C`:
    NullabilitySuffix qNullability = q.nullabilitySuffix;
    if (qNullability == NullabilitySuffix.question) {
      TypeStructure q0 = typeAnalyzerOperations.withNullabilitySuffixInternal(
          q, NullabilitySuffix.none);
      final TypeConstraintGeneratorState state = currentState;

      // If `P` is `P0?` and `P0` is a subtype match for `Q0` under
      // constraint set `C`.
      NullabilitySuffix pNullability = p.nullabilitySuffix;
      if (pNullability == NullabilitySuffix.question) {
        TypeStructure p0 = typeAnalyzerOperations.withNullabilitySuffixInternal(
            p, NullabilitySuffix.none);
        if (performSubtypeConstraintGenerationInternal(p0, q0,
            leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
          return true;
        }
      }

      // Or if `P` is `dynamic` or `void` and `Object` is a subtype match
      // for `Q0` under constraint set `C`.
      if (p is SharedDynamicTypeStructure || p is SharedVoidTypeStructure) {
        if (performSubtypeConstraintGenerationInternal(
            typeAnalyzerOperations.objectType.unwrapTypeView(), q0,
            leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
          return true;
        }
      }

      // Or if `P` is a subtype match for `Q0` under non-empty
      // constraint set `C`.
      bool pMatchesQ0 = performSubtypeConstraintGenerationInternal(p, q0,
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting);
      if (pMatchesQ0 && state != currentState) {
        return true;
      }

      // Or if `P` is a subtype match for `Null` under constraint set `C`.
      if (performSubtypeConstraintGenerationInternal(
          p, typeAnalyzerOperations.nullType.unwrapTypeView(),
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        return true;
      }

      // Or if `P` is a subtype match for `Q0` under empty
      // constraint set `C`.
      if (pMatchesQ0) {
        return true;
      }
    }

    return false;
  }

  /// Type parameters being constrained by [TypeConstraintGenerator].
  Iterable<TypeParameterStructure> get typeParametersToConstrain;

  /// Implementation backing [performSubtypeConstraintGenerationLeftSchema] and
  /// [performSubtypeConstraintGenerationRightSchema].
  ///
  /// If [p] is a subtype of [q] under some constraints, the constraints making
  /// the relation possible are recorded, and `true` is returned. Otherwise,
  /// the constraint state is unchanged (or rolled back using [restoreState]),
  /// and `false` is returned.
  ///
  /// [performSubtypeConstraintGenerationInternal] should be implemented by
  /// concrete classes implementing [TypeConstraintGenerator]. The
  /// implementations of [performSubtypeConstraintGenerationLeftSchema] and
  /// [performSubtypeConstraintGenerationRightSchema] are provided by mixing in
  /// [TypeConstraintGeneratorMixin], which defines
  /// [performSubtypeConstraintGenerationLeftSchema] and
  /// [performSubtypeConstraintGenerationRightSchema] in terms of
  /// [performSubtypeConstraintGenerationInternal].
  ///
  /// The main purpose of this method is to avoid code duplication in the
  /// concrete classes implementing [TypeAnalyzerOperations], so they can
  /// implement only one member, in this case
  /// [performSubtypeConstraintGenerationInternal], and receive the
  /// implementation of both [performSubtypeConstraintGenerationLeftSchema] and
  /// [performSubtypeConstraintGenerationRightSchema] from the mixin.
  bool performSubtypeConstraintGenerationInternal(
      TypeStructure p, TypeStructure q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    // If `P` is `_` then the match holds with no constraints.
    if (p is SharedUnknownTypeStructure) {
      return true;
    }

    // If `Q` is `_` then the match holds with no constraints.
    if (q is SharedUnknownTypeStructure) {
      return true;
    }

    // If `P` is a type variable `X` in `L`, then the match holds:
    //   Under constraint `_ <: X <: Q`.
    NullabilitySuffix pNullability = p.nullabilitySuffix;
    if (typeAnalyzerOperations.matchInferableParameterInternal(p)
        case var pParameter?
        when pNullability == NullabilitySuffix.none &&
            typeParametersToConstrain.contains(pParameter)) {
      addUpperConstraintForParameter(pParameter, q,
          astNodeForTesting: astNodeForTesting);
      return true;
    }

    // If `Q` is a type variable `X` in `L`, then the match holds:
    //   Under constraint `P <: X <: _`.
    NullabilitySuffix qNullability = q.nullabilitySuffix;
    if (typeAnalyzerOperations.matchInferableParameterInternal(q)
        case var qParameter?
        when qNullability == NullabilitySuffix.none &&
            typeParametersToConstrain.contains(qParameter) &&
            (!inferenceUsingBoundsIsEnabled ||
                (qParameter.bound == null ||
                    typeAnalyzerOperations.isSubtypeOfInternal(
                        p,
                        typeAnalyzerOperations.greatestClosureOfTypeInternal(
                            qParameter.bound!,
                            [...typeParametersToConstrain]))))) {
      addLowerConstraintForParameter(qParameter, p,
          astNodeForTesting: astNodeForTesting);
      return true;
    }

    // If `P` and `Q` are identical types, then the subtype match holds
    // under no constraints.
    if (p == q) {
      return true;
    }

    // Note that it's not necessary to rewind [_constraints] to its prior state
    // in case [performSubtypeConstraintGenerationForFutureOr] returns false, as
    // [performSubtypeConstraintGenerationForFutureOr] handles the rewinding of
    // the state itself.
    if (performSubtypeConstraintGenerationForRightFutureOr(p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
      return true;
    }

    if (performSubtypeConstraintGenerationForRightNullableType(p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
      return true;
    }

    // If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
    if (performSubtypeConstraintGenerationForLeftFutureOr(p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
      return true;
    }

    // If `P` is `P0?` the match holds under constraint set `C1 + C2`:
    if (performSubtypeConstraintGenerationForLeftNullableType(p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
      return true;
    }

    // If `Q` is `dynamic`, `Object?`, or `void` then the match holds under
    // no constraints.
    if (q is SharedDynamicTypeStructure ||
        q is SharedVoidTypeStructure ||
        q == typeAnalyzerOperations.objectQuestionType.unwrapTypeView()) {
      return true;
    }

    // If `P` is `Never` then the match holds under no constraints.
    if (typeAnalyzerOperations.isNever(new SharedTypeView(p))) {
      return true;
    }

    // If `Q` is `Object`, then the match holds under no constraints:
    //  Only if `P` is non-nullable.
    if (q == typeAnalyzerOperations.objectType.unwrapTypeView()) {
      return typeAnalyzerOperations.isNonNullableInternal(p);
    }

    // If `P` is `Null`, then the match holds under no constraints:
    //  Only if `Q` is nullable.
    if (p is SharedNullTypeStructure) {
      return typeAnalyzerOperations.isNullableInternal(q);
    }

    // If `P` is a type variable `X` with bound `B` (or a promoted type
    // variable `X & B`), the match holds with constraint set `C`:
    //   If `B` is a subtype match for `Q` with constraint set `C`.
    // Note: we have already eliminated the case that `X` is a variable in `L`.
    if (typeAnalyzerOperations.matchTypeParameterBoundInternal(p)
        case var bound?) {
      if (performSubtypeConstraintGenerationInternal(bound, q,
          leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        return true;
      }
    }

    bool? result = performSubtypeConstraintGenerationForTypeDeclarationTypes(
        p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting);
    if (result != null) {
      return result;
    }

    // If `Q` is `Function` then the match holds under no constraints:
    //   If `P` is a function type.
    if (typeAnalyzerOperations.isDartCoreFunctionInternal(q)) {
      if (p is SharedFunctionTypeStructure) {
        return true;
      }
    }

    if (performSubtypeConstraintGenerationForFunctionTypes(p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
      return true;
    }

    // A type `P` is a subtype match for `Record` with respect to `L` under no
    // constraints:
    //   If `P` is a record type or `Record`.
    if (typeAnalyzerOperations.isDartCoreRecordInternal(q)) {
      if (p is SharedRecordTypeStructure<TypeStructure>) {
        return true;
      }
    }

    if (performSubtypeConstraintGenerationForRecordTypes(p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
      return true;
    }

    return false;
  }

  /// Matches type schema [p] against type [q] as a subtype against supertype,
  /// assuming [p] is the constraining type schema, and [q] contains the type
  /// parameters to constrain, and returns true if [p] is a subtype of [q]
  /// under some constraints, and false otherwise.
  ///
  /// As the generator computes the constraints making the relation possible,
  /// it changes its internal state. The current state of the generator can be
  /// obtained by [currentState], and the generator can be restored to a state
  /// via [restoreState]. If this method returns `false`, it restores the state,
  /// so it is not necessary for the caller to do so.
  ///
  /// The algorithm for subtype constraint generation is described in
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#subtype-constraint-generation
  bool performSubtypeConstraintGenerationLeftSchema(
      SharedTypeSchemaView<TypeStructure> p, SharedTypeView<TypeStructure> q,
      {required AstNode? astNodeForTesting});

  /// Matches type [p] against type schema [q] as a subtype against supertype,
  /// assuming [p] contains the type parameters to constrain, and [q] is the
  /// constraining type schema, and returns true if [p] is a subtype of [q]
  /// under some constraints, and false otherwise.
  ///
  /// As the generator computes the constraints making the relation possible,
  /// it changes its internal state. The current state of the generator can be
  /// obtained by [currentState], and the generator can be restored to a state
  /// via [restoreState]. If this method returns `false`, it restores the state,
  /// so it is not necessary for the caller to do so.
  ///
  /// The algorithm for subtype constraint generation is described in
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#subtype-constraint-generation
  bool performSubtypeConstraintGenerationRightSchema(
      SharedTypeView<TypeStructure> p, SharedTypeSchemaView<TypeStructure> q,
      {required AstNode? astNodeForTesting});

  /// Restores the constraint generator to [state].
  ///
  /// The [state] to restore the constraint generator to can be obtained via
  /// [currentState].
  void restoreState(TypeConstraintGeneratorState state);

  /// Match arguments [pTypeArguments] of P against arguments [qTypeArguments]
  /// of Q, taking into account the variance of type variables in [declaration].
  /// If returns `false`, the constraints are unchanged.
  bool _interfaceTypeArguments(
      TypeDeclaration declaration,
      List<TypeStructure> pTypeArguments,
      List<TypeStructure> qTypeArguments,
      bool leftSchema,
      {required AstNode? astNodeForTesting}) {
    assert(pTypeArguments.length == qTypeArguments.length);

    final TypeConstraintGeneratorState state = currentState;

    for (int i = 0; i < pTypeArguments.length; i++) {
      Variance variance =
          typeAnalyzerOperations.getTypeParameterVariance(declaration, i);
      TypeStructure M = pTypeArguments[i];
      TypeStructure N = qTypeArguments[i];
      if ((variance == Variance.covariant || variance == Variance.invariant) &&
          !performSubtypeConstraintGenerationInternal(M, N,
              leftSchema: leftSchema, astNodeForTesting: astNodeForTesting)) {
        restoreState(state);
        return false;
      }
      if ((variance == Variance.contravariant ||
              variance == Variance.invariant) &&
          !performSubtypeConstraintGenerationInternal(N, M,
              leftSchema: !leftSchema, astNodeForTesting: astNodeForTesting)) {
        restoreState(state);
        return false;
      }
    }

    return true;
  }

  /// Matches [p] against [q], assuming both [p] and [q] are both type
  /// declaration types that refer to different type declarations.
  ///
  /// If [p] is a subtype of [q] under some constraints, the constraints making
  /// the relation possible are recorded, and `true` is returned. Otherwise,
  /// the constraint state is unchanged (or rolled back using [restoreState]),
  /// and `false` is returned.
  bool _interfaceTypes(TypeStructure p, TypeStructure q, bool leftSchema,
      {required AstNode? astNodeForTesting}) {
    if (p.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    if (q.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    // If `P` is `C0<M0, ..., Mk>` and `Q` is `C1<N0, ..., Nj>` then the match
    // holds with respect to `L` under constraints `C`:
    //   If `C1<B0, ..., Bj>` is a superinterface of `C0<M0, ..., Mk>` and
    //   `C1<B0, ..., Bj>` is a subtype match for `C1<N0, ..., Nj>` with
    //   respect to `L` under constraints `C`.

    if ((
      typeAnalyzerOperations.matchTypeDeclarationTypeInternal(p),
      typeAnalyzerOperations.matchTypeDeclarationTypeInternal(q)
    )
        case (
          TypeDeclarationMatchResult(
            typeDeclarationType: TypeDeclarationType pTypeDeclarationType
          ),
          TypeDeclarationMatchResult(
            typeDeclaration: TypeDeclaration qTypeDeclaration,
            typeArguments: List<TypeStructure> qTypeArguments
          )
        )) {
      if (getTypeArgumentsAsInstanceOf(pTypeDeclarationType, qTypeDeclaration)
          case List<TypeStructure> typeArguments) {
        return _interfaceTypeArguments(
            qTypeDeclaration, typeArguments, qTypeArguments, leftSchema,
            astNodeForTesting: astNodeForTesting);
      }
    }

    return false;
  }
}

mixin TypeConstraintGeneratorMixin<
        TypeStructure extends SharedTypeStructure<TypeStructure>,
        // Work around https://github.com/dart-lang/dart_style/issues/1568
        // ignore: lines_longer_than_80_chars
        FunctionParameterStructure extends SharedNamedFunctionParameterStructure<
            TypeStructure>,
        Variable extends Object,
        // Work around https://github.com/dart-lang/dart_style/issues/1568
        // ignore: lines_longer_than_80_chars
        TypeParameterStructure extends SharedTypeParameterStructure<TypeStructure>,
        TypeDeclarationType extends Object,
        TypeDeclaration extends Object,
        AstNode extends Object>
    on TypeConstraintGenerator<
        TypeStructure,
        FunctionParameterStructure,
        Variable,
        TypeParameterStructure,
        TypeDeclarationType,
        TypeDeclaration,
        AstNode> {
  @override
  bool performSubtypeConstraintGenerationLeftSchema(
      SharedTypeSchemaView<TypeStructure> p, SharedTypeView<TypeStructure> q,
      {required AstNode? astNodeForTesting}) {
    return performSubtypeConstraintGenerationInternal(
        p.unwrapTypeSchemaView(), q.unwrapTypeView(),
        leftSchema: true, astNodeForTesting: astNodeForTesting);
  }

  @override
  bool performSubtypeConstraintGenerationRightSchema(
      SharedTypeView<TypeStructure> p, SharedTypeSchemaView<TypeStructure> q,
      {required AstNode? astNodeForTesting}) {
    return performSubtypeConstraintGenerationInternal(
        p.unwrapTypeView(), q.unwrapTypeSchemaView(),
        leftSchema: false, astNodeForTesting: astNodeForTesting);
  }
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

/// Describes constituents of a type derived from a declaration.
///
/// If a type is derived from a declaration, as described in the documentation
/// for [TypeDeclarationKind], objects of [TypeDeclarationMatchResult] describe
/// its components that can be used for the further analysis of the type in the
/// algorithms related to type inference.
class TypeDeclarationMatchResult<TypeDeclarationType extends Object,
    TypeDeclaration extends Object, Type extends Object> {
  /// The kind of type declaration the matched type is of.
  final TypeDeclarationKind typeDeclarationKind;

  /// A more specific subtype of [Type] describing the matched type.
  ///
  /// This is client-specific is needed to avoid unnecessary downcasts.
  final TypeDeclarationType typeDeclarationType;

  /// The type declaration that the matched type is derived from.
  ///
  /// The type declaration is defined in the documentation for
  /// [TypeDeclarationKind] and is a client-specific object representing a
  /// class, an enum, a mixin, or an extension type.
  final TypeDeclaration typeDeclaration;

  /// Type arguments instantiating [typeDeclaration] to the matched type.
  ///
  /// If [typeDeclaration] is not generic, [typeArguments] is an empty list.
  final List<Type> typeArguments;

  TypeDeclarationMatchResult(
      {required this.typeDeclarationKind,
      required this.typeDeclarationType,
      required this.typeDeclaration,
      required this.typeArguments});
}

/// The variance of a type parameter `X` in a type `T`.
enum Variance {
  /// Used when `X` does not occur free in `T`.
  unrelated(keyword: ''),

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[U/X]T <: [V/X]T`.
  covariant(keyword: 'out'),

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[V/X]T <: [U/X]T`.
  contravariant(keyword: 'in'),

  /// Used when there exists a pair `U` and `V` such that `U <: V`, but
  /// `[U/X]T` and `[V/X]T` are incomparable.
  invariant(keyword: 'inout');

  final String keyword;

  const Variance({required this.keyword});

  /// Return the variance with the given [encoding].
  factory Variance.fromEncoding(int encoding) => values[encoding];

  /// Return the variance associated with the string representation of variance.
  factory Variance.fromKeywordString(String keywordString) {
    Variance? result;
    if (keywordString == "in") {
      result = contravariant;
    } else if (keywordString == "inout") {
      result = invariant;
    } else if (keywordString == "out") {
      result = covariant;
    } else if (keywordString == "unrelated") {
      result = unrelated;
    }
    if (result != null) {
      assert(result.keyword == keywordString);
      return result;
    } else {
      throw new ArgumentError(
          'Invalid keyword string for variance: $keywordString');
    }
  }

  /// Return `true` if this represents the case when `X` occurs free in `T`, and
  /// `U <: V` implies `[V/X]T <: [U/X]T`.
  bool get isContravariant => this == contravariant;

  /// Return `true` if this represents the case when `X` occurs free in `T`, and
  /// `U <: V` implies `[U/X]T <: [V/X]T`.
  bool get isCovariant => this == covariant;

  /// Return `true` if this represents the case when there exists a pair `U` and
  /// `V` such that `U <: V`, but `[U/X]T` and `[V/X]T` are incomparable.
  bool get isInvariant => this == invariant;

  /// Return `true` if this represents the case when `X` does not occur free in
  /// `T`.
  bool get isUnrelated => this == unrelated;

  /// Combines variances of `X` in `T` and `Y` in `S` into variance of `X` in
  /// `[Y/T]S`.
  ///
  /// Consider the following examples:
  ///
  /// * variance of `X` in `Function(X)` is contravariant, variance of `Y`
  /// in `List<Y>` is covariant, so variance of `X` in `List<Function(X)>` is
  /// contravariant;
  ///
  /// * variance of `X` in `List<X>` is covariant, variance of `Y` in
  /// `Function(Y)` is contravariant, so variance of `X` in
  /// `Function(List<X>)` is contravariant;
  ///
  /// * variance of `X` in `Function(X)` is contravariant, variance of `Y` in
  /// `Function(Y)` is contravariant, so variance of `X` in
  /// `Function(Function(X))` is covariant;
  ///
  /// * let the following be declared:
  ///
  ///     typedef F<Z> = Function();
  ///
  /// then variance of `X` in `F<X>` is unrelated, variance of `Y` in
  /// `List<Y>` is covariant, so variance of `X` in `List<F<X>>` is
  /// unrelated;
  ///
  /// * let the following be declared:
  ///
  ///     typedef G<Z> = Z Function(Z);
  ///
  /// then variance of `X` in `List<X>` is covariant, variance of `Y` in
  /// `G<Y>` is invariant, so variance of `X` in `G<List<X>>` is invariant.
  Variance combine(Variance other) {
    if (isUnrelated || other.isUnrelated) return unrelated;
    if (isInvariant || other.isInvariant) return invariant;
    return this == other ? covariant : contravariant;
  }

  /// Returns true if this variance is greater than (above) or equal to the
  /// [other] variance in the partial order induced by the variance lattice.
  ///
  ///       unrelated
  /// covariant   contravariant
  ///       invariant
  bool greaterThanOrEqual(Variance other) {
    if (isUnrelated) {
      return true;
    } else if (isCovariant) {
      return other.isCovariant || other.isInvariant;
    } else if (isContravariant) {
      return other.isContravariant || other.isInvariant;
    } else {
      assert(isInvariant);
      return other.isInvariant;
    }
  }

  /// Variance values form a lattice where unrelated is the top, invariant is
  /// the bottom, and covariant and contravariant are incomparable.  [meet]
  /// calculates the meet of two elements of such lattice.  It can be used, for
  /// example, to calculate the variance of a typedef type parameter if it's
  /// encountered on the RHS of the typedef multiple times.
  ///
  ///       unrelated
  /// covariant   contravariant
  ///       invariant
  Variance meet(Variance other) {
    return new Variance.fromEncoding(index | other.index);
  }
}

/// Representation of the state of [TypeConstraintGenerator].
///
/// The state can be obtained via [TypeConstraintGenerator.currentState]. A
/// [TypeConstraintGenerator] can be restored to a state via
/// [TypeConstraintGenerator.restoreState].
///
/// In practice, the state is represented as an integer: the count of the
/// constraints generated so far. Since the count only increases as the
/// generator proceeds, restoring to a state means discarding some constraints.
extension type TypeConstraintGeneratorState(int count) {}
