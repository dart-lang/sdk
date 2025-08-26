// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
        'Invalid keyword string for variance: $keywordString',
      );
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

/// Common interface for data structures used by the implementations to
/// represent the type `dynamic`.
abstract interface class SharedDynamicType implements SharedType {}

/// Common interface for data structures used by the implementations to
/// represent function types.
abstract interface class SharedFunctionType implements SharedType {
  /// All the positional parameter types, starting with the required ones, and
  /// followed by the optional ones.
  List<SharedType> get positionalParameterTypesShared;

  /// The number of elements of [positionalParameterTypesShared] that are
  /// required parameters.
  int get requiredPositionalParameterCount;

  /// The return type.
  SharedType get returnTypeShared;

  /// All the named parameters, sorted by name.
  List<SharedNamedFunctionParameter> get sortedNamedParametersShared;

  /// The type parameters of the function type.
  List<SharedTypeParameter> get typeParametersShared;
}

/// Common interface for data structures used by the implementations to
/// represent a type resulting from a compile-time error.
///
/// The implementations may choose to suppress further errors that arise from
/// the use of this type.
abstract interface class SharedInvalidType implements SharedType {}

/// Common interface for data structures used by the implementations to
/// represent a named parameter of a function type.
abstract interface class SharedNamedFunctionParameter {
  /// Whether this named parameter is required.
  bool get isRequired;

  /// The name of the parameter.
  String get nameShared;

  /// The type of the parameter.
  SharedType get typeShared;
}

/// Common interface for data structures used by the implementations to
/// represent a name/type pair.
abstract interface class SharedNamedType {
  String get nameShared;

  SharedType get typeShared;
}

/// Common interface for data structures used by implementations to represent
/// the type `Null`.
abstract interface class SharedNullType implements SharedType {}

/// Common interface for data structures used by the implementations to
/// represent a record type.
abstract interface class SharedRecordType implements SharedType {
  List<SharedType> get positionalTypesShared;

  /// All the named fields, sorted by name.
  List<SharedNamedType> get sortedNamedTypesShared;
}

/// Common interface for data structures used by the implementations to
/// represent a type.
abstract interface class SharedType {
  /// Whether this type ends in a `?` suffix.
  ///
  /// Note that some types are nullable even though they do not end in a `?`
  /// suffix (for example, `Null`, `dynamic`, and `FutureOr<int?>`). These types
  /// all respond to this query with `false`.
  bool get isQuestionType;

  /// Returns a modified version of this type, with the nullability suffix
  /// changed to [isQuestionType].
  ///
  /// For types that don't accept a nullability suffix (`dynamic`, InvalidType,
  /// `Null`, `_`, and `void`), the type is returned unchanged.
  SharedType asQuestionType(bool isQuestionType);

  /// Return the presentation of this type as it should appear when presented
  /// to users in contexts such as error messages.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String getDisplayString();

  bool isStructurallyEqualTo(covariant SharedType other);
}

/// Common interface for data structures used by the implementations to
/// represent a generic type parameter.
abstract interface class SharedTypeParameter {
  /// The bound of the type parameter.
  SharedType? get boundShared;

  /// The name of the type parameter, for display to the user.
  String get displayName;

  /// Type parameter variance.
  Variance get variance;

  /// True if the type parameter doesn't use declared variance.
  bool get isLegacyCovariant;
}

/// Common interface for data structures used by the implementations to
/// represent the unknown type schema (`_`).
///
/// Note below that there is no `SharedUnknownTypeView`, only
/// [SharedUnknownTypeSchemaView], since we want to restrict
/// [SharedUnknownType] from appearing in type views.
abstract interface class SharedUnknownType implements SharedType {}

/// Common interface for data structures used by the implementations to
/// represent the type `void`.
abstract interface class SharedVoidType implements SharedType {}

extension type SharedDynamicTypeSchemaView(SharedDynamicType _typeStructure)
    implements SharedTypeSchemaView {}

extension type SharedDynamicTypeView(SharedDynamicType _typeStructure)
    implements SharedTypeView {}

extension type SharedInvalidTypeSchemaView(SharedInvalidType _typeStructure)
    implements SharedTypeSchemaView {}

extension type SharedInvalidTypeView(SharedInvalidType _typeStructure)
    implements SharedTypeView {}

extension type SharedNamedTypeSchemaView(SharedNamedType _typeStructure)
    implements Object {}

extension type SharedNamedTypeView(SharedNamedType _namedTypeStructure)
    implements Object {
  String get name => _namedTypeStructure.nameShared;

  SharedTypeView get type => new SharedTypeView(_namedTypeStructure.typeShared);
}

extension type SharedRecordTypeSchemaView(SharedRecordType _typeStructure)
    implements SharedTypeSchemaView {
  List<SharedNamedTypeSchemaView> get namedTypes {
    return _typeStructure.sortedNamedTypesShared
        as List<SharedNamedTypeSchemaView>;
  }

  List<SharedTypeSchemaView> get positionalTypes {
    return _typeStructure.positionalTypesShared as List<SharedTypeSchemaView>;
  }
}

extension type SharedRecordTypeView(SharedRecordType _typeStructure)
    implements SharedTypeView {
  List<SharedNamedTypeView> get namedTypes {
    return _typeStructure.sortedNamedTypesShared as List<SharedNamedTypeView>;
  }

  List<SharedTypeView> get positionalTypes {
    return _typeStructure.positionalTypesShared as List<SharedTypeView>;
  }
}

extension type SharedTypeParameterView(SharedTypeParameter _typeParameter)
    implements Object {
  TypeParameter unwrapTypeParameterViewAsTypeParameterStructure<
    TypeParameter extends SharedTypeParameter
  >() => _typeParameter as TypeParameter;
}

extension type SharedTypeSchemaView(SharedType _typeStructure)
    implements Object {
  bool get isQuestionType => _typeStructure.isQuestionType;

  String getDisplayString() => _typeStructure.getDisplayString();

  bool isStructurallyEqualTo(SharedTypeSchemaView other) =>
      _typeStructure.isStructurallyEqualTo(other.unwrapTypeSchemaView());

  TypeStructure unwrapTypeSchemaView<TypeStructure extends SharedType>() =>
      _typeStructure as TypeStructure;
}

extension type SharedTypeView(SharedType _typeStructure) implements Object {
  bool get isQuestionType => _typeStructure.isQuestionType;

  String getDisplayString() => _typeStructure.getDisplayString();

  bool isStructurallyEqualTo(SharedTypeView other) =>
      _typeStructure.isStructurallyEqualTo(other.unwrapTypeView());

  TypeStructure unwrapTypeView<TypeStructure extends SharedType>() =>
      _typeStructure as TypeStructure;
}

/// Note that there is no `SharedUnknownTypeView`, only
/// [SharedUnknownTypeSchemaView], since we want to restrict
/// [SharedUnknownType] from appearing in type views and
/// allow it to appear only in type schema views.
extension type SharedUnknownTypeSchemaView(SharedUnknownType _typeStructure)
    implements SharedTypeSchemaView {}

extension type SharedVoidTypeSchemaView(SharedVoidType _typeStructure)
    implements SharedTypeSchemaView {}

extension type SharedVoidTypeView(SharedVoidType _typeStructure)
    implements SharedTypeView {}

/// Extension methods of [SharedTypeStructureExtension] are intended to avoid
/// explicit null-testing on types before wrapping them into [SharedTypeView]
/// or [SharedTypeSchemaView].
///
/// Consider the following code:
///     DartType? type = e.foo();
///     return type == null ? null : SharedTypeView(type);
///
/// In the example above we want to wrap the result of the evaluation of
/// `e.foo()` in `SharedTypeView` if it's not null. For that we need to store
/// it into a variable to enable promotion in the ternary operator that will
/// perform the wrapping.
///
/// This code can be rewritten in a more concise way using
/// [SharedTypeStructureExtension] as follows:
///     return e.foo()?.wrapSharedTypeView();
extension SharedTypeStructureExtension on SharedType {
  SharedTypeSchemaView wrapSharedTypeSchemaView() {
    return new SharedTypeSchemaView(this);
  }

  SharedTypeView wrapSharedTypeView() {
    return new SharedTypeView(this);
  }
}

extension SharedTypeStructureMapEntryExtension
    on ({SharedType keyType, SharedType valueType}) {
  ({SharedTypeView keyType, SharedTypeView valueType})
  wrapSharedTypeMapEntryView() {
    return (
      keyType: new SharedTypeView(this.keyType),
      valueType: new SharedTypeView(this.valueType),
    );
  }

  ({SharedTypeSchemaView keyType, SharedTypeSchemaView valueType})
  wrapSharedTypeSchemaMapEntryView() {
    return (
      keyType: new SharedTypeSchemaView(this.keyType),
      valueType: new SharedTypeSchemaView(this.valueType),
    );
  }
}
